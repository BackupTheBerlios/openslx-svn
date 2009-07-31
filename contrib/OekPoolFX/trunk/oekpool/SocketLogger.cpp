/*
 * SocketLogger.cpp
 *
 *  Created on: 02.07.2009
 *      Author: bw21
 */

#include "SocketLogger.h"
#include <algorithm>
#include <boost/foreach.hpp>

using namespace std;

SocketLogger::SocketLogger(CommandListener* p) {
	cmd = p;
}

SocketLogger::~SocketLogger() {

}

void SocketLogger::addClient(Client* c) {
	logClients.push_back(c);
}

void SocketLogger::delClient(Client* c) {
	vector<Client*>::iterator
	it = find(logClients.begin(),logClients.end(),c);
	if(it != logClients.end()) {
		logClients.erase(it);
	}
}

void SocketLogger::log(loglevel_t lvl, std::string msg,const Client* client) {
	if(loglevel < lvl ) return;

	// TODO: replace clog with e.g. cmd->write(string)

	if(client != NULL) {
		switch(lvl) {
		case LOG_LEVEL_FATAL:
			clog << "[FF] " + client->getHostName() + ": " + msg + "\n";
			break;
		case LOG_LEVEL_ERROR:
			clog << "[EE] " + client->getHostName() + ": " + msg + "\n";
			break;
		case LOG_LEVEL_WARNING:
			clog << "[WW] " + client->getHostName() + ": " + msg + "\n";
			break;
		case LOG_LEVEL_INFO:
			clog << "[II] " + client->getHostName() + ": " + msg + "\n";
			break;
		}
	}

	BOOST_FOREACH(Client* cl, logClients) {
		switch(lvl) {
		case LOG_LEVEL_FATAL:
			clog << "[FF] " + cl->getHostName() + ": " + msg + "\n";
			break;
		case LOG_LEVEL_ERROR:
			clog << "[EE] " + cl->getHostName() + ": " + msg + "\n";
			break;
		case LOG_LEVEL_WARNING:
			clog << "[WW] " + cl->getHostName() + ": " + msg + "\n";
			break;
		case LOG_LEVEL_INFO:
			clog << "[II] " + cl->getHostName() + ": " + msg + "\n";
			break;
		}
	}
}
