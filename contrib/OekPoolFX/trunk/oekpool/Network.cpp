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
#include <limits>
#include <stdlib.h>
#include <SocketHandler.h>



#include "Network.h"

using namespace std;

Network::Network() {

}

Network::~Network() {

}

Network * Network::getInstance() {
	static Network instance;
	return &instance;
}

void Network::createWolSequ(std::string macAddress, char* sequence) {
	std::vector<char> macComponent (splitAddress(macAddress, "%x", ":"));
	int i;

	for(i = 0; i < 6; i++){
		sequence[i] = 255;
	}

	for(i = 0; i < 92; i++){
		sequence[i+6] = macComponent[i%6];
	}
}

IPAddress Network::createBroadcast(IPAddress ipAddress) {
	bool networkFound = false;
	unsigned int i;

	for(i = 0; i < availableNetworks.size(); i++) {
		for(int z = 0; z < 4; z++ ) {
			networkFound = true;
			if( ( ipAddress[z] & availableNetworks[i].networkAddress[z] ) !=
				availableNetworks[i].networkAddress[z] )
			{
				networkFound = false;
				break;
			}
		}

		if(networkFound == true)
			break;
	}

	return availableNetworks[i].broadcastAddress;
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
		segment = strtok(NULL, delimiter.c_str());
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

void Network::pingHost(bool& flag, const char* host) {
	SocketHandler h;
	pingSocket* p = new pingSocket(h);
	if (p->Open(host, 80))
		p->Close();
}

void Network::setNetworks(std::vector<networkInfo> networks) {
	availableNetworks = networks;
}

bool Network::sendWolPacket(IPAddress ip, std::string mac) {

	IPAddress broadcats = createBroadcast(ip);
	char packet[102];

	createWolSequ(mac, packet);
	const std::string pack(packet);

	SocketHandler h;
	UdpSocket p(h);
	p.SetBroadcast(true);

	char buffer[16];
	snprintf(buffer, 16, "%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3]);
	const std::string ip_addr(buffer);

	p.SendTo(ip_addr, 99, packet);
	p.SendTo(ip_addr, 99, packet);
	p.SendTo(ip_addr, 99, packet);

	return true;
}

//=================================================================================

pingSocket::pingSocket(ISocketHandler& h) : TcpSocket(h) {

}
