/*
 * Ssh.cpp
 *
 *  Created on: 23.04.2009
 *      Author: julian
 */

#include "SshThread.h"
#include "Client.h"

#include "include/libssh2.h"

#include <algorithm>

#include <arpa/inet.h>

using namespace std;

SshThread::SshThread() {

	pthread_mutex_init(&clientmutex, NULL);

}

SshThread::~SshThread() {

}

SshThread *SshThread::getInstance() {
	static SshThread instance;

	return &instance;

}

void SshThread::_connect(std::string ipaddress) {
	if(ipaddress.length() > 1) {
		_connect(inet_addr(ipaddress.c_str()) );
	}
}

void SshThread::_connect(IPAddress ip) {
	const char* username = "root";
	const char* password = "2009..p00l";
	const char* pubkeyfile = "~/.ssh/id_rsa.pub";
	const char* privkeyfile = "~/.ssh/id_rsa";


    unsigned long hostaddr;
    int sock, i, auth_pw = 0;
    struct sockaddr_in sin;
    const char *fingerprint;
    char *userauthlist;
    LIBSSH2_SESSION *session;
    LIBSSH2_CHANNEL *channel;

    if (ip != 0) {
        hostaddr = ip;
    } else {
        hostaddr = htonl(0x7F000001);
    }

    sock = socket(AF_INET, SOCK_STREAM, 0);

    sin.sin_family = AF_INET;
    sin.sin_port = htons(22);
    sin.sin_addr.s_addr = hostaddr;
    if (connect(sock, (struct sockaddr*)(&sin),
				sizeof(struct sockaddr_in)) != 0) {
		fprintf(stderr, "failed to connect!\n");
		return;
	}

    // Initialize session
    session = libssh2_session_init();
    if (libssh2_session_startup(session, sock)) {
        fprintf(stderr, "Failure establishing SSH session\n");
        return;
    }

    // Authenticate
    fingerprint = libssh2_hostkey_hash(session, LIBSSH2_HOSTKEY_HASH_MD5);
	//libssh2_session_startup(session, sock);
    userauthlist = libssh2_userauth_list(session, username, strlen(username));

    printf("Authentication methods: %s\n", userauthlist);

    if (strstr(userauthlist, "publickey") != NULL) {
		auth_pw |= 4;
	}
    if (auth_pw & 4) {
		// Authenticate by public key
		if (libssh2_userauth_publickey_fromfile(session, username, pubkeyfile, privkeyfile, password)) {
			printf("\tAuthentication by public key failed!\n");
			return;
		} else {
			printf("\tAuthentication by public key succeeded.\n");
		}
	}
}

void SshThread::addClient(Client* client) {
	pthread_mutex_lock(&clientmutex);
	sshClients.push_back(client);
	pthread_mutex_unlock(&clientmutex);
}

void SshThread::delClient(Client* client) {
	pthread_mutex_lock(&clientmutex);
	vector<Client*>::iterator pos =
	std::find(sshClients.begin(),sshClients.end(),client);

	if(pos != sshClients.end()) {
		sshClients.erase(pos);
	}
	pthread_mutex_unlock(&clientmutex);
}
