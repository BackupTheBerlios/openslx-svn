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

#endif /* EVENT_H_ */
