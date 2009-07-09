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
struct Offline;
struct PXE;
struct Wake;
struct PingWake;
struct PingOffline;
struct SshWake;
struct SshOffline;
struct Error;
struct Shutdown;



struct Offline : sc::simple_state<Offline, Client> {
    typedef sc::transition< EvtStart, PXE > reactions;
    Offline();
    virtual ~Offline();
};

struct PXE : sc::simple_state<PXE, Client> {
    typedef mpl::list <
        sc::transition< EvtWakeCommand, Wake >,
        sc::transition< EvtPingFailure, PXE >,
        sc::transition< EvtPingSuccess, PingOffline > > reactions;

    PXE();
    ~PXE();
};

struct Wake : sc::simple_state<Wake, Client> {
    typedef mpl::list <
		sc::transition< EvtPingSuccess, PingWake >,
		sc::transition< EvtPingFailure, Wake >,
		sc::transition< EvtPingError, Error > > reactions;

    Wake();
    ~Wake() {};
};

struct PingWake : sc::simple_state<PingWake, Client> {
    typedef mpl::list<
        sc::transition< EvtSshError, Error >,
        sc::transition< EvtSshSuccess, SshWake >,
        sc::transition< EvtSshFailure, PingWake > >  reactions;

    PingWake();
    ~PingWake() {};
};

struct PingOffline : sc::simple_state<PingOffline, Client> {
    typedef mpl::list<
		sc::transition< EvtSshError, PXE >,
        sc::transition< EvtSshSuccess, SshOffline >,
        sc::transition< EvtSshFailure, PingOffline > >  reactions;

    PingOffline();
    ~PingOffline() {};
};

struct Error : sc::simple_state<Error, Client> {
    typedef sc::transition< EvtOffline, Offline > reactions;

    Error() {};
    ~Error() {};
};

struct SshWake: sc::simple_state<SshWake, Client>  {
    typedef mpl::list <
        sc::transition< EvtShutdown, Shutdown >,
        sc::transition< EvtSshFailure, PingWake >,
        sc::transition< EvtSshSuccess, SshWake > > reactions;

    SshWake();
    ~SshWake();
};

struct SshOffline: sc::simple_state<SshOffline, Client>  {
    typedef mpl::list <
        sc::transition< EvtShutdown, Shutdown >,
        sc::transition< EvtSshFailure, PingOffline >,
        sc::transition< EvtSshSuccess, SshOffline > > reactions;

    SshOffline();
    ~SshOffline();
};

struct Shutdown : sc::simple_state<Shutdown, Client>  {
    typedef mpl::list <
		sc::transition< EvtOffline, Offline >,
		sc::transition< EvtStart, PXE > > reactions;

    Shutdown();
    ~Shutdown();
};

}

#endif /* CLIENTSTATES_H_ */
