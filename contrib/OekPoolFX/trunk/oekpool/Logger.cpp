/*
 * Logger.cpp
 *
 *  Created on: 18.06.2009
 *      Author: bw21
 */

#include "Logger.h"
#include "Configuration.h"

#include <string>

using namespace std;

Logger::Logger() {
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

Logger::~Logger() {

}


void Logger::log(std::string msg, LogLevel lvl) {

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

	clog << msg << endl;
}
