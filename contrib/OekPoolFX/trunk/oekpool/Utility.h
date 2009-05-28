/*
 * Utility.h
 *
 *  Created on: 28.05.2009
 *      Author: bw21
 */


#include "types.h"

#ifndef UTILITY_H_
#define UTILITY_H_

class Utility {
public:
	Utility();
	virtual ~Utility();

	static
	IPAddress ipFromString(std::string ip);
};

#endif /* UTILITY_H_ */
