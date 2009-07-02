/*
 * Client.cpp
 *
 *  Created on: 23.04.2009
 *      Author: bastian
 */

#include "Client.h"
#include "ClientStates.h"
#include "Utility.h"
#include "StdLogger.h"
#include "Configuration.h"
#include <iostream>

using namespace std;

/**
 * Client default constructor
 */
Client::Client(AttributeMap al, std::vector<PXESlot> slots)
{
	exists_in_ldap = true;
	host_responding = false;
	ping_attempts = 0;

	pthread_mutex_init(&sshMutex, NULL);
	pthread_mutex_init(&pingMutex, NULL);

    initiate(); // Statemachine

    attributes = al;

    pxeslots = setPXEInfo(slots);


    StdLogger* log = new StdLogger();

    log->log(LOG_LEVEL_INFO,"Client with name \"" + al["HostName"]+"\" created!",this);

    IPAddress ip = Utility::ipFromString(al["IPAddress"]);

}

/**
 * Client default destructor
 */
Client::~Client() {
    terminate(); // Statemachine
}

void Client::updateFromLdap(AttributeMap attr, std::vector<PXESlot> slots) {
	attributes = attr;

	// TODO
	// Verhalten muss definiert werden für den Fall, dass der aktuell laufende PXESlot ersetzt wird.
	pxeslots = setPXEInfo(slots);
}

std::vector<PXEInfo> Client::setPXEInfo(std::vector<PXESlot> timeslots) {
	size_t found;
	std::string temp;
	std::vector<string> splitTimeString;
	std::vector<string> splitStartString;
	std::vector<string> splitEndString;
	std::vector<PXEInfo> pxeinfoVector;
	PXEInfo tempInfo;

	int i;

	// iteration over alls pxe slots
	for(i = 0; i < timeslots.size(); i++) {


		temp = timeslots[i].TimeSlot;

		tempInfo.TimeString = temp;
		tempInfo.MenuName = timeslots[i].cn;
		tempInfo.ForceBoot = timeslots[i].ForceBoot;

		// split the time code into day of week, start time and end time
		while( (found=temp.find_first_of("_")) != std::string::npos) {
			splitTimeString.push_back(temp.substr(0, found));
			temp = temp.substr(found+1);
		}
		splitTimeString.push_back(temp);

		// split start time into hour and minute/10
		found = splitTimeString[1].find_first_of(":");
		splitStartString.push_back(splitTimeString[1].substr(0,found));
		splitStartString.push_back(splitTimeString[1].substr(found+1));

		// split end time into hour and minute/10
		found = splitTimeString[2].find_first_of(":");
		splitEndString.push_back(splitTimeString[2].substr(0,found));
		splitEndString.push_back(splitTimeString[2].substr(found+1));

		// assign the corresponding times
		tempInfo.StartTime.tm_sec = 0;
		tempInfo.ShutdownTime.tm_sec = 0;

		tempInfo.StartTime.tm_hour = Utility::toInt(splitStartString[0]);
		tempInfo.ShutdownTime.tm_hour = Utility::toInt(splitEndString[0]);

		tempInfo.StartTime.tm_min = Utility::toInt(splitStartString[1]);
		tempInfo.StartTime.tm_min *= 10;
		tempInfo.ShutdownTime.tm_min = Utility::toInt(splitEndString[1]);
		tempInfo.ShutdownTime.tm_min *= 10;

		tempInfo.StartTime.tm_wday = tempInfo.ShutdownTime.tm_wday = Utility::toInt(splitTimeString[0]);

		// clear the temporary vectors
		splitStartString.clear();
		splitEndString.clear();
		splitTimeString.clear();

		pxeinfoVector.push_back(tempInfo);
	}

	return pxeinfoVector;
}

