/*
 * Ldap.h
 *
 *  Created on: 23.04.2009
 *      Author: julian
 */

#ifndef LDAP_H_
#define LDAP_H_

#include <ldap.h>
#include <string>
#include <vector>
#include "LDAPConnection.h"
#include "LDAPConstraints.h"

class Ldap {
    LDAPConstraints* cons;
    LDAPControlSet* ctrls;
    LDAPConnection *lc;
    char *host;
    int port;
    char *who;
    char *cred;
public:
	Ldap(char* host,int port, char* who, char* cred);
	virtual ~Ldap();
	std::vector<std::string> search(std::string base,int,std::string filter);
};

#endif /* LDAP_H_ */
