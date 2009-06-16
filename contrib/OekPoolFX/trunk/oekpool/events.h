/*
 * event.h
 *
 *  Created on: 24.04.2009
 *      Author: bastian
 */

#include <boost/statechart/event.hpp>

namespace sc = boost::statechart;

#ifndef EVENT_H_
#define EVENT_H_

struct EvtHostlistInsert : sc::event< EvtHostlistInsert > { };
struct EvtStart : sc::event< EvtStart > { };
struct EvtWakeCommand : sc::event<EvtWakeCommand> {};
struct EvtPingSuccess: sc::event< EvtPingSuccess > {};
struct EvtPingFailure: sc::event< EvtPingFailure > {};
struct EvtPingError: sc::event< EvtPingError > {};
struct EvtSshSuccess : sc::event<EvtSshSuccess> {};
struct EvtSshFailure : sc::event<EvtSshFailure> {};
struct EvtSshError : sc::event<EvtSshError> {};
struct EvtShutdown: sc::event< EvtShutdown > {};
struct EvtOffline : sc::event<EvtOffline> {};

// permanent mode of a client
struct EvtPermanentSSHError : sc::event<EvtPermanentSSHError> {};
struct EvtPermanentWake : sc::event<EvtPermanentWake> {};

#endif /* EVENT_H_ */
