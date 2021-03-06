/*
 * Ssh.cpp
 *
 *  Created on: 23.04.2009
 *      Author: julian
 */

#include "SshThread.h"
#include "Client.h"
#include "Utility.h"
#include "Configuration.h"
#include "LoggerFactory.h"

#include "include/libssh2.h"

#include <algorithm>
#include <map>

#include <arpa/inet.h>

#include <boost/foreach.hpp>
#include <pthread.h>
#include <signal.h>

using namespace std;



pthread_mutex_t SshThread::clientmutex;
pthread_mutex_t SshThread::timeoutmutex;
pthread_t SshThread::thread;
pthread_t SshThread::timeoutthread;

std::vector<Client*> SshThread::sshClients;
std::map<Client*,SSHInfo > SshThread::sshInfos;
std::pair<Client*, time_t > SshThread::sshTimeout;
std::map<Client*,std::vector<sshStruct> > SshThread::sshCmds;

bool SshThread::started;

extern bool exitFlag;


SshThread::SshThread() {

	sshTimeout.first = NULL;
	sshTimeout.second = 0;

	pthread_mutex_init(&clientmutex, NULL);
	pthread_mutex_init(&timeoutmutex, NULL);

	started = true;

	pthread_create(&thread, NULL, SshThread::_main, NULL);
	pthread_create(&timeoutthread, NULL, SshThread::_main_timer, NULL);
	pthread_detach(timeoutthread);
}

void SshThread::update() {
	pthread_mutex_lock(&timeoutmutex);
	if(!started) {
		pthread_create(&thread,NULL, SshThread::_main, NULL);
		pthread_detach(timeoutthread);
		started = true;
	}
	pthread_mutex_unlock(&timeoutmutex);
}

SshThread::~SshThread() {

}

SshThread *SshThread::getInstance() {
	static SshThread instance;

	return &instance;

}

void SshThread::_connect(std::string ipaddress, SSHInfo* sshinfo) {
	if(ipaddress.length() > 1) {
		_connect(Utils::ipFromString(ipaddress.c_str()), sshinfo );
	}
}

void SshThread::_connect(IPAddress ip, SSHInfo* sshinfo) {
	Configuration* conf = Configuration::getInstance();
	Logger* logger = LoggerFactory::getInstance()->getGlobalLogger();


	string username = conf->getString("ssh_username");
	string authmethod = conf->getString("ssh_auth_method");
	string password = conf->getString("ssh_password");
	string pubkeyfile = conf->getString("ssh_public_key");
	string privkeyfile = conf->getString("ssh_private_key");

	sshinfo->sock = 0;
	sshinfo->channel = NULL;

    unsigned long hostaddr;
    int i, auth_pw = 0;


    if (ip != 0) {
        hostaddr = ip;
    } else {
        hostaddr = htonl(0x7F000001);
    }

    sshinfo->sock = socket(AF_INET, SOCK_STREAM, 0);

    sshinfo->sin.sin_family = AF_INET;
    sshinfo->sin.sin_port = htons(22);
    sshinfo->sin.sin_addr.s_addr = hostaddr;
    if (connect(sshinfo->sock, (struct sockaddr*)(&sshinfo->sin),
				sizeof(struct sockaddr_in)) != 0) {
    	logger->log(LOG_LEVEL_ERROR,"failed to connect!",sshinfo->client);
    	throw exception();
	}

    // Initialize session
    sshinfo->session = libssh2_session_init();
    if (libssh2_session_startup(sshinfo->session, sshinfo->sock)) {
    	logger->log(LOG_LEVEL_ERROR,"Failure establishing SSH session",sshinfo->client);
    	throw exception();
        return;
    }

    // Authenticate
    //fingerprint = libssh2_hostkey_hash(session, LIBSSH2_HOSTKEY_HASH_MD5);

	//libssh2_session_startup(session, sock);
    sshinfo->userauthlist = libssh2_userauth_list(sshinfo->session, username.c_str(), username.size());

    logger->log(LOG_LEVEL_INFO,string("Authentication methods: ")+ sshinfo->userauthlist,sshinfo->client);


    if (strstr(sshinfo->userauthlist, "password") != NULL) {
        auth_pw |= 1;
    }
    if (strstr(sshinfo->userauthlist, "publickey") != NULL) {
		auth_pw |= 4;
	}

    if ((auth_pw & 1) && authmethod == "password") {
		/* We could authenticate via password */
		if (libssh2_userauth_password(sshinfo->session, username.c_str(), password.c_str())) {
			logger->log(LOG_LEVEL_ERROR,"\tAuthentication by password failed!",sshinfo->client);
			throw exception();
			return;
		} else {
			logger->log(LOG_LEVEL_INFO,"\tAuthentication by password succeeded.",sshinfo->client);
		}
	} else if ( (auth_pw & 4) && authmethod == "publickey") {
		// Authenticate by public key
		if (libssh2_userauth_publickey_fromfile(sshinfo->session, username.c_str(),
				pubkeyfile.c_str(), privkeyfile.c_str(), password.c_str()))
		{
			logger->log(LOG_LEVEL_ERROR,"\tAuthentication by public key failed!", sshinfo->client);
			throw exception();
			return;
		} else {
			logger->log( LOG_LEVEL_INFO,"\tAuthentication by public key succeeded.",sshinfo->client);
		}
	} else {
		logger->log(
				LOG_LEVEL_ERROR,"\tAuthentication method "+authmethod
				+" not available!\nAvailable are: "+sshinfo->userauthlist,sshinfo->client);
		libssh2_session_disconnect(sshinfo->session,
				"Did not find suitable authentication method (password)!");
		throw exception();
		return;
	}

	//libssh2_channel_handle_extended_data(sshinfo->channel,
	//		LIBSSH2_CHANNEL_EXTENDED_DATA_IGNORE);
}


