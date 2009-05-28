
#include "main.h"
#include <iostream>
#include <string>
#include <vector>

#include "Client.h"
#include "Ldap.h"
#include "Configuration.h"
#include "events.h"

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

    Configuration& conf = Configuration::getInstance();

    Ldap& obj = Ldap::getInstance(
                  conf.getString("ldap_server"),
                  conf.getInt("ldap_port"),
                  conf.getString("ldap_user"),
                  conf.getString("ldap_password"));

    obj.getClients("");


    return 0;
}
