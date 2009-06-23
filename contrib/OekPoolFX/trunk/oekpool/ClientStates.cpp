/*
 * ClientStates.cpp
 *
 *  Created on: 24.04.2009
 *      Author: bastian
 */

#include "Configuration.h"
#include "ClientStates.h"
#include "boost/filesystem.hpp"
#include "Utility.h"
#include "Network.h"

namespace bfs = boost::filesystem;

/**
 * "Offline"-state enter function
 */
ClientStates::Offline::Offline() {
    //cout << "Entered Offline state!" << endl;
}

ClientStates::Offline::~Offline() {

}

/**
 * "PXEConfig"-state enter function
 */
ClientStates::PXE::PXE() {
   // cout << "Entered PXEConfig state!" << endl;
	Client& client = context<Client>();
	PXEInfo* pxe = client.getActiveSlot();

	std::string tftp = Configuration::getInstance()->getString("tftp_root_dir");
	std::string dir = pxe->TimeString;
	std::string file = Utility::getPXEFilename(client.getHWAddress());
	bfs::path link(tftp + file);
	bfs::path source(dir + "/" + file);

	if(bfs::exists(link)) {
		bfs::remove(link);
		bfs::create_symlink(link,source);
	}
	else {
		bfs::create_symlink(link,source);
	}

	if(pxe->ForceBoot) {
		client.process_event(EvtWakeCommand());
	}
	else {
		Network::getInstance()->hostAlive(client.host_responding, client.getIP(), &client.pingMutex);
	}
}

ClientStates::PXE::~PXE(){}

/**
 * "Wake"-state enter function
 */
ClientStates::Wake::Wake() {
    //cout << "Entered Wake state!" << endl;
	Client& client = context<Client>();

	Network::getInstance()->sendWolPacket(Utility::ipFromString(client.getIP()), client.getHWAddress());

	Network::getInstance()->hostAlive(client.host_responding, client.getIP(), &client.pingMutex);
}
