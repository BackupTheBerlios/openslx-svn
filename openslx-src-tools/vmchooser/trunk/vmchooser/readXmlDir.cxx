/**
 * author: Bastian Wissler
 * purpose: Scan a given folder for XML-Files and get information
 *	    about installed Images / SessionManagers
 */
#include <stdio.h>
#include <glob.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <libxml/parser.h>
#include <libxml/tree.h>
#include <libxml/xpath.h>

#include <boost/regex.hpp>

#include <vector>
#include <iostream>

#include "inc/constants.h"
#include "inc/DataEntry.h"
#include "inc/functions.h"


#ifdef LIBXML_TREE_ENABLED


vector<string> xmlVec;

char* getAttribute(xmlDoc *doc, char* name)
{
        xmlNode* temp;
	xmlXPathContextPtr xp = xmlXPathNewContext(doc);
	string bla = string("/settings/eintrag/")+ string(name)+ string("/@param");
	if(xp == NULL) {
		fprintf(stderr,"Error: unable to create new XPath context\n");
		xmlFreeDoc(doc);
		return NULL;
	}
	xmlXPathObjectPtr xpp = xmlXPathEvalExpression((const xmlChar*)bla.c_str(), xp);
	if(xpp == NULL) {
		fprintf(stderr,"Error: unable to evaluate xpath expression \"%s\"\n", bla.c_str());
		xmlXPathFreeContext(xp); 
		xmlFreeDoc(doc); 
		return NULL;
	}

	//print_xpath_nodes(xpp->nodesetval, stdout);
	int size;
	size = (xpp->nodesetval) ? xpp->nodesetval->nodeNr: 0;
        for (int i= 0; i < size; i++) {
		temp = xpp->nodesetval->nodeTab[i];
                if (temp->type == XML_ATTRIBUTE_NODE ) {
                        return (char*) temp->children->content;
                } else {
                        continue;
                }
        }
        return NULL;
}

char* getNodeValue(xmlDoc *doc, char* name)
{
        xmlNode* temp;
	xmlXPathContextPtr xp = xmlXPathNewContext(doc);
	string bla = string("/settings/eintrag/")+ string(name);
	if(xp == NULL) {
		fprintf(stderr,"Error: unable to create new XPath context\n");
		xmlFreeDoc(doc);
		return NULL;
	}
	xmlXPathObjectPtr xpp = xmlXPathEvalExpression((const xmlChar*)bla.c_str(), xp);
	if(xpp == NULL) {
		fprintf(stderr,"Error: unable to evaluate xpath expression \"%s\"\n", bla.c_str());
		xmlXPathFreeContext(xp); 
		xmlFreeDoc(doc); 
		return NULL;
	}

	//print_xpath_nodes(xpp->nodesetval, stdout);
	int size;
	size = (xpp->nodesetval) ? xpp->nodesetval->nodeNr: 0;
        for (int i= 0; i < size; i++) {
		temp = xpp->nodesetval->nodeTab[i];
                if (temp->type == XML_TEXT_NODE ) {
                        return (char*) temp->content;
                } else {
                        continue;
                }
        }
        return NULL;
}



