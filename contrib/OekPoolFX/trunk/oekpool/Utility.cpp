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

using namespace std;

Utility::Utility() {
	// Nothing to write here, since this class should only contain static functions
}

Utility::~Utility() {
	// Nothing to write here, since this class should only contain static functions
}


IPAddress Utility::ipFromString(string ip) {
	int buf[4]={0,0,0,0};

	IPAddress ipl = 0;
	long ltemp = 0L;

	sscanf(ip.c_str(), "%d.%d.%d.%d", &buf[0], &buf[1], &buf[2], &buf[3]);
//	cout << "Integer Buffer: " << buf[0] << "." << buf[1] << "." << buf[2] << "." << buf[3] << endl;
	for(int c=3;c>=0;c--) {
	    ltemp = buf[c];
		ipl += (ltemp<<(c*8));
	}

//	cout << "IPAddress to convert: " << ip << endl;
//	cout << "IPAddress converted:  " << ipl << endl;

	return ipl;
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
