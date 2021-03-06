/*
 * Network.h
 *
 *  Created on: 23.04.2009
 *      Author: julian
 */

#ifndef NETWORK_H_
#define NETWORK_H_

#include <stdio.h>
#include <iostream>
#include <vector>

#include <TcpSocket.h>
#include <UdpSocket.h>
#include <ISocketHandler.h>
#include "types.h"
#include <StdoutLog.h>


using namespace std;

class Network {
public:
	virtual ~Network();
	static Network * getInstance();

	bool sendWolPacket(ipaddr_t ipAddress, std::string macAddress);
	void setNetworks(vector<networkInfo>);
	void hostAlive(char& flag, string host, pthread_mutex_t* mutex);
private:
	Network();
	Network(const Network& cc);
	static void* pingHost(void* pingArgs);
	void createWolSequ(std::string macAddress, 	// MAC Address of the client
			char* sequence			// Char array where sequence is
												// written to
			);
	ipaddr_t createBroadcast(ipaddr_t ipAddress);
	std::vector<char> splitAddress(std::string address,
			std::string format,
			std::string delimiter
			);
	// bool createPing(const char* host);

	vector<networkInfo> availableNetworks;
};

//==============================================================================

// Socket for the network ping

class pingSocket : public TcpSocket {

public:
	pingSocket(ISocketHandler& );
	void OnConnect(void);

};

//==============================================================================

class errorLog : public StdoutLog {

public:
	void setFlag(bool&);
	void setMutex(pthread_mutex_t*);
	void error(ISocketHandler *, Socket *, const std::string &call, int err, const std::string &sys_err, loglevel_t);

private:
	bool* flag;
	pthread_mutex_t* mutex;
};

#endif /* NETWORK_H_ */
