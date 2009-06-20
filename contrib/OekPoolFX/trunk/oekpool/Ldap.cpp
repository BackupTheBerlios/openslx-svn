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
#include "Configuration.h"

#include <string>
#include <vector>
#include <ldap.h>
#include <stdlib.h>
#include <iostream>

#include <boost/foreach.hpp>

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

Ldap::Ldap() {
	Configuration* conf = Configuration::getInstance();

	string host = conf->getString("ldap_server");
	int port = conf->getInt("ldap_port");
	string who = conf->getString("ldap_user");
	string cred = conf->getString("ldap_password");

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

Ldap* Ldap::getInstance() {
    static Ldap instance;
    return &instance;
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
 * ATTENTION: Free client objects...
 */
void Ldap::getClients(string pool, map<string,Client*>& clist) {

	string base;
	string filter="(HostName=*)";
	string filterpxe="(objectClass=ActivePXEConfig)";

	const char* attrs[] = { "HostName", "HWaddress", "IPAddress",
	        "description", 0 };
	const char* attrspxe[] = { "cn","ForceBoot","TimeSlot",0};

	StringList attribs((char**)attrs);
	StringList attribspxe((char**)attrspxe);

	vector<AttributeMap> vec;
	vector<AttributeMap> vecpxe;
	vector<PXESlot> vecslots;
	PXESlot pxeslot;


	if (pool.empty()) {
		base = "cn=computers,ou=Rechenzentrum,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de";
	}
	else {
		base = "cn=computers,ou="+ pool + ",ou=Rechenzentrum,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de";
	}

	vec = search(base, LDAP_SCOPE_ONELEVEL, filter, attribs);

	for(std::size_t i=0;i< vec.size();i++ )
	{
		if(!vec[i]["HostName"].empty() && !vec[i]["IPAddress"].empty())
		{
			pair<string, string> p = Utility::splitIPRange(vec[i]["IPAddress"]);
			vec[i]["IPAddress"] = p.first;



			// Get PXE Timeslot Information
			string basepxe = string("HostName=")+vec[i]["HostName"]+","+base;
			vecpxe = search(basepxe,LDAP_SCOPE_ONELEVEL, filterpxe, attribspxe);

			BOOST_FOREACH(AttributeMap am, vecpxe) {
				pxeslot.ForceBoot = (am["ForceBoot"]=="TRUE"?true:false);
				pxeslot.TimeSlot = am["TimeSlot"];
				pxeslot.cn = am["cn"];

				vecslots.push_back(pxeslot);
			}

			// if client object not already exists - create it
			// otherwise call method "updateFromLdap";
			if(clist.find(vec[i]["HWaddress"]) == clist.end()) {
				clist[vec[i]["HWaddress"]] = new Client(vec[i], vecslots);
			}
			else {
				clist[vec[i]["HWaddress"]]->updateFromLdap(vec[i], vecslots);
			}
		}
	}

	return;
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

	vec = search(base, LDAP_SCOPE_ONELEVEL, filter,attribs);

	for(uint i=0;i < vec.size();i++)
	{
		temp.subnetMask = Utility::ipFromString(vec[i]["dhcpoptNetmask"]);
		temp.broadcastAddress = Utility::ipFromString(vec[i]["dhcpoptBroadcast-address"]);
		temp.networkAddress = Utility::ipFromString(vec[i]["cn"]);

		result.push_back(temp);
	}

	return result;
}
