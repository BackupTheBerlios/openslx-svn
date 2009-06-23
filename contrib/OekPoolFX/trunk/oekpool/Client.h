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
    AttributeMap attributes;
    std::vector<PXEInfo> pxeslots;
    bool exists_in_ldap;

    std::vector<PXEInfo> setPXEInfo(std::vector<PXESlot>);
public:
    Client(AttributeMap, std::vector<PXESlot>);
    ~Client();

    void updateFromLdap(AttributeMap,std::vector<PXESlot>);
    bool isActive();

    PXEInfo* getActiveSlot();
    std::string getHWAddress();
    std::string getIP();

    pthread_mutex_t pingMutex, sshMutex;
    bool host_responding;
    int ping_attempts;
};



#endif /* CLIENT_H_ */