bool Client::isActive(bool shutdown) {
	time_t currentTime;
	time_t futureTime;
	time(&currentTime);

	if(shutdown)
		futureTime = currentTime + Configuration::getInstance()->getInt("shutdown_time");
	else
		futureTime = currentTime + Configuration::getInstance()->getInt("warn_time");

	struct tm * currentTm = localtime(&currentTime);
	struct tm * futureTm = localtime(&futureTime);


	for(int i=0; i < pxeslots.size(); i++) {
		// checking the right week day
		if(currentTm->tm_wday != pxeslots[i].StartTime.tm_wday)
			continue;

		// checking the interval with precision of full hours
		if((currentTm->tm_hour < pxeslots[i].StartTime.tm_hour) || (futureTm->tm_hour > pxeslots[i].ShutdownTime.tm_hour))
				continue;

		// checking whether it's in start hour but before start minute
		if((currentTm->tm_hour == pxeslots[i].StartTime.tm_hour) && (currentTm->tm_min < pxeslots[i].StartTime.tm_min))
				continue;

		// checking whether it's in finish hour but after finish minute
		if((futureTm->tm_hour == pxeslots[i].ShutdownTime.tm_hour) && (futureTm->tm_min > pxeslots[i].ShutdownTime.tm_min))
				continue;

		return true;
	}

	return false;
}

PXEInfo* Client::getActiveSlot(bool shutdown) {
	time_t currentTime;
	time_t futureTime;
	time(&currentTime);

	if(shutdown)
		futureTime = currentTime + Configuration::getInstance()->getInt("shutdown_time");
	else
		futureTime = currentTime + Configuration::getInstance()->getInt("warn_time");

	struct tm * currentTm = localtime(&currentTime);
	struct tm * futureTm = localtime(&futureTime);


	for(int i; i < pxeslots.size(); i++) {
		if(currentTm->tm_wday != pxeslots[i].StartTime.tm_wday)
			continue;
		if((currentTm->tm_hour < pxeslots[i].StartTime.tm_hour) || (futureTm->tm_hour > pxeslots[i].ShutdownTime.tm_hour))
				continue;
		if((currentTm->tm_hour == pxeslots[i].StartTime.tm_hour) && (currentTm->tm_min < pxeslots[i].StartTime.tm_min))
				continue;
		if((futureTm->tm_hour == pxeslots[i].ShutdownTime.tm_hour) && (futureTm->tm_min > pxeslots[i].ShutdownTime.tm_min))
				continue;
		return &pxeslots[i];
	}

	return NULL;
}

std::string Client::getHWAddress() {
	return attributes["HWaddress"];
}

std::string Client::getIP() {
	return attributes["IPAddress"];
}

std::string Client::getHostName() {
	return attributes["HostName"];
}

std::map<std::string,bool> Client::getCmdTable() {
	pthread_mutex_lock(&sshMutex);
	map<string,bool> result(cmdTable);
	pthread_mutex_unlock(&sshMutex);

	return result;
}

void Client::setCmdTable(std::map<std::string,bool> cmds) {
	pthread_mutex_lock(&sshMutex);

	// TODO
	// Hier wäre ein abgleich der Daten wünschenswert, da u.U. schon neue Daten
	// eingefügt worden sind, die hiermit überschrieben werden.
	cmdTable = cmds;
	pthread_mutex_unlock(&sshMutex);
}

void Client::insertCmd(std::string cmd) {
	cmdTable.insert(std::pair<std::string, bool>(cmd, false));
}

void Client::resetCmdTable() {
	cmdTable.clear();
}

void Client::processClient() {

	// checking whether client is in PXE state
	// and applying specific checks
	try {
		state_cast<const ClientStates::PXE &>();
		checkPXE();
	}
	catch(const std::bad_cast &Ex) {}

	// checking "Wake"
	try {
		state_cast<const ClientStates::Wake &>();
		checkWake();
	}
	catch(const std::bad_cast &Ex) {}

	// checking "PingWake"
	try {
		state_cast<const ClientStates::PingWake &>();
		checkPingWake();
	}
	catch(const std::bad_cast &Ex) {}

	// checking Error
	try {
		state_cast<const ClientStates::Error &>();
		checkError();
	}
	catch(const std::bad_cast &Ex) {}

	// checking "SshWake"
	try {
		state_cast<const ClientStates::SshWake &>();
		checkSSHWake();
	}
	catch(const std::bad_cast &Ex) {}

	// checking "PingOffline"
	try {
		state_cast<const ClientStates::PingOffline &>();
		checkPingOffline();
	}
	catch(const std::bad_cast &Ex) {}

	// checking "SshOffline"
	try {
		state_cast<const ClientStates::SshOffline &>();
		checkSSHOffline();
	}
	catch(const std::bad_cast &Ex) {}

	// checking "Shutdown"
	try {
		state_cast<const ClientStates::Shutdown &>();
		checkShutdown();
	}
	catch(const std::bad_cast &Ex) {}
}

