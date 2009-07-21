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
    std::vector<std::string> cmdTable;

    /**
     * private function to reset pxe-informations
     */
    std::vector<PXEInfo> setPXEInfo(std::vector<PXESlot>);

    /**
     * Indicates when to warn the user about shutdown next
     */
    time_t nextWarnTime;

    /**
     * Series of checks for every state of the client
     * Every check can trigger some state transition
     */
    void checkOffline(void);
    void checkPXE(void);
    void checkWake(void);
    void checkPingWake(void);
    void checkError(void);
    void checkSSHWake(void);
    void checkPingOffline(void);
    void checkSSHOffline(void);
    void checkShutdown(void);

public:
    Client(AttributeMap, std::vector<PXESlot>);
    ~Client();

    void updateFromLdap(AttributeMap,std::vector<PXESlot>);
    void processClient(void);

    bool isActive(bool shutdown = false);

    PXEInfo* getActiveSlot(bool shutdown = false);
    std::string getHWAddress();
    std::string getIP();
    std::string getHostName();

    std::vector<std::string> getCmdTable();
    void resetCmdTable(void);
    void insertCmd(std::string);

    /**
     * public mutexes
     */
    pthread_mutex_t pingMutex, // mutex for pings
					sshMutex;  // mutex for ssh

    /**
     * wether host is responding (used by ping and ssh)
     */
    char host_responding;
    char ssh_responding;

    /**
     * Indicates when shutdown state is finished
     */
    time_t shutdown;

    /**
     * number of times the client has pinged
     * (used by states pxeconfig and wake)
     */
    int ping_attempts, ssh_attempts;
};



#endif /* CLIENT_H_ */
