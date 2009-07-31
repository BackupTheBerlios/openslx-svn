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

#include "Client.h"
#include "pthread.h"

/**
 * SshThread: class to handle ssh connections and commands
 *
 * This class starts 2 threads:
 *  1.) ssh worker thread: connects and runs commands
 *    main function: _main()
 *  2.) timeout watch thread: watch for timeouts set by worker thread
 *    main function: _main_timer()
 *    if a timeout occurred,
 *    	- the client gets deleted (via delClient(client,true))
 *      - the commands of this client are delete
 *      	*** ATTENTION: watch for too short ssh_interval times here,
 *      	***			   but this should not be a problem ;-)
 *      - the timeout is reset (via _reset_timeout() )
 *      - signal SIGHUP is send to worker thread (and _quit_thread() is called)
 *
 *  central data structures are protected by mutexes:
 *   sshClients, sshInfos, sshCmds by clientmutex
 *   sshTimeout by timeoutmutex
 *   client->ssh_responding by client->sshMutex
 */
class SshThread {

private:
	// protects all client data stored in this class
	static pthread_mutex_t clientmutex;
	// protects sshTimeout (for watch thread)
	static pthread_mutex_t timeoutmutex;

	// worker thread
	static pthread_t thread;
	// watch thread
	static pthread_t timeoutthread;

	// vector containing all clients
	static std::vector<Client*> sshClients;
	// map containing connection information and sockets
	static std::map<Client*,SSHInfo > sshInfos;
	// static pair for timeout detection (see timeoutmutex)
	static std::pair<Client*, time_t > sshTimeout;
	// all commands for each clients, updated regularly from client->getCmdTable()
	static std::map<Client*,std::vector<sshStruct> > sshCmds;

	// bool, if thread has already started
	static bool started;

	// connect via ssh (using libssh2)
	static void _connect(std::string, SSHInfo*);
	static void _connect(IPAddress, SSHInfo*);
	// expects a running ssh session, but creates new channel each time
	static void _runCmd(SSHInfo*,std::string);

	static void _disconnect(SSHInfo*);

	// thread 1: worker thread
	static void* _main(void*);
	// thread 2: watcher thread
	static void* _main_timer(void*);

	// set timeout (protected by mutex)
	// time_t is the time difference here
	static void _set_timeout(Client*, time_t = 0);
	// reset timer to 0 and client to NULL
	static void _reset_timeout();
	// quit thread and reset timer
	static void _quit_thread(int);

	SshThread();
	virtual ~SshThread();

public:
	// Singleton
	static SshThread* getInstance();

	// update() checks, whether we have to restart
	// worker thread (only allowed in main thread)
	void update();

	// adds a client to the private data (protected by clientmutex)
	void addClient(Client* );
	// deletes a client from the private data (protected by clientmutex)
	// if a timeout occurred, do not try to disconnect (would cause another timeout)
	void delClient(Client* ,bool timeout = false);

};

#endif /* SSH_H_ */
