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
#include <time.h>

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

    attributes = al;

    pxeslots = setPXEInfo(slots);


    StdLogger* log = new StdLogger();

    log->log(LOG_LEVEL_INFO,"Client with name \"" + al["HostName"]+"\" created!",this);

    IPAddress ip = Utility::ipFromString(al["IPAddress"]);
    time(&nextWarnTime);
    time(&shutdown);
    initiate(); // Statemachine
}

/**
 * Client default destructor
 */
Client::~Client() {
    terminate(); // Statemachine
}

void Client::updateFromLdap(AttributeMap attr, std::vector<PXESlot> slots) {
	// clog << "Updating client" << getHWAddress() << endl;
	attributes = attr;

	// TODO
	// (Verhalten muss definiert werden für den Fall, dass der aktuell laufende PXESlot ersetzt wird.)
	// Evtl. wird der Zugriff im Web-Interface gesperrt, sodass diesr Fall nicht auftritt.
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
	tm tempStart, tempShutdown;

	int i,z;

	// iteration over alls pxe slots
	for(i = 0; i < timeslots.size(); i++) {

		tempInfo.MenuName = timeslots[i].cn;
		tempInfo.ForceBoot = timeslots[i].ForceBoot;

		// iteration over all time slots
		for(z = 0; z < timeslots[i].TimeSlot.size(); z++){
			temp = timeslots[i].TimeSlot[z];

			tempInfo.TimeString.push_back(temp);

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
			tempStart.tm_sec = 0;
			tempShutdown.tm_sec = 0;

			tempStart.tm_hour = Utility::toInt(splitStartString[0]);
			tempShutdown.tm_hour = Utility::toInt(splitEndString[0]);

			tempStart.tm_min = Utility::toInt(splitStartString[1]);
			tempStart.tm_min *= 10;
			tempShutdown.tm_min = Utility::toInt(splitEndString[1]);
			tempShutdown.tm_min *= 10;

			tempStart.tm_wday = tempShutdown.tm_wday = Utility::toInt(splitTimeString[0]);

			// put the times into the time vectors
			tempInfo.StartTime.push_back(tempStart);
			tempInfo.ShutdownTime.push_back(tempShutdown);

			// clear the temporary vectors
			splitStartString.clear();
			splitEndString.clear();
			splitTimeString.clear();
		}
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
		for(int z=0; z < pxeslots[i].StartTime.size(); z++) {
			// checking the right week day
			if(currentTm->tm_wday != pxeslots[i].StartTime[z].tm_wday)
				continue;
			// checking the interval with precision of full hours
			if((currentTm->tm_hour < pxeslots[i].StartTime[z].tm_hour) || (futureTm->tm_hour > pxeslots[i].ShutdownTime[z].tm_hour))
					continue;
			// checking whether it's in start hour but before start minute
			if((currentTm->tm_hour == pxeslots[i].StartTime[z].tm_hour) && (currentTm->tm_min < pxeslots[i].StartTime[z].tm_min))
					continue;
			// checking whether it's in finish hour but after finish minute
			if((futureTm->tm_hour == pxeslots[i].ShutdownTime[z].tm_hour) && (futureTm->tm_min > pxeslots[i].ShutdownTime[z].tm_min))
					continue;
			return true;
		}
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


	for(int i=0; i < pxeslots.size(); i++) {
		for(int z=0; z < pxeslots[i].StartTime.size(); z++) {
			if(currentTm->tm_wday != pxeslots[i].StartTime[z].tm_wday)
				continue;
			if((currentTm->tm_hour < pxeslots[i].StartTime[z].tm_hour) || (futureTm->tm_hour > pxeslots[i].ShutdownTime[z].tm_hour))
				continue;
			if((currentTm->tm_hour == pxeslots[i].StartTime[z].tm_hour) && (currentTm->tm_min < pxeslots[i].StartTime[z].tm_min))
				continue;
			if((futureTm->tm_hour == pxeslots[i].ShutdownTime[z].tm_hour) && (futureTm->tm_min > pxeslots[i].ShutdownTime[z].tm_min))
				continue;
			return &pxeslots[i];
		}
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

std::vector<std::string> Client::getCmdTable() {
	pthread_mutex_lock(&sshMutex);
	vector<string> result(cmdTable);
	resetCmdTable();
	pthread_mutex_unlock(&sshMutex);

	return result;
}

void Client::insertCmd(std::string cmd) {
	cmdTable.push_back(cmd);
}

void Client::resetCmdTable() {
	cmdTable.clear();
}

void Client::processClient() {

	// clog << "Processing client" << getHostName() << endl;

	// checking whether client is in PXE state
	// and applying specific checks
	try {
		state_cast<const ClientStates::Offline &>();
		checkOffline();
	}
	catch(const std::bad_cast &Ex) {}

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
	if(isActive()) {
		process_event(EvtStart());
	}
}

void Client::checkPXE() {
	clog << "CheckPXE" << endl;
	if(!isActive()) {
		process_event(EvtShutdown());
		return;
	}

	if(getActiveSlot()->ForceBoot) {
		process_event(EvtWakeCommand());
		return;
	}

	// TODO
	// Hier sollten noch Timing-Bedingungen eingefügt werden
	pthread_mutex_lock(&pingMutex);
	if( (host_responding & (char)0xC0) == (char)0xC0 ) {
		ping_attempts = 0;
		host_responding = 0;
		process_event(EvtPingSuccess());
	}
	pthread_mutex_unlock(&pingMutex);

	pthread_mutex_lock(&pingMutex);
	if( (host_responding & (char)0xC0) == (char)0x80 ) {
		host_responding = 0;
		process_event(EvtPingFailure());
	}
	pthread_mutex_unlock(&pingMutex);
}

void Client::checkWake() {

	pthread_mutex_lock(&pingMutex);
	if( (host_responding & (char)0xC0) == (char)0xC0 ) {
			ping_attempts = 0;
			host_responding = 0;
			process_event(EvtPingSuccess());
		}
	pthread_mutex_unlock(&pingMutex);

	pthread_mutex_lock(&pingMutex);
	if( (host_responding & (char)0xC0) == (char)0x80 ) {
		ping_attempts++;
		host_responding = 0;
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
		ssh_responding = 0;
		process_event(EvtSshSuccess());
	}
	pthread_mutex_unlock(&sshMutex);

	pthread_mutex_lock(&sshMutex);
	if( (ssh_responding & (char)0xC0) == (char)0x40 ) {
		clog << "SSH Error!" << endl;
		ssh_attempts++;
		ssh_responding = 0;
		if(ssh_attempts > 5){
			clog << "SSH Error" << endl;
			process_event(EvtSshError());
			insertCmd("echo \"ping?\"");
		}
		else{
			clog << "SSH Failure" << endl;
			process_event(EvtPingFailure());
			insertCmd("echo \"ping?\"");
		}
	}
	pthread_mutex_unlock(&sshMutex);
}

void Client::checkError() {
	// TODO
	// Specify error handling or
	// remove if it's done inside the state
	process_event(EvtOffline());
}

void Client::checkSSHWake() {

	if(isActive(true) == false) {
		process_event(EvtShutdown());
		return;
	}


	if(isActive() == false) {
		time_t currentTime;
		time(&currentTime);
		if(currentTime > nextWarnTime)
		{
			insertCmd("xmessage -display :0 \"Dieser Rechner wird demnächst heruntergefahren.\nBitte speichern Sie alle Daten.\" &");
			nextWarnTime = currentTime + Configuration::getInstance()->getInt("warn_interval");
		}
	}

	pthread_mutex_lock(&sshMutex);
	if( (ssh_responding & (char)0xC0) == (char)0xC0 ) {
		ssh_attempts = 0;
		ssh_responding = 0;
		process_event(EvtSshSuccess());
	}
	pthread_mutex_unlock(&sshMutex);

	pthread_mutex_lock(&sshMutex);
	if( (ssh_responding & (char)0xC0) == (char)0x40 ) {
		clog << "SSH Error!" << endl;
		ssh_attempts ++;
		ssh_responding = 0;
		process_event(EvtPingFailure());
	}
	pthread_mutex_unlock(&sshMutex);
}

void Client::checkPingOffline() {

	// TODO
	// Hier sollten noch Timing-Bedingungen eingefügt werden
	pthread_mutex_lock(&sshMutex);
	if( (ssh_responding & (char)0xC0) == (char)0xC0 ) {
		ssh_attempts = 0;
		ssh_responding = 0;
		process_event(EvtSshSuccess());
	}
	pthread_mutex_unlock(&sshMutex);

	pthread_mutex_lock(&sshMutex);
	if( (ssh_responding & (char)0xC0) == (char)0x40 ) {
		clog << "SSH Error!" << endl;
		ssh_attempts ++;
		ssh_responding = 0;
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

	if(isActive() == false) {
		time_t currentTime;
		time(&currentTime);
		if(currentTime > nextWarnTime)
		{
			insertCmd("xmessage -display :0 \"Dieser Rechner wird demnächst heruntergefahren.\nBitte speichern Sie alle Daten.\" &");
			nextWarnTime = currentTime + Configuration::getInstance()->getInt("warn_interval");
		}
	}

	// TODO
	// Hier sollten noch Timing-Bedingungen eingefügt werden
	pthread_mutex_lock(&sshMutex);
	if( (ssh_responding & (char)0xC0) == (char)0xC0 ) {
		ssh_attempts = 0;
		ssh_responding = 0;
		process_event(EvtSshSuccess());
	}
	pthread_mutex_unlock(&sshMutex);

	pthread_mutex_lock(&sshMutex);
	if( (ssh_responding & (char)0xC0) == (char)0x40 ) {
		clog << "SSH Error!" << endl;
		ssh_attempts ++;
		ssh_responding = 0;
		process_event(EvtPingFailure());
	}
	pthread_mutex_unlock(&sshMutex);
}

void Client::checkShutdown() {
	time_t currentTime;
	time(&currentTime);
	if(shutdown + 10 < currentTime) {
		process_event(EvtOffline());
		shutdown = false;
	}
}
