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
#include <boost/filesystem.hpp>

#include <cstring>
#include <vector>
#include <iostream>
#include <fstream>

#include "inc/constants.h"
#include "inc/DataEntry.h"
#include "inc/functions.h"

namespace bfs=boost::filesystem;

#ifdef LIBXML_TREE_ENABLED

string env;
vector<string> xmlVec;

xmlXPathObjectPtr evalXPath(xmlDocPtr doc, const char* path) {
	xmlXPathContextPtr xp = xmlXPathNewContext(doc);
	string bla = string(path);
	if(xp == NULL) {
		fprintf(stderr,"Error: unable to create new XPath context\n");
		xmlFreeDoc(doc);
		return NULL;
	}
	xmlXPathObjectPtr result = xmlXPathEvalExpression((const xmlChar*)bla.c_str(), xp);
	if(result == NULL) {
		fprintf(stderr,"Error: unable to evaluate xpath expression \"%s\"\n", bla.c_str());
		xmlXPathFreeContext(xp);
		xmlFreeDoc(doc);
		return NULL;
	}
	xmlXPathFreeContext(xp);
	return result;
}

char* getAttribute(xmlDoc *doc, char* name)
{
	xmlNode* temp;
	string path = string("/settings/eintrag/")+ string(name)+ string("/@param");
	char* cpath = strdup(path.c_str());

	//print_xpath_nodes(xpp->nodesetval, stdout);

	// Get Attribute via XPath
	xmlXPathObjectPtr xpp = evalXPath(
			doc,
			(const char*)cpath
		);
	free(cpath);

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

        tempc = getAttribute(doc,(char *)"short_description");
        if (tempc != NULL ) {
                de->short_description = tempc;

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
                } else if (strcmp(tempc,"virtualbox") == 0) {
                        de->imgtype = VBOX;
                } else {
                    de->imgtype = OTHER;
                }
        }
        else {

          // Defaults to vmware - if the attribute is unknown
          de->imgtype = VMWARE;

        }
        tempc = NULL;

        tempc = getAttribute(doc,(char *) "active");
        if (tempc != NULL ) {
                de->active = (strstr(tempc,"true")!= NULL?true:false);
                if(de->active == false) {
                    delete de;
                    return NULL;
                }
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

        tempc = getAttribute(doc,(char *) "icon");
        if (tempc != NULL ) {
                de->icon = tempc;
        }
        else {
                de->icon = "vmware";
        }
        tempc = NULL;

        de->xml = doc;

        return de;
}


/**
 * The main function of this file:
 *
 * - calls xmlfilter.sh to glob a folder for xmls
 *   -> if no xmlfilter.sh is available, it globs for available xmls
 * - reads all xml files and creates for each its own DataEntry-struct
 */
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

  bfs::path filter(string(fpath).append("/").append(filterscript));


  if(bfs::is_regular_file(filter)) {
	  if( (inp = popen(string(fpath).append("/")
	          .append(filterscript).append(" ")
	          .append(path).c_str(), "r" )) && bfs::is_regular_file(filter) ) {
	      while(fgets(line, MAX_LENGTH, inp ) != NULL) {
	        xmlVec.push_back(string(line).substr(0,strlen(line)-1) );
	      }
	      pclose(inp);
	  }
  }
  else
  {
	  ifstream conffile("/etc/opt/openslx/vmchooser-stage3.conf");
	  if(conffile) {
		  int n = 255;
		  char buf[n];
		  string s = "";
		  while(!conffile.eof()) {
			  conffile.getline(buf, n);
			  s = buf;
			  if(s.substr(0,13) == "vmchooser_env") {
				  env = s.substr(15,s.length()-16);
			  }
		  }
	  }

	  glob_t globbuf;
	  glob(string(path).append("*.xml").c_str(), NULL, NULL, &globbuf);

	  xmlDocPtr tdoc = 0;
	  char* tstr = 0;

	  for(int c=0; c<globbuf.gl_pathc; c++) {
		  tdoc = xmlReadFile(globbuf.gl_pathv[c],NULL,XML_PARSE_RECOVER|XML_PARSE_NOERROR);

		  if(!tdoc) {
			  cerr << "Error opening xml file " << globbuf.gl_pathv[c] << "!" << endl;
			  return 0;
		  }

		  tstr = getAttribute(tdoc, (char*)"pools");

		  if(tstr == 0) {
			  xmlFreeDoc(tdoc);
			  continue;
		  }

		  if(env == tstr) {
			  xmlVec.push_back(string(globbuf.gl_pathv[c]) );
		  }

		  xmlFreeDoc(tdoc);
		  tdoc = 0; tstr = 0;
	  }

  }

  free(fpath);

  xmlDoc *doc = 0;
  int c = 0;
  string::size_type loc;

  // We need to reserve the memory for all the pointers here
  if(xmlVec.size() == 0) {
    return NULL;
  }
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

    doc = xmlReadFile(xmlVec[i].c_str(), NULL, XML_PARSE_RECOVER|XML_PARSE_NOERROR);
    if (doc == NULL) {
            fprintf(stderr, "error: could not parse file %s\n", xmlVec[i].c_str());
            continue;
    }

    result[c] = get_entry(doc);
    if (result[c] != 0) {
    	    result[c]->xml_name = xmlVec[i];
            c++;
    }
    /* xmlDoc still needed to write back information for VMware etc. */
    // xmlFreeDoc(doc);
  }

  result[c] = '\0';
  if(c!= 0) {
    return result;
  }
  else {
    return NULL;
  }

}


#else

#error "Tree Support for libxml2 must be available!"

#endif
