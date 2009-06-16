/*
 * Utility.cpp
 *
 *  Created on: 28.05.2009
 *      Author: bw21
 */

#include "Utility.h"

#include <string>
#include <iostream>
#include <cstdio>

#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>

using namespace std;

Utility::Utility() {
	// Nothing to write here, since this class should only contain static functions
}

Utility::~Utility() {
	// Nothing to write here, since this class should only contain static functions
}


IPAddress Utility::ipFromString(string ip) {
	return inet_addr(ip.c_str());
}

pair<string,string>
Utility::splitIPRange(string range) {

    pair<string,string> result;
    string::size_type cutAt;
    if((cutAt = range.find_first_of('_')) != string::npos) {
        result.first = range.substr(0,cutAt);
        result.second = range.substr(cutAt+1);
    }

    return result;
}
