/*
 * types.h
 *
 *  Created on: 19.05.2009
 *      Author: bw21
 */

#include <string>
#include <vector>
#include <map>

#ifndef TYPES_H_
#define TYPES_H_

typedef std::map<std::string,std::string> AttributeMap;
typedef unsigned long IPAddress;

struct networkInfo{
	IPAddress networkAddress;
	IPAddress subnetMask;
	IPAddress broadcastAddress;
};

struct PXESlot {
	std::string cn;
	std::string TimeSlot;
	bool ForceBoot;
};

#endif /* TYPES_H_ */
