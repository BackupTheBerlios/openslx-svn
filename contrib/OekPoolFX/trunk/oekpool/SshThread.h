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

	static std::vector<Client*> sshClients;
	static std::map<Client*,SSHInfo > sshInfos;
	//static std::map<Client*,std::vector<std::string,bool> >
	//sshCmds;

	pthread_t sshWorkerThread;

	void _connect(std::string, SSHInfo*);
	void _connect(IPAddress, SSHInfo*);

	// expects a running ssh session !!
	void _runCmd(SSHInfo*,std::string);

	void _disconnect(SSHInfo*);

	void* _main();

	void* threadUpdateClients(void*);


	SshThread();
	virtual ~SshThread();

public:
	static SshThread* getInstance();


	void addClient(Client* );
	void delClient(Client* );

};

#endif /* SSH_H_ */
