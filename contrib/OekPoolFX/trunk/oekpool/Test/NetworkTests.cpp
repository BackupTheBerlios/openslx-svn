/*
 * NetworkTests.cpp
 *
 *  Created on: 28.05.2009
 *      Author: jb78
 */

#include "NetworkTests.h"

NetworkTests::NetworkTests() {
	// TODO Auto-generated constructor stub

}

NetworkTests::~NetworkTests() {
	// TODO Auto-generated destructor stub
}

void NetworkTests::runTests() {
	Network* net = Network::getInstance();
	IPAddress ip;
	ip.push_back(10);
	ip.push_back(4);
	ip.push_back(9);
	ip.push_back(255);

	net->sendWolPacket(ip, "00:23:54:c6:1c:ae");
}
