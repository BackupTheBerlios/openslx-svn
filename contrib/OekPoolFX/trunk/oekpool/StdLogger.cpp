/*
 * StdLogger.cpp
 *
 *  Created on: 02.07.2009
 *      Author: bw21
 */

#include "StdLogger.h"
#include "Configuration.h"
#include "types.h"

#include <iostream>
#include <algorithm>

using namespace std;


StdLogger::StdLogger() {
	Configuration* conf = Configuration::getInstance();
	string llvl = conf->getString("log_level");
	if(llvl == "fatal") {
		loglevel = LOG_LEVEL_FATAL;
	}
	else if(llvl == "error")
	{
		loglevel = LOG_LEVEL_ERROR;
	}
	else if(llvl == "warning") {
		loglevel = LOG_LEVEL_WARNING;
	}
	else if(llvl == "info") {
		loglevel = LOG_LEVEL_INFO;
	}
	else {
		loglevel = LOG_LEVEL_ERROR;
	}
}

StdLogger::~StdLogger() {
	// TODO Auto-generated destructor stub
}


void StdLogger::log(loglevel_t lvl, std::string msg,const Client* client) {
	if(loglevel < lvl ) return;

	switch(lvl) {
	case LOG_LEVEL_FATAL:
		clog << "[FF] ";
		break;
	case LOG_LEVEL_ERROR:
		clog << "[EE] ";
		break;
	case LOG_LEVEL_WARNING:
		clog << "[WW] ";
		break;
	case LOG_LEVEL_INFO:
		clog << "[II] ";
		break;
	}

	if(client == 0) {
		clog << msg << endl;
	}
	else {
		clog << ((Client*)client)->getHostName() << ": " << msg << endl;
	}
}
