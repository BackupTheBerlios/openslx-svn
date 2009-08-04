/*
 * CommandListener.cpp
 *
 *  Created on: 02.07.2009
 *      Author: jb78
 */

#include "CommandListener.h"
#include <SocketHandler.h>
#include "ILogger.h"
#include "SocketLogger.h"
#include "Utility.h"
#include "Client.h"
#include "LoggerFactory.h"

#include <boost/foreach.hpp>

std::map<std::string, Client*>* CommandListener::clientList;
pthread_mutex_t* CommandListener::clientListMutex;

CommandListener::CommandListener(ISocketHandler& h) : TcpSocket(h) {
	logger = NULL;
	SetLineProtocol();
}

CommandListener::~CommandListener() {
	if(logger!=NULL) {
		LoggerFactory::getInstance()->getGlobalLogger()->removeLogger((ILogger*)logger);
		delete logger;
	}
	for(int i; i < takenClients.size(); i++){
		takenClients[i]->remote_release(this);
	}
}

void CommandListener::OnAccept() {
	if(GetRemoteAddress() != "127.0.0.1") {
		Send("Remote access denied!\n");
		SetCloseAndDelete();
		return;
	}

	logger = new SocketLogger(this);
	LoggerFactory::getInstance()->getGlobalLogger()->registerLogger((ILogger*)logger);
	Send("Connection established\n");
}

