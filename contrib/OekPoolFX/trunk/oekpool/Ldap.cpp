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

Ldap::Ldap(string host, int port,string who,string cred) {

    cons=new LDAPConstraints;
    ctrls=new LDAPControlSet;
    ctrls->add(LDAPCtrl(LDAP_CONTROL_MANAGEDSAIT));
    cons->setServerControls(ctrls);

    lc=new LDAPConnection(host, port );
    lc->setConstraints(cons);

    try {
        lc->bind(who ,cred,cons);
        bound = true;
    }
    catch(LDAPException e) {
        cerr << "LDAPException in bind(): " << e.getResultMsg() << endl;
        bound = false;
    }

    this->host = host;
    this->port = port;
    this->who = who;
    this->cred = cred;

}

Ldap::~Ldap() {

    lc->unbind();

}

Ldap& Ldap::getInstance(string host, int port,string who,string cred) {
    static Ldap instance(host, port,who,cred);
    return instance;
}

vector<string> Ldap::search(string base, int scope, string filter) {

    if(bound == false) {
        return vector<string>();
    }

    LDAPSearchResults* lr = lc->search(base, scope, filter);

    LDAPEntry* le;
    const LDAPAttributeList* la;
    StringList s;

    do {
        le = lr->getNext();
        la = le->getAttributes();
        for(LDAPAttributeList::const_iterator
                it = la->begin();
                it != la->end();
                it++) {
            s = it->getValues();
            cout << "Attribut " << it->getName() << ": ";
            for(StringList::const_iterator
                    st = s.begin();
                    st != s.end();
                    st ++)
            {
                cout << *st << ", ";
            }
            cout << endl;
        }
    }
    while ( (le = lr->getNext()) );

    return vector<string>();
}
