#include "inc/functions.h"

#include <iostream>
#include <fstream>
#include <unistd.h>
#include <pwd.h>
#include <sys/types.h>

#include "boost/filesystem.hpp"

#include <libxml/parser.h>
#include <libxml/tree.h>
#include <libxml/xpath.h>

namespace bfs = boost::filesystem;

extern string env;

/******************************************
 * Adds user info and hostname to xml
 *
 * usernode: <username param="user" />
 * hostnamenode: <hostname param="host" />
 * computername: needed for bootpgm <computername .../>
 ******************************************/
void addInfo(xmlNode* node, DataEntry* dat) {

	if (node == NULL) {
		return;
	}

	bool user = false;
	bool host = false;

	const int MAX_LENGTH = 200;
	char hostname[MAX_LENGTH];
	uid_t id;
	passwd *pwd;

	string strline;
	xmlNodePtr cur = node->children;
	xmlNodePtr usernode = NULL;
	xmlNodePtr hostnamenode = NULL;
	xmlNodePtr compnamenode = NULL;
	xmlNodePtr filenamenode = NULL;
	xmlNodePtr firstchild = node->children;

	// just use some standard Linux functions here ...
	id = geteuid(); // gets effective user id
	pwd = getpwuid(id); // gets passwd struct (including username)
	gethostname(hostname, MAX_LENGTH - 1); // gets hostname

	// Get <username> node and add "username#param" attribute
	while (cur != NULL) {
		if (!xmlStrcmp(cur->name, (const xmlChar *) "username")) {
			user = true;
			usernode = cur;
			break;
		}
		cur = cur->next;
	}
	if (!user) {
		usernode = xmlNewNode(NULL, (const xmlChar*) "username");
		if (usernode != NULL) {
			xmlNewProp(usernode, (const xmlChar*) "param",
					(const xmlChar*) pwd->pw_name);
			xmlAddChild(node, usernode);
		} else {
			cerr << "<username> node could not be created!" << endl;
		}
	} else {
		// set param attribute in <username>
		xmlSetProp(usernode, (const xmlChar*) "param",
				(const xmlChar*) pwd->pw_name);
	}

	cur = node->children;

	// Get <hostname> node and add "hostname#param" attribute
	while (cur != NULL) {
		if (!xmlStrcmp(cur->name, (const xmlChar *) "hostname")) {
			host = true;
			hostnamenode = cur;
			break;
		}
		cur = cur->next;
	}
	if (!host) {
		hostnamenode = xmlNewNode(NULL, (const xmlChar*) "hostname");
		if (hostnamenode != NULL) {
			xmlNewProp(hostnamenode, (const xmlChar*) "param",
					(const xmlChar*) hostname);
			xmlAddChild(node, hostnamenode);
		} else {
			cerr << "<hostname> node could not be created!" << endl;
		}
	} else {
		// add param value to existant hostname-node
		xmlSetProp(hostnamenode, (const xmlChar*) "param", (xmlChar*) hostname);
	}

	// We need to add computername-node as the first node
	compnamenode = xmlNewNode(NULL, (const xmlChar*) "computername");
	if (compnamenode != NULL) {
		xmlNewProp(compnamenode, (const xmlChar*) "param",
				(const xmlChar*) hostname);
		// Add this node to the beginning of available children
		// -> that is because bootpgm only looks in the first 500 chars
		if (firstchild != NULL) {
			xmlAddPrevSibling(firstchild, compnamenode);
		}
		//xmlFreeNode(compnamenode);
	} else {
		cerr << "<computername> node could not be created!" << endl;
	}

	// We need to add the filename to the xml
	if (dat->xml_name.empty())
		return;
	bfs::path path(dat->xml_name);
	std::string folder = path.branch_path().string();
	folder.append("/");

	if (folder.empty())
		return;
	cur = node->children;

	// Get <hostname> node and add "hostname#param" attribute
	while (cur != NULL) {
		if (!xmlStrcmp(cur->name, (const xmlChar *) "image_name")) {
			filenamenode = cur;
			break;
		}
		cur = cur->next;
	}
	if (!filenamenode) {
		cerr << "There is no node called 'image_name'. " << endl;
	} else {
		// add param value to existant hostname-node
		xmlChar* bla = xmlGetProp(filenamenode, (const xmlChar*) "param");
		if (!bla) {
			cerr << "Could not read Attribute 'param' in 'image_name' node."
					<< endl;
			return;
		} else {
			xmlSetProp(filenamenode, (const xmlChar*) "param",
					(const xmlChar*) folder.append((char*) bla).c_str());
		}
	}

	return;
}




/**
 * read specific xml files for a group from
 *
 *   /etc/opt/openslx/vmchooser-[groupname].xml
 *
 * and add group specific informations like shared_folders,
 * printers and scanners
 *
 * @param dat - this is the DataEntry struct pointer
 * @param group - this is the group name to get informations from
 */