void CommandListener::OnLine(const std::string& line) {

	std::vector<std::string> cmd;
	std::vector<Client*> clist;
	std::string error;
	bool success;

	Utils::stringSplit(line, " ", cmd);

	if(cmd.size()>1) {
		if(cmd[0].find("list") != std::string::npos)
		{
			if(cmd.size() == 3) {
				getClientList(cmd[2],clist, error);
			}
		}
		else {
			getClientList(cmd[1],clist, error);
		}
	}

	if(cmd.size() >= 1){

		if(cmd[0] == "query"){
			success = cmd_query(cmd, clist, error);
		}
		else if(cmd[0] == "list"){
			success = cmd_list(cmd, clist, error);
		}
		else if(cmd[0] == "takeover"){
			success = cmd_takeover(cmd, clist, error);
		}
		else if(cmd[0] == "release"){
			success = cmd_release(cmd, clist, error);
		}
		else if(cmd[0] == "start"){
			success = cmd_start(cmd, clist, error);
		}
		else if(cmd[0] == "shutdown"){
			success = cmd_shutdown(cmd, clist, error);
		}
		else if(cmd[0] == "execute"){
			success = cmd_execute(line, clist, error);
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
	Send("> ");
}

bool CommandListener::cmd_execute(std::string line, std::vector<Client*> clist, std::string& error){
	std::string temp, cmd, client;
	std::vector<std::string> params;
	Client* clientObj = NULL;

	if(!Utils::stringFindCmd(line, cmd, temp)){
		error += "\nBad syntax: Please check your \"'s";
		return false;
	}

	Utils::stringSplit(temp, " ", params);
	if(params.size() != 2){
		error += "\nWrong number of arguments.\nUsage: execute [ip address | mac address | hostname] \"command\"";
		return false;
	}

	BOOST_FOREACH(Client* cl, clist) {
		cl->insertCmd(cmd,0);
		logger->addClient(cl);
	}
	return true;
}

bool CommandListener::cmd_list(std::vector<std::string> params, std::vector<Client*> clist, std::string& error){
	Client* clientObj = NULL;
	std::vector<PXEInfo> pxeslots;
	std::map<std::string, Client*>::iterator it;

	if(params.size() < 2){
		error += "\nPlease supply more arguments.\nUsage: list clients\n       list pxe [ip address | mac address | hostname]";
		return false;
	}

	if(params[1] == "clients"){
		for(it = clientList->begin(); it != clientList->end(); it++){
			error +=  "\n" + it->second->getHWAddress() + ": " + it->second->getHostName() + " (" + it->second->getIP() + ")\n";
		}
		return true;
	}
	else if(params[1] == "pxe"){
		if(params.size() < 3){
			error += "\nPlease supply more arguments.\nUsage: list pxe [ip address | mac address | hostname]";
			return false;
		}

		BOOST_FOREACH(Client* cl, clist) {
			pxeslots = cl->remote_getPXEInfo();

			for(int i = 0; i < pxeslots.size(); i++){
				error += "\n" + Utils::toString(i) + ". " + pxeslots[i].MenuName +"\n";
			}
		}

		return true;
	}
	else{
		error += "\nUsage: list clients\n       list pxe [ip address | mac address | hostname]";
		return false;
	}
}

bool CommandListener::cmd_query(std::vector<std::string> params, std::vector<Client*> clist, std::string& error){

	if(params.size() < 2){
		error += "\nPlease supply more arguments.\nUsage: query [ip address | mac address | hostname]";
		return false;
	}

	BOOST_FOREACH(Client* cl, clist) {
		error += cl->remote_queryState();
	}

	return true;
}

bool CommandListener::cmd_takeover(std::vector<std::string> params, std::vector<Client*> clist, std::string& error){
	if(params.size() < 2){
		error += "\nPlease supply more arguments.\nUsage: takeover [ip address | mac address | hostname]";
		return false;
	}


	BOOST_FOREACH(Client* cl, clist) {
		if(!cl->remote_takeOver(this)){
			error += "\nClient \"" + cl->getHostName() + "\" could not be taken. It might not be in offline state or has been taken by somebody else.";
		}

		takenClients.push_back(cl);
		logger->addClient(cl);

		error += "\nClient \"" + cl->getHostName() + "\" has been taken successfully. You may now change PXE settings.";
	}


	return true;
}

bool CommandListener::cmd_release(std::vector<std::string> params, std::vector<Client*> clist, std::string& error){
	if(params.size() < 2){
		error += "\nPlease supply more arguments.\nUsage: takeover [ip address | mac address | hostname]";
		return false;
	}


	BOOST_FOREACH(Client* cl, clist) {
		if(!cl->remote_release(this)){
			error += "\nClient \"" + cl->getHostName() + "\" has not been taken.";
			return false;
		}

		std::vector<Client*>::iterator pos = std::find(takenClients.begin(), takenClients.end(), cl);
		if(pos != takenClients.end()){
			takenClients.erase(pos);
		}

		error += "\nClient \"" + cl->getHostName() + "\" has been released.";
	}

	return true;
}

bool CommandListener::cmd_start(std::vector<std::string> params, std::vector<Client*> clist, std::string& error){
	if(params.size() < 3){
		error += "\nPlease supply more arguments.\nUsage: takeover [ip address | mac address | hostname]";
		return false;
	}

	bool wake = false;
	int pxeNo = Utils::toInt(params[2]);

	if(params.size() == 3){
		wake = false;
	}
	else{
		if(params[3] == "wake")
			wake = true;
	}

	BOOST_FOREACH(Client* cl, clist) {

		if(!cl->remote_isOwner(this)){
			error += "\nClient \"" + cl->getHostName() + "\" has not been taken.";
			return false;
		}

		if(!cl->remote_start(pxeNo, wake)){
			error += "\nClient \"" + cl->getHostName() + "\" could not be set up. PXE menu does not exist.";
			return false;
		}

		error += "\nClient \"" + cl->getHostName() + "\" has been set up successfully.";
	}

	return true;
}

bool CommandListener::cmd_shutdown(std::vector<std::string> params, std::vector<Client*> clist, std::string& error){
	if(params.size() < 2){
		error += "\nPlease supply more arguments.\nUsage: takeover [ip address | mac address | hostname]";
		return false;
	}

	BOOST_FOREACH(Client* cl, clist) {

		if(!cl->remote_isOwner(this)){
			error += "\nClient \"" + cl->getHostName() + "\" has not been taken.";
		}

		cl->remote_shutdown();
	}
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

// parses comma separated list of clients
void CommandListener::getClientList(std::string clist, std::vector<Client*>& result, std::string& error) {
	std::vector<std::string> split;
	Client* temp = NULL;
	Utils::stringSplit(clist,",",split);
	if(split.size()== 0) return;
	for(int i=0; i<split.size(); i++) {
		temp = getClient(split[i]);
		if(temp != NULL) {
			result.push_back(temp);
		}
		else {
			error += "Client \"" + split[i] + "\" not found.";
		}
		temp = NULL;
	}
}

void CommandListener::setClientList(std::map<std::string, Client*>* clist) {
	clientList = clist;
}

void CommandListener::setClientListMutex(pthread_mutex_t* clist_mutex) {
	clientListMutex = clist_mutex;
}
