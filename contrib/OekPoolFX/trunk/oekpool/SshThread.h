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

	pthread_t sshWorkerThread;
public:
	void _connect(std::string, SSHInfo*);
	void _connect(IPAddress, SSHInfo*);

	// expects a running ssh session !!
	void _runCmd(SSHInfo*,std::string);

	void* threadUpdateClients(void*);

	void _disconnect(SSHInfo*);
private:
	SshThread();
	virtual ~SshThread();

public:
	static SshThread* getInstance();


	static void addClient(Client* );
	static void delClient(Client* );
};

#endif /* SSH_H_ */
