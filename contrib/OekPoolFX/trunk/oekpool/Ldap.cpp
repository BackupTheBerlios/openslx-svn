/*
 * Ldap.cpp
 *
 *  Created on: 23.04.2009
 *      Author: julian
 */

#include "Ldap.h"
#include "Client.h"
#include "Network.h"
#include "Utility.h"

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

    LDAPSearchResults* lr = lc->search(base, scope, filter,attribs, false);

    LDAPEntry* le;
    const LDAPAttribute* la;
    StringList s;
    vector<AttributeMap> result;
	AttributeMap temp;

    while( (le = lr->getNext()) ) {

    	for(StringList::const_iterator
    			it =attribs.begin();
				it!=attribs.end();
				it++)
    	{
    	    //cout << endl << "Name: " << *it << " |";
    		la = le->getAttributeByName(*it);
    		if(la == NULL) continue;
			s = la->getValues();
			for(StringList::const_iterator
					st = s.begin();
					st != s.end();
					st ++)
			{
			    //cout << "Value: " << *st;
				temp[*it] = *st;
			}
    	}
    	//cout << endl;

    	if(temp.size() > 0) {
			result.push_back(temp);
	    	temp.clear();
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


/**
 * ATTENTION: Free return memory (pointers and data)
 */
Client** Ldap::getClients(string pool) {

	string base;
	string filter="(HostName=*)";

	const char* attrs[] = { "HostName", "HWaddress", "IPAddress",
	        "description", "DomainName", "dhcpHlpCont", 0 };
	StringList attribs((char**)attrs);
	vector<AttributeMap> vec;


	if (pool.empty()) {
		base = "cn=computers,ou=Rechenzentrum,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de";
	}
	else {
		base = "ou="+ pool + ",ou=Rechenzentrum,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de";
	}

	vec = search(base, LDAP_SCOPE_SUBTREE, filter, attribs);

	Client** result = new Client*[vec.size()+1];

	for(std::size_t i=0;i< vec.size();i++ )
	{
		if(!vec[i]["HostName"].empty() && !vec[i]["IPAddress"].empty())
		{
			if(!vec[i]["IPAddress"].empty()) {
				string::size_type cutAt;
				cout << "IPAddress before cut: " << vec[i]["IPAddress"] << endl;
				if((cutAt = vec[i]["IPAddress"].find_first_of('_')) != string::npos) {
					vec[i]["IPAddress"] = vec[i]["IPAddress"].substr(0,cutAt);
					cout << "IPAddress after cut: " << vec[i]["IPAddress"] << endl;
				}
			}
			result[i] = new Client(vec[i]);
		}
	}
	result[vec.size()] = '\0';

	return result;
}


vector<networkInfo> Ldap::getNetworks()
{
	string base = "cn=dhcp,ou=Rechenzentrum,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de";
	string filter="(dhcpoptNetmask=*)";

	const char* attrs[] = { "cn", "dhcpoptNetmask", "dhcpoptBroadcast-address", 0 };
	StringList attribs((char**)attrs);
	vector<AttributeMap> vec;
	vector<networkInfo> result;
	networkInfo temp;

	vec = search(base, LDAP_SCOPE_SUBTREE, filter,attribs);

	for(uint i=0;i < vec.size();i++)
	{
		temp.subnetMask = Utility::ipFromString(vec[i]["dhcpoptNetmask"]);
		temp.broadcastAddress = Utility::ipFromString(vec[i]["dhcpoptBroadcast-address"]);
		temp.networkAddress = Utility::ipFromString(vec[i]["cn"]);

		result.push_back(temp);
	}

	return result;
}
