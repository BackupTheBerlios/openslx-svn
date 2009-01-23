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

#include "inc/DataEntry.h"
#include "inc/functions.h"


#ifdef LIBXML_TREE_ENABLED

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

        tempc = getAttribute(doc,"short_description");
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

        tempc = getAttribute(doc,"long_description");
        if (tempc != NULL ) {
                de->description = tempc;
        }
        tempc = NULL;

        tempc = getAttribute(doc,"creator");
        if (tempc != NULL ) {
                de->creator = tempc;
        }
        tempc = NULL;

        tempc = getAttribute(doc,"email");
        if (tempc != NULL ) {
                de->email = tempc;
        }
        tempc = NULL;

        tempc = getAttribute(doc,"phone");
        if (tempc != NULL ) {
                de->phone = tempc;
        }
        tempc = NULL;

        tempc = getAttribute(doc,"image_name");
        if (tempc != NULL ) {
                de->imgname = tempc;
        }
        tempc = NULL;

        tempc = getAttribute(doc,"os");
        if (tempc != NULL ) {
                de->os = tempc;
        }
        tempc = NULL;

        tempc = getAttribute(doc,"network");
        if (tempc != NULL ) {
                de->network = tempc;
        }
        tempc = NULL;
        

        tempc = getAttribute(doc,"virtualmachine");
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

        tempc = getAttribute(doc,"active");
        if (tempc != NULL ) {
                de->active = (strstr(tempc,"true")!= NULL?true:false);
        }
        tempc = NULL;
        
        tempc = getAttribute(doc,"locked");
        if (tempc != NULL ) {
                de->locked = (strstr(tempc,"true")!= NULL?true:false);
        }
        else {
                de->locked = false;
        }
        tempc = NULL;

        tempc = getAttribute(doc,"pools");
        if (tempc != NULL ) {
                de->pools = tempc;
        }
        tempc = NULL;

        tempc = getAttribute(doc,"xdm");
        if (tempc != NULL ) {
                de->xdm = tempc;
        }
        tempc = NULL;

        tempc = getAttribute(doc,"priority");
        if (tempc != NULL ) {
                de->priority = atoi(tempc);
        }
        tempc = NULL;
        
        de->xml = doc;

        return de;
}

static int errorfunc(const char* errpath, int errno)
{
        fprintf(stderr, "GLOB(): Fehler aufgetreten unter %s mit Fehlernummer %d \n",errpath, errno);
        return 0;
}


static glob_t* globber(char* path, const char* filetype)
{
        glob_t* gResult = (glob_t*) malloc(sizeof(glob_t));
        char* temp = (char*) malloc(strlen(path)+strlen(filetype)-1);
        strcpy(temp, path);
        strcat(temp, filetype);

        if (glob(temp, GLOB_NOSORT, &errorfunc, gResult)) {
                fprintf(stderr, "Fehler beim Öffnen des Ordners!\n");
                return NULL;
        }
        return gResult;

}


DataEntry** readXmlDir(char* path)
{
        LIBXML_TEST_VERSION
        if ( path== NULL) {
                return NULL;
        }
        glob_t *gResult = globber(path, "/*.xml");

        if ( gResult == NULL ) {
                return NULL;
        }

        if ( gResult->gl_pathc == 0 ) {
                return NULL;
        }

        xmlDoc *doc = NULL;
        int c = 0;

        DataEntry** result = (DataEntry**) malloc(gResult->gl_pathc * sizeof(DataEntry*) +1);

        for (int i=0; gResult->gl_pathv[i] != NULL; i++) {
//                 if (strstr(gResult->gl_pathv[i], "Vorlage") != NULL) {
//                         continue;
//                 }
                /* DEBUG */
                /* printf("%s\n", gResult->gl_pathv[i]);
                 */
                struct stat m;
                stat(gResult->gl_pathv[i], &m);

		/* DEBUG */
		// printf("File: %s, COUNT: %d\n", gResult->gl_pathv[i], gResult->gl_pathc);
                
		if ( S_ISDIR(m.st_mode) ) {
                        continue;
                }

                

                doc = xmlReadFile(gResult->gl_pathv[i], NULL, XML_PARSE_RECOVER);
                if (doc == NULL) {
                        fprintf(stderr, "error: could not parse file %s\n", gResult->gl_pathv[i]);
                        continue;
                }

                result[c] = get_entry(doc);
                if (result[c] != NULL) {
                        c++;
                }
                /* xmlDoc still needed to write back information for VMware etc. */
                // xmlFreeDoc(doc);
        }

        free(gResult);
        result[c] = NULL;
        return result;

}


#else

#error "Tree Support for libxml2 must be available!"

#endif