void readGroupXml(DataEntry* dat, string group) {

	xmlNodePtr envnode = 0,
		tnode = 0, tnode2=0, tnode3=0, // temporary nodes
		shared=0, // Node for shared folders
		printer=0, // Node for printers
		scanner=0; // Node for scanners

	xmlChar* xmlenv = 0;
	string t;

	// these variables are for xpath queries
	xmlXPathObjectPtr xpp;
	int size = 0;

	xmlDocPtr doc = xmlReadFile(
			(string("/etc/opt/openslx/vmchooser-")+group+".xml").c_str(),
			NULL,
			XML_PARSE_RECOVER|XML_PARSE_NOERROR
	);

	if(! doc ) return;


	envnode = xmlFirstElementChild(doc->children);
	if(envnode == 0) {
		return;
	}

	do {
		xmlenv = xmlGetProp(envnode, (const xmlChar*)"param");
		if(xmlStrlen(xmlenv) == 0
				|| string((const char*)envnode->name) != "environment")
		{
			continue;
		}
		if(group == (const char*)xmlenv) {
			tnode = xmlFirstElementChild(envnode);
			do {
				if(tnode->type != XML_ELEMENT_NODE) continue;
				t = (const char*)tnode->name;

				// Here we are looking for shared_folders,printers and scanners
				// respectively
				if(t == "shared_folders") {
					// There could be many shared folders in there
					shared = xmlFirstElementChild(tnode);
					do {
						if(shared->type != XML_ELEMENT_NODE) continue;
						xpp = evalXPath(dat->xml, "/settings/eintrag/shared_folders");
						size = (xpp->nodesetval) ? xpp->nodesetval->nodeNr: 0;

						if(size == 0) {
							// shared_folders node not found - add it
							tnode2 = xmlNewNode(NULL, (const xmlChar*) "shared_folders");
							xmlAddChild(tnode2, shared);
							xpp = evalXPath(dat->xml, "/settings/eintrag");
							size = (xpp->nodesetval) ? xpp->nodesetval->nodeNr: 0;

							for (int i= 0; i < size; i++) {
								tnode3 = xpp->nodesetval->nodeTab[i];
								if (tnode3->type == XML_ELEMENT_NODE ) {
									xmlAddChild(tnode3, tnode2);
								} else {
									continue;
								}
							}
						}
						else
						{
							// found shared_folders node - add children
							for (int i= 0; i < size; i++) {
								tnode2 = xpp->nodesetval->nodeTab[i];
								if (tnode2->type == XML_ELEMENT_NODE ) {
									xmlAddChild(tnode2, shared);
								} else {
									continue;
								}
							}
						}
					} while ( (shared = shared->next) );
				}
				else if(t == "printers") {
					// There could be many printer nodes in there
					printer = xmlFirstElementChild(tnode);
					do {
						if(printer->type != XML_ELEMENT_NODE) continue;
						xpp = evalXPath(dat->xml, "/settings/eintrag/printers");
						size = (xpp->nodesetval) ? xpp->nodesetval->nodeNr: 0;

						if(size == 0) {
							// shared_folders node not found - add it
							tnode2 = xmlNewNode(NULL, (const xmlChar*) "printers");
							xmlAddChild(tnode2, printer);
							xpp = evalXPath(dat->xml, "/settings/eintrag");
							size = (xpp->nodesetval) ? xpp->nodesetval->nodeNr: 0;

							for (int i= 0; i < size; i++) {
								tnode3 = xpp->nodesetval->nodeTab[i];
								if (tnode3->type == XML_ELEMENT_NODE ) {
									xmlAddChild(tnode3, tnode2);
								} else {
									continue;
								}
							}
						}
						else
						{
							// found shared_folders node - add children
							for (int i= 0; i < size; i++) {
								tnode2 = xpp->nodesetval->nodeTab[i];
								if (tnode2->type == XML_ELEMENT_NODE ) {
									xmlAddChild(tnode2, printer);
								} else {
									continue;
								}
							}
						}
					} while ( (printer = printer->next) );
				}
				else if(t == "scanners") {
					// There could be many printer nodes in there
					scanner = xmlFirstElementChild(tnode);
					do {
						if(scanner->type != XML_ELEMENT_NODE) continue;
						xpp = evalXPath(dat->xml, "/settings/eintrag/scanners");
						size = (xpp->nodesetval) ? xpp->nodesetval->nodeNr: 0;

						if(size == 0) {
							// scanners node not found - add it
							tnode2 = xmlNewNode(NULL, (const xmlChar*) "scanners");
							xmlAddChild(tnode2, scanner);
							xpp = evalXPath(dat->xml, "/settings/eintrag");
							size = (xpp->nodesetval) ? xpp->nodesetval->nodeNr: 0;

							for (int i= 0; i < size; i++) {
								tnode3 = xpp->nodesetval->nodeTab[i];
								if (tnode3->type == XML_ELEMENT_NODE ) {
									xmlAddChild(tnode3, tnode2);
								} else {
									continue;
								}
							}
						}
						else
						{
							// found scanners node - add children
							for (int i= 0; i < size; i++) {
								tnode2 = xpp->nodesetval->nodeTab[i];
								if (tnode2->type == XML_ELEMENT_NODE ) {
									xmlAddChild(tnode2, scanner);
								} else {
									continue;
								}
							}
						}
					} while ( (scanner = scanner->next) );
				}
			}
			while ( (tnode = tnode->next) );
		}
	}
	while ( (envnode = envnode->next) );


}

