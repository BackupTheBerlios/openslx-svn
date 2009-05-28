/*
 * NetworkTests.h
 *
 *  Created on: 28.05.2009
 *      Author: jb78
 */

#ifndef NETWORKTESTS_H_
#define NETWORKTESTS_H_

#include "Network.h"

class NetworkTests {
public:
	NetworkTests();
	virtual ~NetworkTests();
	void runTests(void);
private:
	void wolTests(void);
	void pingTests(void);
};

#endif /* NETWORKTESTS_H_ */
