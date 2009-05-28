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

namespace mpl = boost::mpl;
namespace sc = boost::statechart;


// initial state - forward declaration
struct Offline;
// more states
struct PXEConfig;
struct Wake;
struct PingCheck;
struct Error;
struct SSHCheck;
struct Warn;
struct Shutdown;

// a Client object is a boost::statechart::state_machine
struct Client : sc::state_machine< Client, Offline > {
    Client();
    ~Client();
};



struct EvtHostlistInsert : sc::event< EvtHostlistInsert > { };
struct EvtChangePXE : sc::event< EvtChangePXE > { };
struct EvtWakeCommand : sc::event< EvtWakeCommand > { };
struct EvtAfterWakeCommand: sc::event< EvtAfterWakeCommand > {};
struct EvtPingSuccess: sc::event< EvtPingSuccess > {};
struct EvtOnError: sc::event< EvtOnError > {};
struct EvtShutdown: sc::event< EvtShutdown > {};
struct EvtErrorResolved: sc::event<EvtErrorResolved> {};
struct EvtHostlistDelete : sc::event<EvtHostlistDelete> {};
struct EvtSSHError : sc::event<EvtSSHError> {};
struct EvtWarnTimeout : sc::event<EvtWarnTimeout> {};

// permanent mode of a client
struct EvtPermanentSSHError : sc::event<EvtPermanentSSHError> {};
struct EvtPermanentWake : sc::event<EvtPermanentWake> {};

struct Offline : sc::simple_state< Offline, Client > {
    typedef sc::transition< EvtHostlistInsert, PXEConfig > reactions;
    Offline();
    ~Offline() {};
};

struct PXEConfig : sc::simple_state<PXEConfig, Client> {
    typedef mpl::list <
        sc::transition< EvtWakeCommand, Wake >,
        sc::transition< EvtPermanentWake, PingCheck > > reactions;

    PXEConfig();
    ~PXEConfig() {};
};

struct Wake : sc::simple_state<Wake, Client> {
    typedef sc::transition< EvtAfterWakeCommand, PingCheck > reactions;

    Wake();
    ~Wake() {};
};

struct PingCheck : sc::simple_state<PingCheck, Client> {
    typedef mpl::list<
        sc::transition< EvtOnError, Error >,
        sc::transition<EvtPingSuccess, SSHCheck >,
        sc::transition< EvtShutdown, Offline > >  reactions;

    PingCheck() {};
    ~PingCheck() {};
};

struct Error : sc::simple_state<Error, Client> {
    typedef sc::transition< EvtErrorResolved, Offline > reactions;

    Error() {};
    ~Error() {};
};

struct SSHCheck: sc::simple_state<SSHCheck, Client>  {
    typedef mpl::list <
        sc::transition< EvtShutdown, Warn >,
        sc::transition< EvtPermanentSSHError, PingCheck >,
        sc::transition< EvtSSHError, PingCheck > > reactions;

    SSHCheck() {};
    ~SSHCheck() {};
};

struct Warn : sc::simple_state<Warn, Client>  {
    typedef sc::transition< EvtWarnTimeout, Shutdown > reactions;

    Warn() {};
    ~Warn() {};
};

struct Shutdown : sc::simple_state<Shutdown, Client>  {
    typedef sc::transition< EvtHostlistDelete, Offline > reactions;

    Shutdown() {};
    ~Shutdown() {};
};

#endif /* CLIENT_H_ */
