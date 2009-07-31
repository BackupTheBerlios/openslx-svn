/*
 * ClientStates.h
 *
 *  Created on: 24.04.2009
 *      Author: bastian
 */
#ifndef CLIENTSTATES_H_
#define CLIENTSTATES_H_


#include <boost/statechart/state.hpp>
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

struct Offline : sc::state<Offline, Client> {
    typedef sc::transition< EvtStart, PXE > reactions;
    Offline(my_context ctx);
    virtual ~Offline();
};

struct PXE : sc::state<PXE, Client> {
    typedef mpl::list <
        sc::transition< EvtWakeCommand, Wake >,
        sc::transition< EvtPingFailure, PXE >,
        sc::transition< EvtPingSuccess, PingOffline >,
        sc::transition< EvtShutdown, Offline > > reactions;
	PXE(my_context ctx);
    ~PXE();
};

struct Wake : sc::state<Wake, Client> {
    typedef mpl::list <
		sc::transition< EvtPingSuccess, PingWake >,
		sc::transition< EvtPingFailure, Wake >,
		sc::transition< EvtPingError, Error > > reactions;

    Wake(my_context ctx);
    ~Wake() {};
};

struct PingWake : sc::state<PingWake, Client> {
    typedef mpl::list<
        sc::transition< EvtSshError, Error >,
        sc::transition< EvtSshSuccess, SshWake >,
        sc::transition< EvtSshFailure, PingWake > >  reactions;

    PingWake(my_context ctx);
    ~PingWake() {};
};

struct PingOffline : sc::state<PingOffline, Client> {
    typedef mpl::list<
		sc::transition< EvtSshError, PXE >,
        sc::transition< EvtSshSuccess, SshOffline >,
        sc::transition< EvtSshFailure, PingOffline > >  reactions;

    PingOffline(my_context ctx);
    ~PingOffline() {};
};

struct Error : sc::state<Error, Client> {
    typedef sc::transition< EvtOffline, Offline > reactions;

    Error(my_context ctx);
    ~Error() {};
};

struct SshWake: sc::state<SshWake, Client>  {
    typedef mpl::list <
        sc::transition< EvtShutdown, Shutdown >,
        sc::transition< EvtSshFailure, PingWake >,
        sc::transition< EvtSshSuccess, SshWake > > reactions;

    SshWake(my_context ctx);
    ~SshWake();
};

struct SshOffline: sc::state<SshOffline, Client>  {
    typedef mpl::list <
        sc::transition< EvtShutdown, Shutdown >,
        sc::transition< EvtSshFailure, PingOffline >,
        sc::transition< EvtSshSuccess, SshOffline > > reactions;

    SshOffline(my_context ctx);
    ~SshOffline();
};

struct Shutdown : sc::state<Shutdown, Client>  {
    typedef mpl::list <
		sc::transition< EvtOffline, Offline >,
		sc::transition< EvtStart, PXE > > reactions;

    Shutdown(my_context ctx);
    ~Shutdown();
};

}

#endif /* CLIENTSTATES_H_ */
