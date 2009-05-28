/*
 * NetworkTests.cpp
 *
 *  Created on: 28.05.2009
 *      Author: jb78
 */

#include "NetworkTests.h"
#include <iostream>

NetworkTests::NetworkTests() {
	// TODO Auto-generated constructor stub

}

NetworkTests::~NetworkTests() {
	// TODO Auto-generated destructor stub
}

void NetworkTests::runTests() {
	pingTests();
}

void NetworkTests::wolTests() {
	Network* net = Network::getInstance();
	ipaddr_t ip = (1L<<24) + (9L<<16) + (4L<<8) + 10L;
	std::vector<networkInfo> v;
	networkInfo test_net;
	test_net.broadcastAddress = (255L<<24) + (9L<<16) + (4L<<8) + 10;
	test_net.networkAddress = (0L<<24) | (9L<<8) | (4L<<8) | 10L;
	test_net.subnetMask = (0L<<24) | (255L<<16) | (255L<<8) | 255L;
	v.push_back(test_net);
	net->setNetworks(v);
	net->sendWolPacket(ip, "00:23:54:c6:1c:ae");
}

void NetworkTests::pingTests() {
	Network* net = Network::getInstance();
	bool flag;
	net->pingHost(flag, "132.230.4.26");
}