void Client::checkOffline() {
	if(isActive())
		process_event(EvtStart());
}

void Client::checkPXE() {

	if(isActive(true) == false) {
		process_event(EvtShutdown());
		return;
	}

	// TODO
	// Hier sollten noch Timing-Bedingungen eingefügt werden
	pthread_mutex_lock(&pingMutex);
	if( (host_responding & (char)0xC0) == (char)0xC0 ) {
		ping_attempts = 0;
		process_event(EvtPingSuccess());
	}
	pthread_mutex_unlock(&pingMutex);

	pthread_mutex_lock(&pingMutex);
	if( (host_responding & (char)0xC0) == (char)0x80 ) {
		process_event(EvtPingFailure());
	}
	pthread_mutex_unlock(&pingMutex);
}

void Client::checkWake() {

	pthread_mutex_lock(&pingMutex);
	if( (host_responding & (char)0xC0) == (char)0xC0 ) {
			ping_attempts = 0;
			process_event(EvtPingSuccess());
		}
	pthread_mutex_unlock(&pingMutex);

	pthread_mutex_lock(&pingMutex);
	if( (host_responding & (char)0xC0) == (char)0x80 ) {
		ping_attempts++;
		if(ping_attempts > 5)
			process_event(EvtPingError());
		else
			process_event(EvtPingFailure());
	}
	pthread_mutex_unlock(&pingMutex);
}

void Client::checkPingWake() {

	pthread_mutex_lock(&sshMutex);
	if( (ssh_responding & (char)0xC0) == (char)0xC0 ) {
		ssh_attempts = 0;
		process_event(EvtSshSuccess());
	}
	pthread_mutex_unlock(&sshMutex);

	pthread_mutex_lock(&sshMutex);
	if( (ssh_responding & (char)0xC0) == (char)0x80 ) {
		ssh_attempts ++;
		if(ssh_attempts > 5)
			process_event(EvtSshError());
		else
			process_event(EvtPingFailure());
	}
	pthread_mutex_unlock(&sshMutex);
}

void Client::checkError() {
	// TODO
	// Specify error handling or
	// remove if it's done inside the state
}

void Client::checkSSHWake() {

	if(isActive(true) == false) {
		process_event(EvtShutdown());
		return;
	}

	pthread_mutex_lock(&sshMutex);
	if( (ssh_responding & (char)0xC0) == (char)0xC0 ) {
		ssh_attempts = 0;
		process_event(EvtSshSuccess());
	}
	pthread_mutex_unlock(&sshMutex);

	pthread_mutex_lock(&sshMutex);
	if( (ssh_responding & (char)0xC0) == (char)0x80 ) {
		ssh_attempts ++;
		process_event(EvtPingFailure());
	}
	pthread_mutex_unlock(&sshMutex);
}

void Client::checkPingOffline() {

	pthread_mutex_lock(&sshMutex);
	if( (ssh_responding & (char)0xC0) == (char)0xC0 ) {
		ssh_attempts = 0;
		process_event(EvtSshSuccess());
	}
	pthread_mutex_unlock(&sshMutex);

	pthread_mutex_lock(&sshMutex);
	if( (ssh_responding & (char)0xC0) == (char)0x80 ) {
		ssh_attempts ++;
		if(ssh_attempts > 5)
			process_event(EvtSshError());
		else
			process_event(EvtPingFailure());
	}
	pthread_mutex_unlock(&sshMutex);
}

void Client::checkSSHOffline() {
	if(isActive(true) == false) {
		process_event(EvtShutdown());
		return;
	}

	pthread_mutex_lock(&sshMutex);
	if( (ssh_responding & (char)0xC0) == (char)0xC0 ) {
		ssh_attempts = 0;
		process_event(EvtSshSuccess());
	}
	pthread_mutex_unlock(&sshMutex);

	pthread_mutex_lock(&sshMutex);
	if( (ssh_responding & (char)0xC0) == (char)0x80 ) {
		ssh_attempts ++;
		process_event(EvtPingFailure());
	}
	pthread_mutex_unlock(&sshMutex);
}

void Client::checkShutdown() {
	// nothing todo here
}
