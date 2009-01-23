#include "inc/functions.h"

#include <iostream>
#include <unistd.h>
#include <pwd.h>
#include <sys/types.h>

/******************************************
 * Adds user info and hostname to xml
 *
 * usernode: <username param="user" />
 * hostnamenode: <hostname param="host" />
 * computername: needed for bootpgm <computername .../>
 ******************************************/
void addInfo(xmlNode* node) {
  
  if(node == NULL) {
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
  xmlNodePtr firstchild = node->children;
 
  // just use some standard Linux functions here ...
  id = geteuid(); // gets effective user id
  pwd = getpwuid(id); // gets passwd struct (including username)
  gethostname(hostname, MAX_LENGTH-1); // gets hostname
 
  // Get <username> node and add "username#param" attribute
  while(cur != NULL) {
    if (!xmlStrcmp(cur->name, (const xmlChar *)"username")){
      user = true;
      usernode = cur;
      break;
    }
    cur = cur->next;
  }
  if(! user) {
    usernode = xmlNewNode(NULL, (const xmlChar*) "username");
    if(usernode != NULL ) {
      xmlNewProp(usernode, (const xmlChar*) "param", (const xmlChar*) pwd->pw_name);
      xmlAddChild(node, usernode);
    }
    else {
      cerr << "<username> node could not be created!" << endl;
    }
  }
  else {
    // set param attribute in <username>
    xmlSetProp(usernode, (const xmlChar*) "param", (const xmlChar*) pwd->pw_name);
  }

  cur = node->children;
 
  // Get <hostname> node and add "hostname#param" attribute
  while(cur != NULL) {
    if (!xmlStrcmp(cur->name, (const xmlChar *)"hostname")){
      host = true;
      hostnamenode = cur;
      break;
    }
    cur = cur->next;
  }
  if(! host) {
    hostnamenode = xmlNewNode(NULL, (const xmlChar*) "hostname");
    if(hostnamenode != NULL ) {
      xmlNewProp(hostnamenode, (const xmlChar*) "param", (const xmlChar*) hostname);
      xmlAddChild(node, hostnamenode);
    }
    else {
      cerr << "<hostname> node could not be created!" << endl;
    }
  }
  else {
    // add param value to existant hostname-node
    xmlSetProp(hostnamenode, (const xmlChar*) "param", (xmlChar*) hostname);
  }

  // We need to add computername-node as the first node
  compnamenode = xmlNewNode(NULL, (const xmlChar*) "computername");
  if(compnamenode != NULL) {
    xmlNewProp(compnamenode, (const xmlChar*) "param", (const xmlChar*) hostname);
    // Add this node to the beginning of available children
    // -> that is because bootpgm only looks in the first 500 chars
    if(firstchild != NULL) {
      xmlAddPrevSibling(firstchild, compnamenode);
    }
    //xmlFreeNode(compnamenode);
  }
  else {
    cerr << "<computername> node could not be created!" << endl;
  }

  return;
}

