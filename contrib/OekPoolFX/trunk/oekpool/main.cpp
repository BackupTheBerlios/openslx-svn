
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

#include <boost/foreach.hpp>

#include <StdLog.h>

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

    Ldap* ldap = Ldap::getInstance();

    Network::getInstance()->setNetworks(ldap->getNetworks());

    vecPools = ldap->getPools();

    BOOST_FOREACH(string pool, vecPools) {
    	ldap->getClients(pool,clientList);
    }

    (new StdLogger())->log(
    		LOG_LEVEL_INFO,
    		Utility::toString(clientList.size())+
				" client objects created ",
			NULL
    );

    SshThread* ssh = SshThread::getInstance();
    SSHInfo sshinfo;

    int i = 0;
	while(exitFlag == false) {
		sleep(1);
		cout << "Seconds: " << ++i;
    }

    return 0;
}

void setExitFlag(int i) {
	exitFlag = true;
}
