/*
 * FileLogger.cpp
 *
 *  Created on: 02.07.2009
 *      Author: bw21
 */

#include "FileLogger.h"
#include "Configuration.h"
#include <iostream>
#include <fstream>

using namespace std;

FileLogger::FileLogger(string filename)
: filename(filename),
  file(filename.c_str())
{

	if(!file) {
		cerr << filename << " could not be opened for writing!" << endl;
		return;
	}
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

FileLogger::~FileLogger() {
	// TODO Auto-generated destructor stub
}

void FileLogger::log(loglevel_t lvl, std::string msg, const Client* client) {
	if(!file) return;
	if(loglevel < lvl ) return;

	switch(lvl) {
	case LOG_LEVEL_FATAL:
		file << "[FF] ";
		break;
	case LOG_LEVEL_ERROR:
		file << "[EE] ";
		break;
	case LOG_LEVEL_WARNING:
		file << "[WW] ";
		break;
	case LOG_LEVEL_INFO:
		file << "[II] ";
		break;
	}

	if(client == 0) {
		file << msg << endl;
	}
	else {
		file << ((Client*)client)->getHostName() << ": " << msg << endl;
	}
}

