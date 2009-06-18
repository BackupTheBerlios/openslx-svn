
//#include "main.h"
#include <iostream>
#include <string>
#include <vector>

#include "Client.h"
#include "Ldap.h"
#include "Configuration.h"
#include "events.h"

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
int main(int argc, char** argv) {

//    Client client;
//
//    client.process_event(EvtHostlistInsert() );
//
//    client.process_event(EvtWakeCommand() );

	// call the various singleton to initialize
    Configuration* conf = Configuration::getInstance();

    Ldap* obj = Ldap::getInstance();

    Network::getInstance()->setNetworks(obj->getNetworks());

    vector<string> bla = obj->getPools();

    BOOST_FOREACH(string pool, bla) {
    	cout << pool << endl;
    }



    return 0;
}
