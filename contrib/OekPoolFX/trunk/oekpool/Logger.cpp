/*
 * Logger.cpp
 *
 *  Created on: 18.06.2009
 *      Author: bw21
 */

#include "Logger.h"
#include "Configuration.h"

#include <string>
#include <boost/foreach.hpp>

using namespace std;

Logger::Logger() {

}

Logger::~Logger() {
	deleteAllLogger();
}

void Logger::log(loglevel_t lvl, std::string msg, const Client* client) {
	BOOST_FOREACH(ILogger* lg, vecLogger) {
		lg->log(lvl, msg, client);
	}
}

void Logger::registerLogger(const ILogger* logger) {
	vecLogger.push_back((ILogger*)logger);
}

void Logger::removeLogger(const ILogger* logger) {

	vector<ILogger*>::iterator
	it = std::find(vecLogger.begin(), vecLogger.end(), logger);

	if (it != vecLogger.end()) {
		vecLogger.erase(it);
	}
}

void Logger::deleteAllLogger() {
	for(vector<ILogger*>::iterator
			it = vecLogger.begin();
			it!= vecLogger.end();
			it++) {
		delete *it;
	}
}
