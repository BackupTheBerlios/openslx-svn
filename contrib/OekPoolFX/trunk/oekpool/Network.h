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


using namespace std;

class Network {
public:
	virtual ~Network();
	static Network * getInstance();

	bool sendWolPacket(IPAddress ipAddress, std::string macAddress);
	void pingHost(bool& flag, const char* host);
	void setNetworks(vector<networkInfo>);

private:
	Network();
	Network(const Network& cc);
	void createWolSequ(std::string macAddress, 	// MAC Address of the client
			char* sequence			// Char array where sequence is
												// written to
			);
	IPAddress createBroadcast(IPAddress ipAddress);
	std::vector<char> splitAddress(std::string address,
			std::string format,
			std::string delimiter
			);
	bool createPing(const char* host);

	vector<networkInfo> availableNetworks;
};


// Socket for the network ping

class pingSocket : public TcpSocket {

public:
	pingSocket(ISocketHandler& );

};

#endif /* NETWORK_H_ */
