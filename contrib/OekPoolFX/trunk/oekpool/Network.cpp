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

	for(i = 0; i < 96; i++){
		sequence[i+6] = macComponent[i%6];
		//printf("%x\n", sequence[i+6]);
	}
}

ipaddr_t Network::createBroadcast(ipaddr_t ipAddress) {
	unsigned int i;

	for(i = 0; i < availableNetworks.size(); i++) {

		if((availableNetworks[i].subnetMask & ipAddress) == availableNetworks[i].networkAddress)
			break;
	}

	return (ipaddr_t)availableNetworks[i-1].broadcastAddress;
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
	errorLog log;
	log.setFlag(flag);
	h.RegStdLog(&log);

	p->Open(host, 22);
	h.Add(p);
	h.Select(1,0);
	while (h.GetCount())
	{
		h.Select(1,0);
	}
}

void Network::setNetworks(std::vector<networkInfo> networks) {
	availableNetworks = networks;
}

bool Network::sendWolPacket(ipaddr_t ip, std::string mac) {

	ipaddr_t broadcast = createBroadcast(ip);
	cout << broadcast << "\n";
	char packet[102];

	createWolSequ(mac, packet);
	std::string pack;

	pack.assign(packet, 102);

	SocketHandler h;
	UdpSocket p(h);
	p.SetBroadcast(true);

	p.SendTo(broadcast, 99, pack);
	p.SendTo(broadcast, 99, pack);
	p.SendTo(broadcast, 99, pack);

	return true;
}

//==============================================================================

pingSocket::pingSocket(ISocketHandler& h) : TcpSocket(h) {

}

void pingSocket::OnConnect(void) {
	SetCloseAndDelete(true);
}

//==============================================================================

void errorLog::setFlag(bool& bFlag) {
	flag = &bFlag;
}

void errorLog::error(ISocketHandler *, Socket *, const std::string &call, int err, const std::string &sys_err, loglevel_t) {

	if((err == 113) or (err == -1))
		*flag = false;
	else
		*flag = true;
}
