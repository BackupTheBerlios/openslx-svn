
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

#include <sys/time.h>


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

// this is the client list
map<string, Client*> clientList;
// this is the vector containing pools
vector<string> vecPools;

int main(int argc, char** argv) {

	signal(SIGTERM, setExitFlag);

	// call the various singleton to initialize
    Configuration* conf = Configuration::getInstance();
    Network* network = Network::getInstance();
    Ldap* ldap = Ldap::getInstance();

    network->setNetworks(ldap->getNetworks());

    Logger* logger = LoggerFactory::getInstance()->getGlobalLogger();

    logger->log(
    		LOG_LEVEL_INFO,
    		Utility::toString(clientList.size())+
				" client objects created ",
			NULL
    );

    SshThread* ssh = SshThread::getInstance();
    SSHInfo sshinfo;


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
			clog << "Aktualisiere LDAP-Info\n";
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

		/** logger->log(LOG_LEVEL_INFO,"Warte "+Utility::toString(wait.tv_sec)+
		 *		" sec und "+Utility::toString(wait.tv_nsec)+" nsec",NULL);
		 */

		nanosleep(&wait, NULL);
    }

    return 0;
}

void setExitFlag(int i) {
	exitFlag = true;
}
