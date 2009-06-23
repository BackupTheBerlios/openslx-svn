/*
 * Client.cpp
 *
 *  Created on: 23.04.2009
 *      Author: bastian
 */

#include "Client.h"
#include "ClientStates.h"
#include "Utility.h"
#include "Logger.h"
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


    Logger* log = Logger::getInstance();

    log->log("Client with name \"" + al["HostName"]+"\" created!",LOG_LEVEL_INFO);

    IPAddress ip = Utility::ipFromString(al["IPAddress"]);

}

/**
 * Client default destructor
 */
Client::~Client() {
    terminate(); // Statemachine
}

void Client::updateFromLdap(AttributeMap attr, std::vector<PXESlot> slots) {

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

bool Client::isActive() {
	time_t currentTime;
	time_t futureTime;
	time(&currentTime);
	futureTime = currentTime + 600;
	struct tm * currentTm = localtime(&currentTime);
	struct tm * futureTm = localtime(&futureTime);


	for(int i; i < pxeslots.size(); i++) {
		if(currentTm->tm_wday != pxeslots[i].StartTime.tm_wday)
			continue;
		if((currentTm->tm_hour < pxeslots[i].StartTime.tm_hour) || (futureTm->tm_hour > pxeslots[i].ShutdownTime.tm_hour))
				continue;
		if((currentTm->tm_min < pxeslots[i].StartTime.tm_min) && (futureTm->tm_min > pxeslots[i].ShutdownTime.tm_min))
				continue;
		return true;
	}

	return false;
}

PXEInfo* Client::getActiveSlot() {
	time_t currentTime;
	time_t futureTime;
	time(&currentTime);
	futureTime = currentTime + 600;
	struct tm * currentTm = localtime(&currentTime);
	struct tm * futureTm = localtime(&futureTime);


	for(int i; i < pxeslots.size(); i++) {
		if(currentTm->tm_wday != pxeslots[i].StartTime.tm_wday)
			continue;
		if((currentTm->tm_hour < pxeslots[i].StartTime.tm_hour) || (futureTm->tm_hour > pxeslots[i].ShutdownTime.tm_hour))
				continue;
		if((currentTm->tm_min < pxeslots[i].StartTime.tm_min) && (futureTm->tm_min > pxeslots[i].ShutdownTime.tm_min))
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
