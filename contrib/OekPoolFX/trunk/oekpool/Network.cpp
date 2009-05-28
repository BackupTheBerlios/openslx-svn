/*
 * Network.cpp
 *
 *  Created on: 23.04.2009
 *      Author: julian
 */
#include <stdio.h>
#include <string.h>
#include <iostream>
#include <vector>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <limits>
#include <stdlib.h>

#include "Network.h"

using namespace std;

Network::Network() {
	// TODO Auto-generated constructor stub

}

Network::~Network() {
	// TODO Auto-generated destructor stub
}

Network * Network::getInstance() {
	static Network instance;
	return &instance;
}

void Network::createWolSequ(std::string macAddress, char(&sequence)[102]) {
	std::vector<char> macComponent (splitAddress(macAddress, "%x", ":"));
	int i;



		for(i = 0; i < 6; i++){
		sequence[i] = 255;
	}

	for(i = 0; i < 92; i++){
		sequence[i+6] = macComponent[i%6];
	}
}

std::string Network::createBroadcast(std::string ipAddress) {
	vector<char> ip (splitAddress(ipAddress, "%d", "."));
	bool networkFound = false;
	char buffer [16];
	unsigned int i;

	for(i = 0; i < availableNetworks.size(); i++) {
		for(int z = 0; z < 4; z++ ) {
			networkFound = true;
			if( ( ip[z] & availableNetworks[i].networkAddress[z] ) !=
				availableNetworks[i].networkAddress[z] )
			{
				networkFound = false;
				break;
			}
		}

		if(networkFound == true)
			break;
	}

	sprintf(buffer, "%d.%d.%d.%d",
			availableNetworks[i].broadcastAddress[0],
			availableNetworks[i].broadcastAddress[1],
			availableNetworks[i].broadcastAddress[2],
			availableNetworks[i].broadcastAddress[3]
			);
	string bcString (buffer);
	return bcString;
}

std::vector<char> Network::splitAddress(std::string address, std::string format, string delimiter) {

	std::vector<char> component;
	char * str = strdup(address.c_str());
	const char * cformat = format.c_str();
	char * segment;
	int charByte;

	segment = strtok(str, delimiter.c_str());

	while(segment != NULL){
		sscanf(segment, cformat, &charByte);
		component.push_back((char)charByte);
		strtok(NULL, delimiter.c_str());
	}



	/*result = address.find(delimiter);
	while(result != std::string::npos)
	{
		result = address.find(delimiter, result+1 );
		sscanf(address.substr(result + 1,2).c_str(), format.c_str(), &charByte);
		component.push_back((char) charByte);
	}*/




    free(str);
	return component;
}
