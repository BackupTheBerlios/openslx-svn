/*
 * SocketLogger.cpp
 *
 *  Created on: 02.07.2009
 *      Author: bw21
 */

#include "SocketLogger.h"
#include "CommandListener.h"
#include <algorithm>
#include <boost/foreach.hpp>

using namespace std;

SocketLogger::SocketLogger(CommandListener* p) {
	cmd = p;
}

SocketLogger::~SocketLogger() {

}

void SocketLogger::addClient(Client* c) {
	vector<Client*>::iterator
		it = find(logClients.begin(),logClients.end(),c);
	if(it == logClients.end()) {
		logClients.push_back(c);
	}
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

	vector<Client*>::iterator it = std::find(logClients.begin(),logClients.end(),client);
	if(it != logClients.end()) {
		switch(lvl) {
		case LOG_LEVEL_FATAL:
			cmd->Send("[FF] " + (*it)->getHostName() + ": " + msg + "\n");
			break;
		case LOG_LEVEL_ERROR:
			cmd->Send("[EE] " + (*it)->getHostName() + ": " + msg + "\n");
			break;
		case LOG_LEVEL_WARNING:
			cmd->Send("[WW] " + (*it)->getHostName() + ": " + msg + "\n");
			break;
		case LOG_LEVEL_INFO:
			cmd->Send("[II] " + (*it)->getHostName() + ": " + msg + "\n");
			break;
		default:
			return;
			break;
		}


		cmd->SendPrompt();
	}
}
