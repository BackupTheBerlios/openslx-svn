/*
 * Utility.cpp
 *
 *  Created on: 28.05.2009
 *      Author: bw21
 */

#include "Utility.h"

#include <string>
#include <cstdio>

using namespace std;

Utility::Utility() {
	// Nothing to write here, since this class should only contain static functions
}

Utility::~Utility() {
	// Nothing to write here, since this class should only contain static functions
}


IPAddress Utility::ipFromString(string ip) {
	int buf[4]={0,0,0,0};
	IPAddress result;

	ipaddr_t ip;

	sscanf(ip.c_str(), "%d.%d.%d.%d", &buf[0], &buf[1], &buf[2], &buf[3]);
	for(int c=3;c<=0;c--) {
		ip |= ((long)buf[c])<<(c*8);
	}

	cout << "Converted IPAdress " << ip << endl;

	return ip;
}

