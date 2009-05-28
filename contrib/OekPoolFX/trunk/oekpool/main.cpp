
#include "main.h"
#include <iostream>
#include <string>

#include "Client.h"

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

    Client client;

    client.process_event(EvtHostlistInsert() );

    client.process_event(EvtWakeCommand() );

    return true;
}
