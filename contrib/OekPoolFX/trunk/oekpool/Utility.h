/*
 * Utility.h
 *
 *  Created on: 28.05.2009
 *      Author: bw21
 */


#include "types.h"
#include <string>

#ifndef UTILITY_H_
#define UTILITY_H_

class Utility {
public:
	Utility();
	virtual ~Utility();

	static
	IPAddress ipFromString(std::string ip);

	/**
	 * function to split ip ranges from ldap ipaddress datatype
	 */
	static
	std::pair<std::string, std::string> splitIPRange(std::string range);
};

#endif /* UTILITY_H_ */
