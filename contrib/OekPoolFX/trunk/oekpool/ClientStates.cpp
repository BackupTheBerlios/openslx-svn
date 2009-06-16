/*
 * ClientStates.cpp
 *
 *  Created on: 24.04.2009
 *      Author: bastian
 */

#include "ClientStates.h"

/**
 * "Offline"-state enter function
 */
ClientStates::Offline::Offline() {
    //cout << "Entered Offline state!" << endl;
}

/**
 * "PXEConfig"-state enter function
 */
ClientStates::PXE::PXE() {
    //cout << "Entered PXEConfig state!" << endl;
}

/**
 * "Wake"-state enter function
 */
ClientStates::Wake::Wake() {
    //cout << "Entered Wake state!" << endl;
}
