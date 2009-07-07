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
	Utility();
	virtual ~Utility();
public:

	static
	IPAddress ipFromString(std::string ip);

	/**
	 * function to split ip ranges from ldap ipaddress datatype
	 */
	static
	std::pair<std::string, std::string> splitIPRange(std::string range);

	static
	std::string getPXEFilename(std::string mac);

	/**
	 * function to convert various types to string
	 */
	static
	std::string toString(int);

	/**
	 * function to convert various types to int
	 */
	static
	int toInt(std::string);

	static
	std::vector<std::string> stringSplit(std::string, std::string, std::vector<std::string>);
};

#endif /* UTILITY_H_ */
