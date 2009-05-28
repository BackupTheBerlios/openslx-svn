/*
 * Client.cpp
 *
 *  Created on: 23.04.2009
 *      Author: bastian
 */

#include "Client.h"
#include "ClientStates.h"
#include <iostream>

using namespace std;

/**
 * Client default constructor
 */
Client::Client() {
    initiate();
    cout << "Client object created!" << endl << endl;

}

/**
 * Client default destructor
 */
Client::~Client() {
    terminate();
    cout << "Client object destroyed!" << endl << endl;
}
