/*
 * Configuration.cpp
 *
 *  Created on: 20.05.2009
 *      Author: bastian
 */

#include "Configuration.h"
#include <iostream>
#include <sstream>
#include <string>

#include <libxml/parser.h>
#include <libxml/tree.h>


#ifndef LIBXML_TREE_ENABLED
#error "Tree Support for libxml2 must be available!"
#endif

using namespace std;


Configuration* Configuration::getInstance() {
    static Configuration instance;
    return &instance;
}

Configuration::~Configuration() {

}

Configuration::Configuration() {
    const char* filename = "config_own.xml";
    xmlDoc* doc =  xmlParseFile(filename);

    if(!doc) {
        cerr << "Could not open configuration file " << filename << " !" << endl;
        return;
    }

    xmlNode* root = doc->children;
    xmlChar* tval = NULL;

    if(!root) {
        cerr << "Could not get parent node!" << endl;
        return;
    }

    if(string((const char*)root->name) != "configuration") {
        return;
    }

    for(xmlNodePtr
        child = root->children;
        child!= NULL;
        child = child->next)
    {
        if(child->type != XML_ELEMENT_NODE) continue;
        tval = xmlNodeGetContent(child);
        vals[(char*)child->name] = (char*) tval;
        xmlFree(tval);
    }

    xmlFreeDoc(doc);
}

string Configuration::getString(string name) {

    // if key not found, return empty string
    if(vals.find(name)== vals.end()) {
        return string();
    }

    return vals[name];
}

int Configuration::getInt(string name) {

    int i;

    // if key not found, return -1
    if(vals.find(name)== vals.end()) {
        return -1;
    }
    // if value is empty
    if(vals[name].empty()) {
        return -1;
    }


    istringstream is;
    is.str(vals[name]);
    is >> i;

    return i;
}
