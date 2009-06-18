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
    std::vector<PXESlot> pxeslots;

    bool exists_in_ldap;
public:
    Client(AttributeMap, std::vector<PXESlot>);
    ~Client();

    void updateFromLdap(AttributeMap,std::vector<PXESlot>);
};



#endif /* CLIENT_H_ */
