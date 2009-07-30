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
	static pthread_mutex_t timeoutmutex;
	static pthread_t thread;
	static pthread_t timeoutthread;

	static std::vector<Client*> sshClients;
	static std::map<Client*,SSHInfo > sshInfos;
	static std::pair<Client*, time_t > sshTimeout;
	static std::map<Client*,std::vector<sshStruct> > sshCmds;

	static bool started;

	static void _connect(std::string, SSHInfo*);
	static void _connect(IPAddress, SSHInfo*);

	// expects a running ssh session !!
	static void _runCmd(SSHInfo*,std::string);

	static void _disconnect(SSHInfo*);

	static void* _main(void*);
	static void* _main_timer(void*);

	static void _set_timeout(Client*, time_t = 0);
	static void _reset_timeout();
	static void _quit_thread(int);

	SshThread();
	virtual ~SshThread();

public:
	static SshThread* getInstance();
	void update();


	void addClient(Client* );
	void delClient(Client* );

};

#endif /* SSH_H_ */
