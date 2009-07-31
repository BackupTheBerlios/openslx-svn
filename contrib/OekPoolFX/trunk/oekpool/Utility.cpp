/*
 * Utility.cpp
 *
 *  Created on: 28.05.2009
 *      Author: bw21
 */

#include "Utility.h"

#include <string>
#include <iostream>
#include <sstream>
#include <cstdio>

#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>

using namespace std;

template string Utility::toString<int>(int);
template string Utility::toString<unsigned int>(unsigned int);
template string Utility::toString<long>(long);


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

string Utility::getPXEFilename(string mac){
	size_t found = mac.find_first_of(":");

	while(found != string::npos) {
		mac[found] = '-';
		found = mac.find_first_of(":", found + 1);
	}

	string str("01-");

	return str.append(mac);
}

template<typename T>
string Utility::toString(T bla) {
	ostringstream o;
	o.clear();
	o << bla;
	return o.str();
}

int Utility::toInt(string bla) {
	istringstream i;
	i.str(bla);
	int result = 0;
	i >> result;

	return result;
}

void Utility::stringSplit(std::string str, std::string delim, std::vector<std::string>& results) {

	int cutAt;

	while( (cutAt = str.find_first_of(delim)) != str.npos ) {
		if(cutAt > 0) {
			results.push_back(str.substr(0,cutAt));
		}
		str = str.substr(cutAt+1);
	}
	if(str.length() > 0) {
		results.push_back(str);
	}
}

bool Utility::stringFindCmd(std::string input, std::string& extract, std::string& output){
	size_t found,length;
	std::vector<size_t> quoteVec;

	found = input.find("\"", 0);

	while(found != input.npos){
		quoteVec.push_back(found);
		found = input.find("\"", found);
	}

	if(quoteVec.size() != 0){
		return false;
	}

	length = quoteVec[1] - quoteVec[0] - 1;
	extract = input.substr(quoteVec[0]+1, length);
	output = input.replace(quoteVec[0], length + 2,"");
	return true;
}
