/*
 * main.cpp
 *
 *  Created on: 28.05.2009
 *      Author: jb78
 */

#include "main.h"

int main(void) {
	NetworkTests* nt = new NetworkTests();
	nt->runTests();
	delete nt;
}
