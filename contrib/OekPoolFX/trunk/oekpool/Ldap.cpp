/*
 * Ldap.cpp
 *
 *  Created on: 23.04.2009
 *      Author: julian
 */

#include "Ldap.h"
#include <string>
#include <vector>
#include <ldap.h>
#include <stdlib.h>
#include <iostream>

// from ldapc++
#include "LDAPConnection.h"
#include "LDAPConstraints.h"
#include "LDAPSearchReference.h"
#include "LDAPSearchResults.h"
#include "LDAPAttribute.h"
#include "LDAPAttributeList.h"
#include "LDAPEntry.h"
#include "LDAPException.h"
#include "LDAPModification.h"

using namespace std;

Ldap::Ldap(char* host, int port, char* who, char* cred) {

    cons=new LDAPConstraints;
    ctrls=new LDAPControlSet;
    ctrls->add(LDAPCtrl(LDAP_CONTROL_MANAGEDSAIT));
    cons->setServerControls(ctrls);

    lc=new LDAPConnection(host, port );
    lc->setConstraints(cons);

    try {
        lc->bind(who ,cred,cons);
    }
    catch(LDAPException e) {
        cerr << e.getResultMsg() << endl;
    }

    this->host = strdup(host);
    this->port = port;
    this->who = strdup(who);
    this->cred = strdup(cred);

}

Ldap::~Ldap() {

    free(this->host);
    free(this->who);
    free(this->cred);
}

vector<string> Ldap::search(string base, int scope, string filter) {


    return vector<string>();
}
