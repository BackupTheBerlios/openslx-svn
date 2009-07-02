/*
 * types.h
 *
 *  Created on: 19.05.2009
 *      Author: bw21
 */

#include <string>
#include <vector>
#include <map>
#include <pthread.h>
#include "include/libssh2.h"
#include <netinet/in.h>
#include <sys/socket.h>
#include "StdLog.h"
#include "Client.h"


#ifndef TYPES_H_
#define TYPES_H_

typedef std::map<std::string,std::string> AttributeMap;
typedef unsigned long IPAddress;

struct networkInfo{
	IPAddress networkAddress;
	IPAddress subnetMask;
	IPAddress broadcastAddress;
};

struct Client; // forward declaration for Clientstates
struct SSHInfo {
	Client* client;
    struct sockaddr_in sin;
    const char *fingerprint;
    char *userauthlist;
    int sock; // Socket
    LIBSSH2_SESSION *session;
    LIBSSH2_CHANNEL *channel;
};

struct PXESlot {
	std::string cn;
	std::string TimeSlot;
	bool ForceBoot;
};

struct PXEInfo {
	std::string MenuName;
	std::string TimeString;
	tm StartTime;
	tm ShutdownTime;
	bool ForceBoot;
};

struct pingStruct {
	char* alive;
	pthread_mutex_t * mutex;
	std::string ipAddress;
};
#endif /* TYPES_H_ */