void SshThread::_disconnect(SSHInfo* sshinfo) {

	Logger* logger = LoggerFactory::getInstance()->getGlobalLogger();
    if (sshinfo->channel) {
    	libssh2_channel_set_blocking(sshinfo->channel, 0);
    	libssh2_channel_close(sshinfo->channel);
    	if(libssh2_channel_wait_closed(sshinfo->channel) == -1) {
    		logger->log(LOG_LEVEL_ERROR, "Error closing channel!", sshinfo->client);
    		return;
    	}
        libssh2_channel_free(sshinfo->channel);
        sshinfo->channel = NULL;
    }
    libssh2_session_disconnect(sshinfo->session, "Normal Shutdown, Thank you for playing");
    libssh2_session_free(sshinfo->session);
    sleep(1);
    close(sshinfo->sock);
}

void SshThread::_runCmd(SSHInfo* sshinfo, string cmd) {

	if(cmd.size() == 0) return;
	int retval = 0, bsize = 0, MAX_LENGTH=255, error = 0;
	char buf[MAX_LENGTH];
	string output;

    Logger* log = LoggerFactory::getInstance()->getGlobalLogger();

    if(!sshinfo->channel) {
	if (!(sshinfo->channel = libssh2_channel_open_session(sshinfo->session))) {
		log->log(LOG_LEVEL_ERROR,"Unable to open a session",sshinfo->client);
		libssh2_session_disconnect(sshinfo->session,
						"Could not allocate channel!");
		throw exception();
		return;
	}}

	log->log(LOG_LEVEL_INFO,"Running command: "+cmd,sshinfo->client);
	retval = libssh2_channel_exec(sshinfo->channel, cmd.c_str() );
	if(retval == -1) {
		error = libssh2_session_last_error(sshinfo->session,0,0,0);
		switch(error) {
		case LIBSSH2_ERROR_SOCKET_SEND:
			log->log(LOG_LEVEL_ERROR,"Could not send command!",sshinfo->client);
			break;
		case LIBSSH2_ERROR_ALLOC:
			log->log(LOG_LEVEL_ERROR,"Some memory problem!",sshinfo->client);
			break;
		default:
			log->log(LOG_LEVEL_ERROR,"Some unknown error occurred running the SSH command!",sshinfo->client);
			log->log(LOG_LEVEL_ERROR,"Error code is "+Utils::toString(error),sshinfo->client);
			break;
		}
		throw exception();
	}

	bsize = libssh2_channel_read(sshinfo->channel, buf, MAX_LENGTH);
	log->log(LOG_LEVEL_INFO,"Returning output (following lines):",sshinfo->client);
	while( bsize != 0 ) {
		output += string(buf,bsize);
		if(bsize < 0) {
			log->log(LOG_LEVEL_ERROR,"ERROR running command!",sshinfo->client);
			throw exception();
		}
		bsize = libssh2_channel_read(sshinfo->channel, buf, MAX_LENGTH);
	}


	log->log(LOG_LEVEL_INFO,output,sshinfo->client);

	libssh2_channel_close(sshinfo->channel);
	if(!libssh2_channel_wait_closed(sshinfo->channel)) {
		libssh2_channel_free(sshinfo->channel);
		sshinfo->channel = NULL;
	}
}


/**
 * This is the thread main function (and returns a void* - very important)
 */
