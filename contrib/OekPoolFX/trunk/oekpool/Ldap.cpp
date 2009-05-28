/*
 * Ldap.cpp
 *
 *  Created on: 23.04.2009
 *      Author: julian
 */

#include "Ldap.h"
#include "Client.h"
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

vector<AttributeMap> Ldap::search(string base, int scope, string filter, const StringList& attribs) {

    if(bound == false) {
        return vector<AttributeMap>();
    }

    LDAPSearchResults* lr = lc->search(base, scope, filter,attribs, true);

    LDAPEntry* le;
    const LDAPAttribute* la;
    StringList s;
    vector<AttributeMap> result;

    while( (le = lr->getNext()) ) {

    	for(StringList::const_iterator
    			it =attribs.begin();
				it!=attribs.end();
				it++)
    	{
    		la = le->getAttributeByName(*it);
    		if(la == NULL) continue;
			s = la->getValues();
			AttributeMap temp;
			for(StringList::const_iterator
					st = s.begin();
					st != s.end();
					st ++)
			{
				// TODO: Check for values with more than one item
				temp[*it] = *st;
			}
			result.push_back(temp);
    	}

    }

    return result;
}


vector<string> Ldap::getPools() {
	vector<string> result;

	StringList attribs;
    attribs.add("ou");

    vector<AttributeMap> ous = search(string("ou=Rechenzentrum,ou=UniFreiburg,")
                .append("ou=RIPM,dc=uni-freiburg,dc=de"),
                LDAP_SCOPE_SUBTREE,
                string("(&(!(ou=Rechenzentrum))(ou=*))"),
                attribs
               );

    for(vector<AttributeMap>::iterator
    		it= ous.begin();
			it!=ous.end();
			it++)
    {
    	if(! (*it)["ou"].empty())
    	{
    		result.push_back( (*it)["ou"] );
    	}
    }

    return result;
}


Client** Ldap::getClients(string pool) {

	string base;
	string filter="(HostName=*)";

	const char* attrs[] = { "HostName", "HWaddress", "IPAdress", 0 };
	StringList attribs((char**)attrs);
	vector<AttributeMap> vec;


	if (pool.empty()) {
		base = "ou=Rechenzentrum,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de";
	}
	else {
		base = "ou="+ pool + ",ou=Rechenzentrum,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de";
	}

	vec = search(base, LDAP_SCOPE_SUBTREE, filter, attribs);

	Client** result = new Client*[vec.size()+1];

	for(std::size_t i=0;i< vec.size();i++ )
	{
		if(!vec[i]["HostName"].empty()) {
			result[i] = new Client(vec[i]);
		}
	}
	result[vec.size()] = '\0';

	return result;
}
