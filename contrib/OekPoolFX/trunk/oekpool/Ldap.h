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

#include "LDAPConnection.h"
#include "LDAPConstraints.h"



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
     * @param host host to connect to
     * @param port connection port
     * @param who username
     * @param cred credentials - password
     */
    Ldap(std::string host,int port,std::string who,std::string cred);
public:
    /**
     * Singleton wrapper for this class
     */
    static Ldap& getInstance(std::string host,int port,std::string who,std::string cred);

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
	 * @param pool Pool to get Clients from
	 * @returns Clients from "pool", if empty -> return global Clients
	 */
	Client** getClients(std::string pool);

	/**
	 * Get network information (broadcast address,subnet mask and network address)
	 */
	std::vector<networkInfo> getNetworks();
};

#endif /* LDAP_H_ */
