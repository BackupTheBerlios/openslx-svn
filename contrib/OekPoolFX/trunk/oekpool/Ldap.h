/*
 * Ldap.h
 *
 *  Created on: 23.04.2009
 *      Author: julian
 */

#ifndef LDAP_H_
#define LDAP_H_

#include "Client.h"
#include "types.h"
#include "Network.h"

#include <ldap.h>
#include <string>
#include <vector>
#include <map>

#include <time.h>

#include "LDAPConnection.h"
#include "LDAPConstraints.h"


/**
 * LDAP: handles connection to ldap and contains
 *  general functions to search for
 *  and get Clients/PXEInfos
 */
class Ldap {

    /**
     * LDAP specific variables
     */
    LDAPConstraints* cons;
    LDAPControlSet* ctrls;
    LDAPConnection *lc;

    /**
     * ldap server host
     */
    std::string host;

    /**
     * server port
     */
    int port;

    /**
     * username
     */
    std::string who;

    /**
     * password
     */
    std::string cred;

    /**
     * Is connection established?
     */
    bool bound;

    /**
     * default constructor for the Ldap class
     */
    Ldap();
public:
    /**
     * Singleton wrapper for this class
     */
    static Ldap* getInstance();

    /**
     * Ldap destructor
     */
	virtual ~Ldap();

	/**
	 * Search LDAP for some objects
	 * @param base string to give the base
	 * @param scope int to give the scope of the search
	 * @param filter string which filters objects
	 */
	std::vector<AttributeMap> search(std::string base,int,std::string filter, const StringList& attribs);

	/**
	 * Get pool names out of LDAP server
	 * @returns List of pools (vector of strings)
	 */
	std::vector<std::string> getPools();

	/**
	 * Get client data from LDAP and create them (null-terminated array)
	 * @param pool - Pool to get Clients from
	 * @param clist - reference to clients-pointer-map (ordered by HWadress)
	 */
	void getClients(std::string , std::map<string,Client*>&);

	/**
	 * Get network information (broadcast address,subnet mask and network address)
	 */
	std::vector<networkInfo> getNetworks();
};

#endif /* LDAP_H_ */
