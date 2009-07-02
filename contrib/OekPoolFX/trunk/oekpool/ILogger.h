/*
 * ICommand.h
 *
 *  Created on: 02.07.2009
 *      Author: bw21
 */

#ifndef ICOMMAND_H_
#define ICOMMAND_H_

#include "Client.h"

class ILogger  {
protected:
	loglevel_t loglevel;
public:

	// Client* == 0x0 -> all clients/ no clients
	virtual void log(loglevel_t lvl, std::string msg, const Client* client) = 0;
};

#endif /* ICOMMAND_H_ */
