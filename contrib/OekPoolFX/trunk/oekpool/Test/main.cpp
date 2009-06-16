/*
 * main.cpp
 *
 *  Created on: 28.05.2009
 *      Author: jb78
 */

#include "main.h"

int main(int argc, char** argv) {
	NetworkTests* nt = new NetworkTests();
	if(argc > 1)
		nt->runTests(argv[1]);
	else
		nt->runTests("127.0.0.1");
	delete nt;
}