DataEntry* get_entry(xmlDoc * doc)
{
        char *tempc = NULL;
        DataEntry* de = new DataEntry();
        
        if(doc->name != NULL) {
        	de->xml_name = string(doc->name);
        }

        tempc = getAttribute(doc,(char *)"short_description");
        if (tempc != NULL ) {
                de->short_description = tempc;
		//printf("%s\n",de->short_description.c_str());
		// replace a substring
                std::string dest_string, dest1_string;
                boost::regex re("\n|\r");
                boost::regex_replace(std::back_inserter(dest_string),
                        de->short_description.begin(),
                        de->short_description.end(),
                        re,
                        " ");
        }
        tempc = NULL;

        if (de->short_description.empty()) {
                free(de);
                fprintf(stderr, "No short_description given\n");
                return NULL;
        }

        tempc = getAttribute(doc,(char *) "long_description");
        if (tempc != NULL ) {
                de->description = tempc;
        }
        tempc = NULL;

        tempc = getAttribute(doc,(char *) "creator");
        if (tempc != NULL ) {
                de->creator = tempc;
        }
        tempc = NULL;

        tempc = getAttribute(doc,(char *) "email");
        if (tempc != NULL ) {
                de->email = tempc;
        }
        tempc = NULL;

        tempc = getAttribute(doc,(char *) "phone");
        if (tempc != NULL ) {
                de->phone = tempc;
        }
        tempc = NULL;

        tempc = getAttribute(doc,(char *) "image_name");
        if (tempc != NULL ) {
                de->imgname = tempc;
        }
        tempc = NULL;

        tempc = getAttribute(doc,(char *) "os");
        if (tempc != NULL ) {
                de->os = tempc;
        }
        tempc = NULL;

        tempc = getAttribute(doc,(char *) "network");
        if (tempc != NULL ) {
                de->network = tempc;
        }
        tempc = NULL;
        

        tempc = getAttribute(doc,(char *) "virtualmachine");
        if (tempc != NULL ) {
                if ( strcmp(tempc,"vmware") == 0 ) {
                        de->imgtype = VMWARE;
                } else {
                        de->imgtype = VBOX;
                }
        }
        else {
        
        
          /* TODO: DEFAULTS TO VMWARE HERE */
          de->imgtype = VMWARE;
        
        }
        tempc = NULL;

        tempc = getAttribute(doc,(char *) "active");
        if (tempc != NULL ) {
                de->active = (strstr(tempc,"true")!= NULL?true:false);
        }
        tempc = NULL;
        
        tempc = getAttribute(doc,(char *) "locked");
        if (tempc != NULL ) {
                de->locked = (strstr(tempc,"true")!= NULL?true:false);
        }
        else {
                de->locked = false;
        }
        tempc = NULL;

        tempc = getAttribute(doc,(char *) "pools");
        if (tempc != NULL ) {
                de->pools = tempc;
        }
        tempc = NULL;

        tempc = getAttribute(doc,(char *) "xdm");
        if (tempc != NULL ) {
                de->xdm = tempc;
        }
        tempc = NULL;

        tempc = getAttribute(doc,(char *) "priority");
        if (tempc != NULL ) {
                de->priority = atoi(tempc);
        }
        else {
                de->priority = 5;
        }
        tempc = NULL;
        
        de->xml = doc;

        return de;
}



DataEntry** readXmlDir(char* path)
{
  const int MAX_LENGTH = 256;
  char line[MAX_LENGTH];
  char* fpath = getFolderName();
  FILE* inp;

        LIBXML_TEST_VERSION
        if ( path== NULL) {
                return NULL;
        }

        if( (inp = popen(string(fpath).append("/")
              .append(filterscript).append(" ")
              .append(path).c_str(), "r" )) ) {
          while(fgets(line, MAX_LENGTH, inp ) != NULL) {
            xmlVec.push_back(string(line).substr(0,strlen(line)-1) );
          }
        }

        xmlDoc *doc = NULL;
        int c = 0;
        string::size_type loc;

        DataEntry** result = (DataEntry**) malloc(xmlVec.size() * sizeof(DataEntry*) +1);

        for (unsigned int i=0; i < xmlVec.size(); i++) {
                loc = xmlVec[i].find( "Vorlage" );
                if( loc != string::npos ) {
                  // FOUND Vorlage
                  continue;
                }
                
                struct stat m;
                stat(xmlVec[i].c_str(), &m);


                /* DEBUG */
                //printf("File: %s, COUNT: %d\n", xmlVec[i].c_str(), xmlVec.size());
                if ( S_ISDIR(m.st_mode) ) {
                        continue;
                }

                doc = xmlReadFile(xmlVec[i].c_str(), NULL, XML_PARSE_RECOVER);
                if (doc == NULL) {
                        fprintf(stderr, "error: could not parse file %s\n", xmlVec[i].c_str());
                        continue;
                }

                result[c] = get_entry(doc);
                if (result[c] != NULL) {
                        c++;
                }
                /* xmlDoc still needed to write back information for VMware etc. */
                // xmlFreeDoc(doc);
        }

        result[c] = NULL;
        return result;

}


#else

#error "Tree Support for libxml2 must be available!"

#endif
