
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
#include <time.h>

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

	typedef pair<string,Client*> clientPair;

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
    clock_t timeStamp;
    clock_t wait;

	while(!exitFlag) {
		timeStamp = clock();


		if(i == 0) {
			clog << "Aktualisiere LDAP-Info\n";
			vecPools = ldap->getPools();

			BOOST_FOREACH(string pool, vecPools) {
				ldap->getClients(pool,clientList);
			}
		}

		typedef pair< string, Client* > mpair;
		BOOST_FOREACH(mpair p, clientList) {
			p.second->processClient();
		}

	    i = (i + 1) % 6;
		wait = 5000000L -  ((1000000L*(clock() - timeStamp)) / CLOCKS_PER_SEC);
		clog << "Warte " << wait << " usec" << endl;

		// TODO use nanosleep to work with interrupts
		usleep(wait);
    }

    return 0;
}

void setExitFlag(int i) {
	exitFlag = true;
}
