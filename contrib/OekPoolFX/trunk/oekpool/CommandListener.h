/*
 * CommandListener.h
 *
 *  Created on: 02.07.2009
 *      Author: jb78
 */

#ifndef COMMANDLISTENER_H_
#define COMMANDLISTENER_H_

#include "TcpSocket.h"

class CommandListener : public TcpSocket {
public:
	CommandListener(ISocketHandler&);
	virtual ~CommandListener();

	void OnAccept(void);
	void OnLine(const std::string&);
};

#endif /* COMMANDLISTENER_H_ */
