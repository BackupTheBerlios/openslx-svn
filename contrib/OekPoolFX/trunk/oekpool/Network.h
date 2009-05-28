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

using namespace std;

struct networkInfo{
	vector<char> networkAddress;
	vector<char> subnetMask;
	vector<char> broadcastAddress;
};


class Network {
public:
	virtual ~Network();
	static Network * getInstance();

	bool sendWolPacket(std::string ipAddress, std::string macAddress);

private:
	Network();
	Network(const Network& cc);
	void createWolSequ(std::string macAddress, 	// MAC Address of the client
			char(&sequence) [102]			// Char array where sequence is
												// written to
			);
	std::string createBroadcast(std::string ipAddress);
	std::vector<char> splitAddress(std::string address,
			std::string format,
			std::string delimiter
			);

	vector<networkInfo> availableNetworks;
};

#endif /* NETWORK_H_ */
