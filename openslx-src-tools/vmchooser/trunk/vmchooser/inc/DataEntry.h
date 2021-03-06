#ifndef DATAENTRY_H_
#define DATAENTRY_H_

#include <string>
#include <libxml/tree.h>
using namespace std;

enum ImgType {
	LINUX,
	VMWARE,
	VBOX,
    OTHER
};

struct DataEntry {

	string short_description;
	string description;

	string creator;
	string email;
	string phone;

	string imgname;
	ImgType imgtype;
	string os;
	string icon;
	string network;

	bool active;
	bool locked;
	string pools;
	string xdm;
	int priority;

	string command;
	string xml_name;
	xmlDoc* xml;

};

#endif /*DATAENTRY_H_*/
