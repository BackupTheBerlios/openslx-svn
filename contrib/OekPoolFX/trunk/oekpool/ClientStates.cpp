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
#include "SshThread.h"

namespace bfs = boost::filesystem;

/**
 * "Offline"-state enter function
 */
ClientStates::Offline::Offline() {
    //cout << "Entered Offline state!" << endl;
	Client& client = context<Client>();
	client.resetCmdTable();
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
		client.host_responding = 0;
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

	// indicates that client is in "wake mode"
	client.host_responding = 0x20;

	Network::getInstance()->hostAlive(client.host_responding, client.getIP(), &client.pingMutex);
}

ClientStates::PingWake::PingWake() {
	// TODO
	// evtl. Timer setzen
	Client& client = context<Client>();
	client.insertCmd("echo \"ping?\"");
}

ClientStates::SshWake::SshWake() {
	// TODO
	// evtl Timer setzen
	Client& client = context<Client>();
	SshThread::getInstance()->addClient(&client);
	client.insertCmd("echo \"ping?\"");
}

ClientStates::SshWake::~SshWake() {
	Client& client = context<Client>();
	SshThread::getInstance()->delClient(&client);
}

ClientStates::SshOffline::SshOffline() {
	// TODO
	// evtl Timer setzen
	Client& client = context<Client>();
	SshThread::getInstance()->addClient(&client);
	client.insertCmd("echo \"ping?\"");
}

ClientStates::SshOffline::~SshOffline() {
	Client& client = context<Client>();
	SshThread::getInstance()->delClient(&client);
}

ClientStates::PingOffline::PingOffline() {
	// TODO
	// evtl Timer setzen
	Client& client = context<Client>();
	client.insertCmd("echo \"ping?\"");
}

ClientStates::Shutdown::Shutdown() {
	Client& client = context<Client>();
	client.insertCmd("shutdown -h now");

	client.process_event(EvtOffline());
}
