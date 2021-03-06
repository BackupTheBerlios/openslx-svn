/*
 * CommandListener.h
 *
 *  Created on: 02.07.2009
 *      Author: jb78
 */

#ifndef COMMANDLISTENER_H_
#define COMMANDLISTENER_H_

#include "TcpSocket.h"
#include "types.h"
#include "pthread.h"

// forward decl
class SocketLogger;

class CommandListener : public TcpSocket {
public:
	CommandListener(ISocketHandler&);
	virtual ~CommandListener();

	void OnAccept(void);
	void OnLine(const std::string&);


	void SendPrompt();


	// call these before use (in main)
	static void setClientList(std::map<std::string, Client*>*);
	static void setClientListMutex(pthread_mutex_t*);

private:

	bool cmd_query	 (std::vector<std::string>, std::vector<Client*>, std::string&);
	bool cmd_list	 (std::vector<std::string>, std::vector<Client*>, std::string&);
	bool cmd_takeover(std::vector<std::string>, std::vector<Client*>, std::string&);
	bool cmd_release (std::vector<std::string>, std::vector<Client*>, std::string&);
	bool cmd_start	 (std::vector<std::string>, std::vector<Client*>, std::string&);
	bool cmd_shutdown(std::vector<std::string>, std::vector<Client*>, std::string&);
	bool cmd_execute (std::string, std::vector<Client*>, std::string&);

	Client* getClient(std::string);
	void getClientList(std::string clist, std::vector<Client*>& result, std::string&);

	static std::map<std::string, Client*>* clientList;
	static pthread_mutex_t* clientListMutex;

	std::vector<Client*> takenClients;

	SocketLogger* logger;
};

#endif /* COMMANDLISTENER_H_ */
