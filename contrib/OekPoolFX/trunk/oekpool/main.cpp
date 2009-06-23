
//#include "main.h"
#include <iostream>
#include <string>
#include <vector>
#include <map>

#include "Client.h"
#include "Ldap.h"
#include "Configuration.h"
#include "SshThread.h"
#include "events.h"
#include "Utility.h"
#include "Logger.h"
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
int main(int argc, char** argv) {

	typedef pair<string,Client*> clientPair;
//    Client client;
//
//    client.process_event(EvtHostlistInsert() );
//
//    client.process_event(EvtWakeCommand() );

	// call the various singleton to initialize
    Configuration* conf = Configuration::getInstance();

    Ldap* ldap = Ldap::getInstance();

    Network::getInstance()->setNetworks(ldap->getNetworks());

    vector<string> vecpools = ldap->getPools();

    // this is the client list
    map<string, Client*> clist;

    BOOST_FOREACH(string pool, vecpools) {
    	ldap->getClients(pool,clist);
    }

    Logger::getInstance()->log(
    		Utility::toString(clist.size())+
    		" client objects created ",
    		LOG_LEVEL_INFO
    );

    SshThread* ssh = SshThread::getInstance();
    SSHInfo sshinfo;

//    ssh->_connect("132.230.4.13",&sshinfo);
//
//    ssh->_runCmd(&sshinfo, "ls /tmp");
//
//    ssh->_disconnect(&sshinfo);
	BOOST_FOREACH(clientPair p, clist) {
//		cout << p.second->getIP() << p.second->getHostName() <<
//			((p.second->isActive()==true)?"true":"false") << endl;
	}

    while(sleep(60)) {


    }

    return 0;
}
