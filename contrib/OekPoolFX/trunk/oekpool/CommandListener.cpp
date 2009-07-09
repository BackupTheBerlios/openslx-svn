/*
 * CommandListener.cpp
 *
 *  Created on: 02.07.2009
 *      Author: jb78
 */

#include "CommandListener.h"
#include <SocketHandler.h>
#include "Utility.h"

CommandListener::CommandListener(ISocketHandler& h) : TcpSocket(h) {
	SetLineProtocol();
}

CommandListener::~CommandListener() {
	// TODO Auto-generated destructor stub
}

void CommandListener::OnAccept() {
	Send("Connection established\n");
}

void CommandListener::OnLine(const std::string& line) {

	//std::vector<std::string> cmd = Utility::stringSplit(line);

}
