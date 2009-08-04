/*
 * CommandListener.cpp
 *
 *  Created on: 02.07.2009
 *      Author: jb78
 */

#include "CommandListener.h"
#include <SocketHandler.h>
#include "SocketLogger.h"
#include "Utility.h"
#include "Client.h"


std::map<std::string, Client*>* CommandListener::clientList;
pthread_mutex_t* CommandListener::clientListMutex;

CommandListener::CommandListener(ISocketHandler& h) : TcpSocket(h) {
	logger = NULL;
	SetLineProtocol();
}

CommandListener::~CommandListener() {

}

void CommandListener::OnAccept() {
	if(GetRemoteAddress() != "127.0.0.1") {
		Send("Remote access denied!\n");
		SetCloseAndDelete();
		return;
	}

	logger = new SocketLogger(this);
	Send("Connection established\n");
}

void CommandListener::OnLine(const std::string& line) {

	std::vector<std::string> cmd;
	std::string error;
	bool success;

	Utils::stringSplit(line, " ", cmd);

	if(cmd.size() >= 1){

		if(cmd[0] == "query"){
			success = cmd_query(cmd, error);
		}
		else if(cmd[0] == "list"){
			success = cmd_list(cmd, error);
		}
		else if(cmd[0] == "takeover"){
			success = cmd_takeover(cmd, error);
		}
		else if(cmd[0] == "release"){
			success = cmd_release(cmd, error);
		}
		else if(cmd[0] == "start"){
			success = cmd_start(cmd, error);
		}
		else if(cmd[0] == "shutdown"){
			success = cmd_shutdown(cmd, error);
		}
		else if(cmd[0] == "execute"){
			success = cmd_execute(line, error);
		}
		else{
			success = false;
			Send("Command \"" + cmd[0] + "\" not recognized.");
		}

		if(success){
			Send(error + "\n");
		}
		else{
			Send("ERROR: " + error + "\n");
		}
	}

	SendPrompt();
}

void CommandListener::SendPrompt(){
	Send("> \n");
}

bool CommandListener::cmd_execute(std::string line, std::string& error){
	std::string temp, cmd, client;
	std::vector<std::string> params;
	Client* clientObj = NULL;

	if(!Utils::stringFindCmd(line, cmd, temp)){
		error = "Bad syntax: Please check your \"'s";
		return false;
	}

	Utils::stringSplit(temp, " ", params);
	if(params.size() != 2){
		error = "Wrong number of arguments.\nUsage: execute [ip address | mac address | hostname] \"command\"";
		return false;
	}

	clientObj = getClient(params[1]);

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

		clientObj = getClient(params[2]);

		if(clientObj == NULL){
			error = "Client \"" + params[2] + "\" not found.";
			return false;
		}

		pxeslots = clientObj->remote_getPXEInfo();

		error = "";
		for(int i = 0; i < pxeslots.size(); i++){
			error = error + Utils::toString(i) + ". " + pxeslots[i].MenuName +"\n";
		}

		return true;
	}
	else{
		error = "Usage: list clients\n       list pxe [ip address | mac address | hostname]";
		return false;
	}
}

bool CommandListener::cmd_query(std::vector<std::string> params, std::string& error){

	if(params.size() < 2){
		error = "Please supply more arguments.\nUsage: query [ip address | mac address | hostname]";
		return false;
	}

	Client* clientObj = NULL;

	clientObj = getClient(params[1]);

	if(clientObj == NULL){
		error = "Client \"" + params[1] + "\" not found.";
		return false;
	}

	error = clientObj->remote_queryState();
	return true;
}

bool CommandListener::cmd_takeover(std::vector<std::string> params, std::string& error){
	if(params.size() < 2){
		error = "Please supply more arguments.\nUsage: takeover [ip address | mac address | hostname]";
		return false;
	}
	Client* clientObj;

	clientObj = getClient(params[1]);

	if(clientObj == NULL){
		error = "Client \"" + params[1] + "\" not found.";
		return false;
	}

	if(!clientObj->remote_takeOver(this)){
		error = "Client \"" + params[1] + "\" could not be taken. It might not be in offline state or has been taken by somebody else.";
		return false;
	}

	error = "Client \"" + params[1] + "\" has been taken successfully. You may now change PXE settings.";
	return true;
}

bool CommandListener::cmd_release(std::vector<std::string> params, std::string& error){
	if(params.size() < 2){
		error = "Please supply more arguments.\nUsage: takeover [ip address | mac address | hostname]";
		return false;
	}

	Client* clientObj;

	clientObj = getClient(params[1]);

	if(clientObj == NULL){
		error = "Client \"" + params[1] + "\" not found.";
		return false;
	}

	if(!clientObj->remote_release(this)){
		error = "Client \"" + params[1] + "\" has not been taken.";
		return false;
	}

	error = "Client \"" + params[1] + "\" has been released.";
	return true;
}

bool CommandListener::cmd_start(std::vector<std::string> params, std::string& error){
	if(params.size() < 3){
		error = "Please supply more arguments.\nUsage: takeover [ip address | mac address | hostname]";
		return false;
	}

	Client* clientObj;

	clientObj = getClient(params[1]);

	if(clientObj == NULL){
		error = "Client \"" + params[1] + "\" not found.";
		return false;
	}

	if(!clientObj->remote_isOwner(this)){
		error = "Client \"" + params[1] + "\" has not been taken.";
		return false;
	}

	bool wake;
	int pxeNo = Utils::toInt(params[2]);

	if(params.size() == 3){
		wake = false;
	}
	else{
		if(params[3] == "wake")
			wake = true;
	}


	if(!clientObj->remote_start(pxeNo, wake)){
		error = "Client \"" + params[1] + "\" could not be set up. PXE menu does not exist.";
		return false;
	}

	error = "Client \"" + params[1] + "\" has been set up successfully.";
	return true;
}

bool CommandListener::cmd_shutdown(std::vector<std::string> params, std::string& error){
	if(params.size() < 2){
		error = "Please supply more arguments.\nUsage: takeover [ip address | mac address | hostname]";
		return false;
	}

	Client* clientObj;

	clientObj = getClient(params[1]);

	if(clientObj == NULL){
		error = "Client \"" + params[1] + "\" not found.";
		return false;
	}

	if(!clientObj->remote_isOwner(this)){
		error = "Client \"" + params[1] + "\" has not been taken.";
		return false;
	}

	clientObj->remote_shutdown();
	return true;
}

Client* CommandListener::getClient(std::string client){
	Client* clientObj = NULL;
	std::map<std::string, Client*>::iterator it;

	pthread_mutex_lock(clientListMutex);
	for(it = clientList->begin(); it != clientList->end(); it++){
		if((client == it->second->getIP()) ||
				(client == it->second->getHWAddress()) ||
				(client == it->second->getHostName()))
		{
			clientObj = it->second;
			break;
		}
	}
	pthread_mutex_unlock(clientListMutex);
	return clientObj;
}

void CommandListener::setClientList(std::map<std::string, Client*>* clist) {
	clientList = clist;
}

void CommandListener::setClientListMutex(pthread_mutex_t* clist_mutex) {
	clientListMutex = clist_mutex;
}
