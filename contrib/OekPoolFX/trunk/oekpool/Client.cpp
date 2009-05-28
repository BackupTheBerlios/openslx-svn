/*
 * Client.cpp
 *
 *  Created on: 23.04.2009
 *      Author: bastian
 */

#include "Client.h"
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

/**
 * "Offline"-state enter function
 */
Offline::Offline() {
    //cout << "Entered Offline state!" << endl;
}

/**
 * "PXEConfig"-state enter function
 */
PXEConfig::PXEConfig() {
    //cout << "Entered PXEConfig state!" << endl;
}

/**
 * "Wake"-state enter function
 */
Wake::Wake() {
    //cout << "Entered Wake state!" << endl;
}
