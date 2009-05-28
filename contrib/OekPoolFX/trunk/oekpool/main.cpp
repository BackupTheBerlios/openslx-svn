
#include "main.h"
#include <iostream>
#include <string>
#include <vector>

#include "Client.h"
#include "Ldap.h"
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

    Ldap& obj = Ldap::getInstance("132.230.4.xx",389,
                        "user", "pass");

    obj.getClients("LSfKS");

    return 0;
}
