/*
 * CommandListener.cpp
 *
 *  Created on: 02.07.2009
 *      Author: jb78
 */

#include "CommandListener.h"
#include <SocketHandler.h>
#include "Utility.h"
#include "Client.h"


std::map<std::string, Client*>* CommandListener::clientList;
pthread_mutex_t* CommandListener::clientListMutex;

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

	std::vector<std::string> cmd;

	Utility::stringSplit(line, " ", cmd);

	if(cmd[0] == "query"){

	}
	else if(cmd[0] == "list"){

	}
	else if(cmd[0] == "takeover"){

	}
	else if(cmd[0] == "release"){

	}
	else if(cmd[0] == "start"){

	}
	else if(cmd[0] == "shutdown"){

	}
	else if(cmd[0] == "execute"){

	}
	else{
		Send("Command \"" + cmd[0] + "\" not recognized.");
	}
	SendPrompt();
}

void CommandListener::SendPrompt(){
	Send("> ");
}

bool CommandListener::cmd_execute(std::string line, std::string& error){
	std::string temp, cmd, client;
	std::vector<std::string> params;
	std::map<std::string, Client*>::iterator it;
	Client* clientObj = NULL;

	if(!Utility::stringFindCmd(line, cmd, temp)){
		error = "Bad syntax: Please check your \"'s";
		return false;
	}

	Utility::stringSplit(temp, " ", params);
	if(params.size() != 2){
		error = "Wrong number of arguments.\nUsage: execute [ip address | mac address | hostname] \"command\"";
		return false;
	}

	for(it = clientList->begin(); it != clientList->end(); it++){

		if((params[1] == it->second->getIP()) ||
				(params[1] == it->second->getHWAddress()) ||
				(params[1] == it->second->getHostName())){
			clientObj = it->second;
			break;
		}
	}

	if(clientObj == NULL){
		error = "Client \"" + params[1] + "\" not found.";
		return false;
	}

	clientObj->insertCmd(cmd, 0);

	return true;
}

bool CommandListener::cmd_list(std::vector<std::string> params, std::string& error){
	Client* clientObj = NULL;
	std::vector<PXEInfo> pxeslots;
	std::map<std::string, Client*>::iterator it;

	if(params.size() < 2){
		error = "Please supply more arguments.\nUsage: list clients\n       list pxe [ip address | mac address | hostname]";
		return false;
	}

	if(params[1] == "clients"){
		error = "";
		for(it = clientList->begin(); it != clientList->end(); it++){
			error = error + it->first + ": " + it->second->getHWAddress() + " (" + it->second->getIP() + ")\n";
		}
		return true;
	}
	else if(params[1] == "pxe"){
		if(params.size() < 3){
			error = "Please supply more arguments.\nUsage: list pxe [ip address | mac address | hostname]";
			return false;
		}

		for(it = clientList->begin(); it != clientList->end(); it++){
			if((params[2] == it->second->getIP()) ||
					(params[2] == it->second->getHWAddress()) ||
					(params[2] == it->second->getHostName()))
			{
				clientObj = it->second;
				break;
			}
		}

		if(clientObj == NULL){
			error = "Client \"" + params[1] + "\" not found.";
			return false;
		}

		pxeslots = clientObj->remote_getPXEInfo();

		error = "";
		for(int i = 0; i < pxeslots.size(); i++){
			error = error + Utility::toString(i) + ". " + pxeslots[i].MenuName +"\n";
		}

		return true;
	}
	else{
		error = "Usage: list clients\n       list pxe [ip address | mac address | hostname]";
		return false;
	}
}
