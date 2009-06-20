/*
 * Client.cpp
 *
 *  Created on: 23.04.2009
 *      Author: bastian
 */

#include "Client.h"
#include "ClientStates.h"
#include "Utility.h"
#include "Logger.h"
#include <iostream>

using namespace std;

/**
 * Client default constructor
 */
Client::Client(AttributeMap al, std::vector<PXESlot> slots)
{
	exists_in_ldap = true;

    initiate(); // Statemachine

    attributes = al;
    pxeslots = slots;

    Logger* log = Logger::getInstance();

    log->log("Client with name \"" + al["HostName"]+"\" created!",LOG_LEVEL_INFO);

    IPAddress ip = Utility::ipFromString(al["IPAddress"]);

}

/**
 * Client default destructor
 */
Client::~Client() {
    terminate(); // Statemachine
}

void Client::updateFromLdap(AttributeMap attr, std::vector<PXESlot> slots) {

}
