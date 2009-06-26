/*
 * Client.h
 *
 *  Created on: 23.04.2009
 *      Author: bastian
 */

#ifndef CLIENT_H_
#define CLIENT_H_

#include <boost/statechart/state_machine.hpp>
#include <boost/statechart/simple_state.hpp>
#include <boost/statechart/event.hpp>
#include <boost/statechart/transition.hpp>
#include <boost/mpl/list.hpp>
#include <time.h>
#include <pthread.h>

#include "events.h"
#include "types.h"

namespace mpl = boost::mpl;
namespace sc = boost::statechart;

namespace ClientStates {
    struct Offline;
}

// a Client object is a boost::statechart::state_machine
struct Client : sc::state_machine< Client, ClientStates::Offline > {
private:

	/**
	 *  attributes read from LDAP
	 */
    AttributeMap attributes;

    /**
     * pxeslots for this client
     */
    std::vector<PXEInfo> pxeslots;

    /**
     * bool, wether it is still in LDAP
     */
    bool exists_in_ldap;

    /**
     * private table to hold commands { ONLY ACCESSED THROUGH THREAD }
     */
    std::map<std::string,bool> cmdTable;

    /**
     * private function to reset pxe-informations
     */
    std::vector<PXEInfo> setPXEInfo(std::vector<PXESlot>);

public:
    Client(AttributeMap, std::vector<PXESlot>);
    ~Client();

    void updateFromLdap(AttributeMap,std::vector<PXESlot>);

    bool isActive();

    PXEInfo* getActiveSlot();
    std::string getHWAddress();
    std::string getIP();
    std::string getHostName();

    std::map<std::string,bool> getCmdTable();
    void setCmdTable(std::map<std::string,bool>);

    /**
     * public mutexes
     */
    pthread_mutex_t pingMutex, // mutex for pings
					sshMutex;  // mutex for ssh

    /**
     * wether host is responding (used by ping)
     */
    bool host_responding;

    /**
     * number of times the client has pinged
     * (used by states pxeconfig and wake)
     */
    int ping_attempts;
};



#endif /* CLIENT_H_ */
