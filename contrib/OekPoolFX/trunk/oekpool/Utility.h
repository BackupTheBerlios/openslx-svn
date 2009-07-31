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
	template<typename T>
	static
	std::string toString(T);

	/**
	 * function to convert various types to int
	 */
	static
	int toInt(std::string);

	/**
	 * function to split a string by a delimiter
	 */
	static
	void stringSplit(std::string, std::string, std::vector<std::string>&);

	/**
	 * function which finds a substring enclosed by inverted commas
	 */

	static
	bool stringFindCmd(std::string, std::string&, std::string&);

};

#endif /* UTILITY_H_ */
