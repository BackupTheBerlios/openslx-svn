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
#include "Logger.h"

#include "include/libssh2.h"

#include <algorithm>
#include <map>

#include <arpa/inet.h>

#include <boost/foreach.hpp>

using namespace std;



pthread_mutex_t SshThread::clientmutex;

std::vector<Client*> SshThread::sshClients;
std::map<Client*,SSHInfo > SshThread::sshInfos;

SshThread::SshThread() {

	pthread_mutex_init(&clientmutex, NULL);

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
	Logger* logger = Logger::getInstance();


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
    	logger->log("failed to connect!",LOG_LEVEL_ERROR);
		return;
	}

    // Initialize session
    sshinfo->session = libssh2_session_init();
    if (libssh2_session_startup(sshinfo->session, sshinfo->sock)) {
    	logger->log("Failure establishing SSH session", LOG_LEVEL_ERROR);
        return;
    }

    // Authenticate
    //fingerprint = libssh2_hostkey_hash(session, LIBSSH2_HOSTKEY_HASH_MD5);

	//libssh2_session_startup(session, sock);
    sshinfo->userauthlist = libssh2_userauth_list(sshinfo->session, username.c_str(), username.size());

    logger->log(string("Authentication methods: ")+ sshinfo->userauthlist, LOG_LEVEL_INFO);


    if (strstr(sshinfo->userauthlist, "password") != NULL) {
        auth_pw |= 1;
    }
    if (strstr(sshinfo->userauthlist, "publickey") != NULL) {
		auth_pw |= 4;
	}

    if ((auth_pw & 1) && authmethod == "password") {
		/* We could authenticate via password */
		if (libssh2_userauth_password(sshinfo->session, username.c_str(), password.c_str())) {
			logger->log("\tAuthentication by password failed!",LOG_LEVEL_ERROR);
			return;
		} else {
			logger->log("\tAuthentication by password succeeded.",LOG_LEVEL_INFO);
		}
	} else if ( (auth_pw & 4) && authmethod == "publickey") {
		// Authenticate by public key
		if (libssh2_userauth_publickey_fromfile(sshinfo->session, username.c_str(),
				pubkeyfile.c_str(), privkeyfile.c_str(), password.c_str()))
		{
			logger->log("\tAuthentication by public key failed!", LOG_LEVEL_ERROR);
			return;
		} else {
			logger->log("\tAuthentication by public key succeeded.", LOG_LEVEL_INFO);
		}
	} else {
		logger->log("\tAuthentication method "+authmethod
				+" not available!\nAvailable are: "+sshinfo->userauthlist,
				LOG_LEVEL_ERROR);
		libssh2_session_disconnect(sshinfo->session,
				"Did not find suitable authentication method!");
		return;
	}

    /* Request a shell */
	if (!(sshinfo->channel = libssh2_channel_open_session(sshinfo->session))) {
		logger->log("Unable to open a session", LOG_LEVEL_ERROR);
		return;
	}

	/* Some environment variables may be set,
	 * It's up to the server which ones it'll allow though
	 */
	libssh2_channel_setenv(sshinfo->channel, "PROMPT", "$");

	/* Request a terminal with 'vanilla' terminal emulation
	 * See /etc/termcap for more options
	 */
	if (libssh2_channel_request_pty(sshinfo->channel, "vanilla")) {
		logger->log("Failed requesting pty", LOG_LEVEL_ERROR);
		this->_disconnect(sshinfo);
		return;
	}

	libssh2_channel_handle_extended_data(sshinfo->channel,
			LIBSSH2_CHANNEL_EXTENDED_DATA_IGNORE);

	/* Open a SHELL on that pty */
	if (libssh2_channel_shell(sshinfo->channel)) {
		logger->log("Unable to request shell on allocated pty", LOG_LEVEL_ERROR);
		this->_disconnect(sshinfo);
		return;
	}

}

void SshThread::_disconnect(SSHInfo* sshinfo) {
    if (sshinfo->channel) {
        libssh2_channel_free(sshinfo->channel);
        sshinfo->channel = NULL;
    }
    libssh2_session_disconnect(sshinfo->session, "Normal Shutdown, Thank you for playing");
    libssh2_session_free(sshinfo->session);
    sleep(1);
    close(sshinfo->sock);
}

void SshThread::_runCmd(SSHInfo* sshinfo, string cmd) {

	cmd.append("\n");

	Logger* log = Logger::getInstance();

	int MAXLEN = 255;
	char buf[MAXLEN];

	libssh2_channel_write(sshinfo->channel, cmd.c_str(), cmd.size() );
	log->log("Running command: "+cmd,LOG_LEVEL_INFO);

	libssh2_channel_flush(sshinfo->channel);


	int bufferlength= 0;

	while(!libssh2_channel_eof(sshinfo->channel)) {
		bufferlength = libssh2_channel_read(sshinfo->channel, buf, MAXLEN );

		log->log(string("Returning output: ")+string(buf,bufferlength),LOG_LEVEL_INFO);
		*buf = 0;
	}

}


void* SshThread::_main() {
	pthread_mutex_lock(&clientmutex);
	BOOST_FOREACH(Client* client, sshClients) {
		//client->context();
	}
	pthread_mutex_unlock(&clientmutex);
}


void SshThread::addClient(Client* client) {
	pthread_mutex_lock(&clientmutex);
	sshClients.push_back(client);
	pthread_mutex_unlock(&clientmutex);


	_connect(client->getIP(), &sshInfos[client]);
	_runCmd(&sshInfos[client], "ls -ahl");
	_disconnect(&sshInfos[client]);
}

void SshThread::delClient(Client* client) {
	pthread_mutex_lock(&clientmutex);
	vector<Client*>::iterator pos =
		find(sshClients.begin(),sshClients.end(),client);

	if(pos != sshClients.end()) {
		sshClients.erase(pos);
	}
	pthread_mutex_unlock(&clientmutex);


	Logger* log = Logger::getInstance();
	log->log("SSH connection disconnected!", LOG_LEVEL_INFO);
}


void SshThread::addCmd(Client* client, vector<string> cmdTable) {
//	pthread_mutex_lock(&cmdtablemutex);
//	cmdTable[client].push_back(cmd);
//	pthread_mutex_unlock(&cmdtablemutex);
}

void SshThread::delCmd(Client* client) {
//	pthread_mutex_lock(&cmdtablemutex);
//	vector<string>::iterator
//	pos = find(cmdTable[client].begin(),cmdTable[client].end(),cmd);
//
//	if(pos != cmdTable[client].end()) {
//		cmdTable[client].erase(pos);
//	}
//	pthread_mutex_unlock(&cmdtablemutex);
}
