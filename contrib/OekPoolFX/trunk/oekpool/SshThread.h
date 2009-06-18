/*
 * Ssh.h
 *
 *  Created on: 23.04.2009
 *      Author: julian
 */
#ifndef SSH_H_
#define SSH_H_

#include <string>
#include <vector>

#include "types.h"
#include "Client.h"
#include "pthread.h"

class SshThread {

private:
	static pthread_mutex_t clientmutex;
	static std::vector<Client*> sshClients;

	void _connect(std::string hostname);
	void _connect(IPAddress ip);

	SshThread();
	virtual ~SshThread();

public:
	static SshThread* getInstance();


	static void addClient(Client* );
	static void delClient(Client* );
};

pthread_mutex_t SshThread::clientmutex;
std::vector<Client*> SshThread::sshClients;

#endif /* SSH_H_ */
