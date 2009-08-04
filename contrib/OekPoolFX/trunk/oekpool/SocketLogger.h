/*
 * SocketLogger.h
 *
 *  Created on: 02.07.2009
 *      Author: bw21
 */

#ifndef SOCKETLOGGER_H_
#define SOCKETLOGGER_H_


#include "ILogger.h"
#include "Client.h"
#include <string>
#include <vector>

// forward decl
class CommandListener;

/**
 * @class SocketListener Support Logging through sockets
 *
 * 	This class holds a list of clients which can
 *  be changed through interface functions.
 *  This list determines wether output from specific clients
 *  has to be logged and which does not.
 */
class SocketLogger : ILogger {
	/**
	 * CommandListener cmd: Socket to log to
	 */
	CommandListener* cmd;

	/**
	 * vector<Client*> logClients: vector of clients to log from
	 */
	std::vector<Client*> logClients;
public:
	SocketLogger(CommandListener* p);
	~SocketLogger();

	/**
	 * Clients can be added/removed here to choose which
	 * one's output needs to be shown on the socket
	 */
	void addClient(Client* c);
	void delClient(Client* c);

	void log(loglevel_t lvl, std::string msg, const Client* client);
};

#endif /* SOCKETLOGGER_H_ */
