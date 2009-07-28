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

using namespace std;



pthread_mutex_t SshThread::clientmutex;
pthread_t SshThread::thread;

std::vector<Client*> SshThread::sshClients;
std::map<Client*,SSHInfo > SshThread::sshInfos;
//std::map<Client*,std::vector<std::string,bool> > SshThread::sshCmds;

extern bool exitFlag;

SshThread::SshThread() {

	pthread_mutex_init(&clientmutex, NULL);

	pthread_create(&thread, NULL, SshThread::_main, NULL);

}

SshThread::~SshThread() {

}

SshThread *SshThread::getInstance() {
	static SshThread instance;

	return &instance;

}

void SshThread::_connect(std::string ipaddress, SSHInfo* sshinfo) {
	if(ipaddress.length() > 1) {
		_connect(Utility::ipFromString(ipaddress.c_str()), sshinfo );
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

	/* Request a shell */
	if (!(sshinfo->channel = libssh2_channel_open_session(sshinfo->session))) {
		logger->log(LOG_LEVEL_ERROR,"Unable to open a session",sshinfo->client);
		libssh2_session_disconnect(sshinfo->session,
						"Could not allocate channel!");
		throw exception();
		return;
	}
	//libssh2_channel_handle_extended_data(sshinfo->channel,
	//		LIBSSH2_CHANNEL_EXTENDED_DATA_IGNORE);
	//libssh2_channel_set_blocking(sshinfo->channel, 0);

}


void SshThread::_disconnect(SSHInfo* sshinfo) {

	Logger* logger = LoggerFactory::getInstance()->getGlobalLogger();
    if (sshinfo->channel) {
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
	string output;

    Logger* log = LoggerFactory::getInstance()->getGlobalLogger();

	int MAXLEN = 255, ret = 0, retprog=0, error=0;
	int bufferlength= 0;
	char buf[MAXLEN];
	vector<string> lines;

	if(!sshinfo->channel) {
		sshinfo->channel = libssh2_channel_open_session(sshinfo->session);
		if(!sshinfo->channel) {
			log->log(LOG_LEVEL_ERROR,"Could not re-open channel", sshinfo->client);
		}
	}

	ret = libssh2_channel_exec(sshinfo->channel, cmd.c_str() );

//	retprog = libssh2_channel_get_exit_status(sshinfo->channel);
	if(ret == -1) {
		error = libssh2_session_last_error(sshinfo->session,0,0,0);
		if(error == LIBSSH2_ERROR_SOCKET_SEND ) {
			log->log(LOG_LEVEL_ERROR, "Could not send data via SSH",sshinfo->client);
			throw exception();
		}
		else if( error == LIBSSH2_ERROR_ALLOC) {
			log->log(LOG_LEVEL_ERROR, "Could not allocate memory for SSH", sshinfo->client);
			throw exception();
		}
		else {
			log->log(LOG_LEVEL_ERROR, "Some error occurred running SSH command: "+cmd, sshinfo->client);
			log->log(LOG_LEVEL_ERROR, "libssh2 error code: "+Utility::toString(error), sshinfo->client);
			throw exception();
		}
	}
	log->log(LOG_LEVEL_INFO,"Running command: "+cmd,sshinfo->client); //.substr(0,cmd.size()-1)
//	if(retprog == 0) {
//		log->log(LOG_LEVEL_ERROR, "ssh command exit status not available: "+cmd, sshinfo->client);
//	}

	do {
		bufferlength = libssh2_channel_read(sshinfo->channel, buf, MAXLEN );
		if(bufferlength < 0) {
			return;
		}
		if(bufferlength != 0) {
			output.append(string(buf,bufferlength));

			if(bufferlength > 0) {
				log->log(LOG_LEVEL_INFO,string("Returning output: ")+output,sshinfo->client);
			}
		}
	} while (bufferlength != 0);

	// close the channel - we don't need it in the next 5 seconds
	libssh2_channel_close(sshinfo->channel);
	if(!libssh2_channel_wait_closed(sshinfo->channel)) {
		libssh2_channel_free(sshinfo->channel);
		sshinfo->channel = NULL;
	}
	else {
		log->log(LOG_LEVEL_ERROR,"Not able to close current channel!",sshinfo->client);
	}

}


/**
 * This is the thread main function (and returns a void* - very important)
 */
void* SshThread::_main(void*) {
	Configuration* conf = Configuration::getInstance();
	SSHInfo sshinfo;
	int i;
	bool commandFlag = true;
	vector<string> sshCmd;

	while(!exitFlag) {

	// copy the clients into a seperate vector
	pthread_mutex_lock(&clientmutex);
	vector<Client*> vecClients = sshClients;
	pthread_mutex_unlock(&clientmutex);

//	if(vecClients.size() == 0) {
//		sleep(conf->getInt("ssh_init_time"));
//	}

	// FOREACH client do
	BOOST_FOREACH(Client* client, vecClients) {
		sshinfo.client = client;
		sshCmd.clear();
		sshCmd = client->getCmdTable();

		if(sshCmd.size() == 0) continue;

		i = 0;

		if(sshInfos.find(client) != sshInfos.end()) {
			sshinfo = sshInfos[client];
		}
		else
		{
			try {
				_connect(client->getIP(),&sshinfo);
				sshInfos[client] = sshinfo;
			}
			catch (exception e) {
				pthread_mutex_lock(&client->sshMutex);
				client->ssh_responding |= (1 << 6);
				pthread_mutex_unlock(&client->sshMutex);
				break;
			}
		}

		// FOREACH command do
		BOOST_FOREACH(string cmd, sshCmd) {
			commandFlag = false;
			try {
				_runCmd(&sshinfo, cmd);
				++i;
				if(i == sshCmd.size()) {
					pthread_mutex_lock(&client->sshMutex);
					client->ssh_responding |= (1 << 7) | (1 << 6);
					pthread_mutex_unlock(&client->sshMutex);
				}
			}
			catch(exception e) {
				_disconnect(&sshinfo);
				sshInfos.erase(sshInfos.find(client) );
				pthread_mutex_lock(&client->sshMutex);
				client->ssh_responding |= (1 << 6);
				pthread_mutex_unlock(&client->sshMutex);
				break;
			}
		} // od
	} // od

	if(commandFlag) sleep(1);

	sleep(2);

	}
	clog << "SSH Thread terminated" << endl;
}


void SshThread::addClient(Client* client) {
	pthread_mutex_lock(&clientmutex);
	if(find(sshClients.begin(), sshClients.end(),client) == sshClients.end()) {
		sshClients.push_back(client);
	}
	pthread_mutex_unlock(&clientmutex);
}

void SshThread::delClient(Client* client) {
	pthread_mutex_lock(&clientmutex);
	vector<Client*>::iterator pos =
		find(sshClients.begin(),sshClients.end(),client);
	std::map<Client*,SSHInfo>::iterator mPos = sshInfos.find(client);

	if(pos != sshClients.end()) {
		sshClients.erase(pos);
		if(mPos != sshInfos.end()) {
			_disconnect(&sshInfos[client]);
			sshInfos.erase(mPos);
		}
	}
	pthread_mutex_unlock(&clientmutex);



    Logger* log = LoggerFactory::getInstance()->getGlobalLogger();
	log->log(LOG_LEVEL_INFO,"SSH connection disconnected!",  client);
}

