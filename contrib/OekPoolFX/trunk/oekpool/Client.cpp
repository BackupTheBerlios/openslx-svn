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
Client::Client(AttributeMap al) {
    initiate();

    _attributes = al;

    cout << "Client object with name " << al["HostName"] <<" created!" << endl;
    cout << "IPAddress: " << al["IPAddress"] << endl;

    IPAddress ip = Utility::ipFromString(al["IPAddress"]);
    cout << "IPAddress converted: " << ip << endl;

}

/**
 * Client default destructor
 */
Client::~Client() {
    terminate();
    cout << "Client object destroyed!" << endl << endl;
}
