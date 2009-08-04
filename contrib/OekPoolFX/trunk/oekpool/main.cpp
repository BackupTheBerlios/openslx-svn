
//#include "main.h"
#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <signal.h>

#include "Client.h"
#include "Ldap.h"
#include "Configuration.h"
#include "SshThread.h"
#include "events.h"
#include "Utility.h"
#include "StdLogger.h"
#include "types.h"
#include "LoggerFactory.h"

#include "CommandListener.h"
#include <ListenSocket.h>
#include <SocketHandler.h>

#include <sys/time.h>
#include <pthread.h>


#include <boost/foreach.hpp>

using namespace std;

/**
 * This program is the administrative program for ordinary computer pools
 * which are organized through a LDAP-structure and a PHP-application
 *
 * Features include:
 *  - Wake On Lan
 *  - Ping
 *  - Execute arbitrary SSH commands
 *  - etc. pp.
 */

// global variables

bool exitFlag = false;
void setExitFlag(int);
void* _main_socket(void*);

// this is the client list
map<string, Client*> clientList;
pthread_mutex_t clientListMutex;

// this is the vector containing pools
vector<string> vecPools;

// this is the socket callback thread (_main_socket)
pthread_t socketThread;

int main(int argc, char** argv) {

	signal(SIGTERM, setExitFlag);

	pthread_mutex_init(&clientListMutex, NULL);

	// call the various singleton to initialize
    Configuration* conf = Configuration::getInstance();
    Network* network = Network::getInstance();
    Ldap* ldap = Ldap::getInstance();

    network->setNetworks(ldap->getNetworks());

    Logger* logger = LoggerFactory::getInstance()->getGlobalLogger();

    logger->log(
    		LOG_LEVEL_INFO,
    		Utils::toString(clientList.size())+
				" client objects created ",
			NULL
    );

    SshThread* ssh = SshThread::getInstance();
    SSHInfo sshinfo;

    CommandListener::setClientList(&clientList);
    CommandListener::setClientListMutex(&clientListMutex);
    SocketHandler h;
    ListenSocket<CommandListener> cmdlisten(h);
    if(cmdlisten.Bind(4440)) {
    	logger->log(LOG_LEVEL_FATAL,
				"Port 4440 blocked!",
				NULL);
    	exit(-1);
    }
    h.Add(&cmdlisten);

    pthread_create(&socketThread,NULL,_main_socket,(void*)&h);

    int i = 0;
    timespec timeStamp, timeStamp2;
    timeval timev;
    timespec wait;
    time_t diff = 0;
    //clock_t wait;

	while(!exitFlag) {
		// Get nanosecond time
		gettimeofday(&timev, NULL);
		TIMEVAL_TO_TIMESPEC(&timev, &timeStamp);

		if(i == 0) {
			logger->log(LOG_LEVEL_INFO, "Aktualisiere LDAP-Info",NULL);
			vecPools = ldap->getPools();

			BOOST_FOREACH(string pool, vecPools) {
				ldap->getClients(pool,clientList);
			}
		}

		BOOST_FOREACH(clientPair p, clientList) {
			p.second->processClient();
		}

		// check if the worker thread needs to be restarted
		SshThread::getInstance()->update();

	    i = (i + 1) % 6;

	    gettimeofday(&timev, NULL);
		TIMEVAL_TO_TIMESPEC(&timev, &timeStamp2);
		diff = (timeStamp2.tv_nsec - timeStamp.tv_nsec);
		if(diff < 0) diff = 1e9 + diff;
		wait.tv_sec = 5L -  ((timeStamp2.tv_sec - timeStamp.tv_sec)+diff/1e9);
		wait.tv_nsec =  1e9 - diff;

		/** logger->log(LOG_LEVEL_INFO,"Warte "+Utils::toString(wait.tv_sec)+
		 *		" sec und "+Utils::toString(wait.tv_nsec)+" nsec",NULL);
		 */

		nanosleep(&wait, NULL);
    }

    return 0;
}

void setExitFlag(int i) {
	exitFlag = true;
}


void* _main_socket(void* p) {
	SocketHandler* h = (SocketHandler*) p;

	while(!exitFlag) {
		h->Select(1,0);
	}
}