void* SshThread::_main(void* p) {
	signal(SIGHUP,&SshThread::_quit_thread);
	Configuration* conf = Configuration::getInstance();
	Logger* log = LoggerFactory::getInstance()->getGlobalLogger();

	SSHInfo sshinfo;
	int i;
	bool commandFlag = true;
	vector<sshStruct> sshCmd;

	while(!exitFlag) {

	// copy the clients into a seperate vector
	pthread_mutex_lock(&clientmutex);
	vector<Client*> vecClients = sshClients;
	pthread_mutex_unlock(&clientmutex);


	// FOREACH client do
	BOOST_FOREACH(Client* client, vecClients) {
		sshinfo.client = client;
		sshCmd.clear();
		sshCmd = client->getCmdTable();
		sshCmds[client].insert(sshCmds[client].end(),sshCmd.begin(),sshCmd.end());
		if(sshCmds[client].size() == 0) continue;

		i = 0;

		if(sshInfos.find(client) != sshInfos.end()) {
			sshinfo = sshInfos[client];
		}
		else
		{
			try {
				_set_timeout(client,5);
				_connect(client->getIP(),&sshinfo);
				sshInfos[client] = sshinfo;
			}
			catch (exception e) {
				_reset_timeout();
				pthread_mutex_lock(&client->sshMutex);
				client->ssh_responding |= (1 << 6);
				pthread_mutex_unlock(&client->sshMutex);
				break;
			}
		}

		// FOREACH command do
		BOOST_FOREACH(sshStruct cmd, sshCmds[client]) {
			commandFlag = false;
			try {
				_set_timeout(client,5);
				_runCmd(&sshinfo, cmd.cmd);
				++i;
				if(i == sshCmds[client].size()) {
					pthread_mutex_lock(&client->sshMutex);
					client->ssh_responding |= (1 << 7) | (1 << 6);
					pthread_mutex_unlock(&client->sshMutex);
				}
			}
			catch(exception e) {
				_disconnect(&sshinfo);
				_reset_timeout();
				sshInfos.erase(sshInfos.find(client) );
				pthread_mutex_lock(&client->sshMutex);
				client->ssh_responding |= (1 << 6);
				pthread_mutex_unlock(&client->sshMutex);
				break;
			}
		} // od

		_reset_timeout();
		sshCmds[client].clear();

	} // od

	if(commandFlag) sleep(1);

	sleep(2);

	}

	log->log(LOG_LEVEL_INFO,"SSH Thread terminated", NULL);
}

void* SshThread::_main_timer(void*) {
	Logger* log = LoggerFactory::getInstance()->getGlobalLogger();

	time_t t = 0;
	int ret = 0;

	while(!exitFlag) {
		sleep(1);

		pthread_mutex_lock(&timeoutmutex);
		if(sshTimeout.second == 0) {
			pthread_mutex_unlock(&timeoutmutex);
			continue;
		}
		pthread_mutex_unlock(&timeoutmutex);
		//sshTimeout.first is a client
		//sshTimeout.second is timeout time

		pthread_mutex_lock(&timeoutmutex);
		time(&t);
		if(t > sshTimeout.second && sshTimeout.second != 0) {
			log->log(LOG_LEVEL_ERROR, "Detected timeout in SSH worker thread!", sshTimeout.first);
			pthread_mutex_lock(&sshTimeout.first->sshMutex);
			sshTimeout.first->ssh_responding |= (1 << 6);
			pthread_mutex_unlock(&sshTimeout.first->sshMutex);
			ret = pthread_kill(thread,SIGHUP);
			if(ret) {
				log->log(LOG_LEVEL_FATAL, "Could not kill SSH worker thread!", sshTimeout.first);
			}
			SshThread::getInstance()->delClient(sshTimeout.first, true);
			started = false;
			//pthread_create(&thread, NULL, SshThread::_main, NULL);
		}
		pthread_mutex_unlock(&timeoutmutex);
	}
}


void SshThread::_set_timeout(Client* client, time_t timeout) {
	time_t t = 0;
	pthread_mutex_lock(&timeoutmutex);
	time(&t);
	sshTimeout.first = client;
	sshTimeout.second = t+timeout;
	pthread_mutex_unlock(&timeoutmutex);
}

void SshThread::_reset_timeout() {
	pthread_mutex_lock(&timeoutmutex);
	sshTimeout.first = NULL;
	sshTimeout.second = 0;
	pthread_mutex_unlock(&timeoutmutex);
}

void SshThread::_quit_thread(int sig) {
	_reset_timeout();
	pthread_exit(NULL);
}

void SshThread::addClient(Client* client) {
	pthread_mutex_lock(&clientmutex);
	if(find(sshClients.begin(), sshClients.end(),client) == sshClients.end()) {
		sshClients.push_back(client);
	}
	pthread_mutex_unlock(&clientmutex);
}

void SshThread::delClient(Client* client, bool timeout) {
	pthread_mutex_lock(&clientmutex);
	vector<Client*>::iterator pos =
		find(sshClients.begin(),sshClients.end(),client);
	std::map<Client*,SSHInfo>::iterator mPos = sshInfos.find(client);

	if(pos != sshClients.end()) {
		sshClients.erase(pos);
		if(mPos != sshInfos.end()) {
			if(!timeout)
				_disconnect(&sshInfos[client]);
			sshInfos.erase(mPos);
		}
	}
	sshCmds.erase(client);
	pthread_mutex_unlock(&clientmutex);



    Logger* log = LoggerFactory::getInstance()->getGlobalLogger();
	log->log(LOG_LEVEL_INFO,"SSH connection disconnected!",  client);
}

