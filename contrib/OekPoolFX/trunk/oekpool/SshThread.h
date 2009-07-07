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
#include <map>

#include "types.h"
#include "Client.h"
#include "pthread.h"

class SshThread {

private:
	static pthread_mutex_t clientmutex;
	static pthread_t thread;

	static std::vector<Client*> sshClients;
	static std::map<Client*,SSHInfo > sshInfos;
	//static std::map<Client*,std::vector<std::string,bool> >
	//sshCmds;

	pthread_t sshWorkerThread;

	static void _connect(std::string, SSHInfo*);
	static void _connect(IPAddress, SSHInfo*);

	// expects a running ssh session !!
	static void _runCmd(SSHInfo*,std::string);

	static void _disconnect(SSHInfo*);

	static void* _main(void*);

	SshThread();
	virtual ~SshThread();

public:
	static SshThread* getInstance();


	void addClient(Client* );
	void delClient(Client* );

};

#endif /* SSH_H_ */
