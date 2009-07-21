/*
 * ClientStates.cpp
 *
 *  Created on: 24.04.2009
 *      Author: bastian
 */

#include <time.h>
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
ClientStates::Offline::Offline(my_context ctx): sc::state<Offline, Client>(ctx) {

	cout << "Entered Offline state: " << context<Client>().getHostName() << endl;
	context<Client>().ssh_responding = 0;
	context<Client>().host_responding = 0;
	context<Client>().ping_attempts = 0;

}

ClientStates::Offline::~Offline() {

}

/**
 * "PXEConfig"-state enter function
 */
ClientStates::PXE::PXE(my_context ctx): sc::state<PXE, Client>(ctx) {

    clog << "Entered PXEConfig state!" << endl;
	Client& client = outermost_context();
	PXEInfo* pxe = client.getActiveSlot();

	std::string tftp = Configuration::getInstance()->getString("tftp_root_dir");
	std::string dir = pxe->MenuName;
	std::string file = Utility::getPXEFilename(client.getHWAddress());

	bfs::path link(tftp + file);
	bfs::path source(dir + "/" + file);

	if(bfs::exists(link)) {
		bfs::remove(link);
		bfs::create_symlink(link,source);
	}
	else {
		//bfs::create_symlink(link,source);
	}

	if(!pxe->ForceBoot) {
		client.host_responding = 0;
		Network::getInstance()->hostAlive(client.host_responding, client.getIP(), &client.pingMutex);
	}
}

ClientStates::PXE::~PXE(){}

/**
 * "Wake"-state enter function
 */
ClientStates::Wake::Wake(my_context ctx): sc::state<Wake, Client>(ctx) {
    clog << "Entered Wake state!" << endl;
	Client& client = context<Client>();

	Network::getInstance()->sendWolPacket(Utility::ipFromString(client.getIP()), client.getHWAddress());

	// indicates that client is in "wake mode"
	client.host_responding = 0x20;

	Network::getInstance()->hostAlive(client.host_responding, client.getIP(), &client.pingMutex);
}

ClientStates::PingWake::PingWake(my_context ctx): sc::state<PingWake, Client>(ctx) {
	// TODO
	// evtl. Timer setzen
	clog << "Entered PingWake" << endl;
	Client& client = context<Client>();
	client.insertCmd("echo \"ping?\"");
	SshThread::getInstance()->addClient(&client);
}

ClientStates::SshWake::SshWake(my_context ctx): sc::state<SshWake, Client>(ctx) {
	// TODO
	// evtl Timer setzen
	clog << "Entered SshWake" << endl;
	Client& client = context<Client>();
	//SshThread::getInstance()->addClient(&client);
	client.insertCmd("echo \"ping?\"");

}

ClientStates::SshWake::~SshWake() {
	//Client& client = context<Client>();
	//SshThread::getInstance()->delClient(&client);
}

ClientStates::SshOffline::SshOffline(my_context ctx): sc::state<SshOffline, Client>(ctx) {
	// TODO
	// evtl Timer setzen
	clog << "Entered SshOffline" << endl;
	Client& client = context<Client>();
	//SshThread::getInstance()->addClient(&client);
	client.insertCmd("echo \"ping?\"");
}

ClientStates::SshOffline::~SshOffline() {
	//Client& client = context<Client>();
	//SshThread::getInstance()->delClient(&client);
}

ClientStates::PingOffline::PingOffline(my_context ctx): sc::state<PingOffline, Client>(ctx) {
	// TODO
	// evtl Timer setzen
	clog << "Entered PingOffline state!" << endl;
	Client& client = context<Client>();
	SshThread::getInstance()->addClient(&client);
	client.insertCmd("echo \"ping?\"");
}

ClientStates::Shutdown::Shutdown(my_context ctx): sc::state<Shutdown, Client>(ctx) {
	clog << "Entered Shutdown state!" << endl;
	Client& client = context<Client>();

	client.insertCmd("shutdown -h now");
	SshThread::getInstance()->addClient(&client);
	time(&(client.shutdown));
}

ClientStates::Shutdown::~Shutdown() {
	clog << "Left Shutdown state!" << endl;
	Client& client = context<Client>();
	SshThread::getInstance()->delClient(&client);
	client.resetCmdTable();
}
