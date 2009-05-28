/*
 * ClientStates.h
 *
 *  Created on: 24.04.2009
 *      Author: bastian
 */
#ifndef CLIENTSTATES_H_
#define CLIENTSTATES_H_


#include <boost/statechart/simple_state.hpp>
#include <boost/mpl/list.hpp>

#include "events.h"
#include "Client.h"


namespace sc = boost::statechart;
namespace mpl = boost::mpl;

namespace ClientStates {

// forward declaration to enable variable transitions
struct PXEConfig;
struct Wake;
struct PingCheck;
struct Error;
struct SSHCheck;
struct Warn;
struct Shutdown;



struct Offline : sc::simple_state<Offline, Client> {
    typedef sc::transition< EvtHostlistInsert, PXEConfig > reactions;
    Offline();
    ~Offline() {}
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

}

#endif /* CLIENTSTATES_H_ */
