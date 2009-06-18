/*
 * Client.cpp
 *
 *  Created on: 23.04.2009
 *      Author: bastian
 */

#include "Client.h"
#include "ClientStates.h"
#include "Utility.h"
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

    cout << "Client with name \"" << al["HostName"] <<"\" created!" << endl;
    cout << "IPAddress: " << al["IPAddress"] << endl;

    IPAddress ip = Utility::ipFromString(al["IPAddress"]);

}

/**
 * Client default destructor
 */
Client::~Client() {
    terminate(); // Statemachine

    cout << "Client \""<< attributes["HostName"] << "\" destroyed!" << endl << endl;
}

void Client::updateFromLdap(AttributeMap attr, std::vector<PXESlot> slots) {

}
