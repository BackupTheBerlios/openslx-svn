#include <fltk/Widget.h>

#include "inc/DataEntry.h"
#include "inc/SWindow.h"
#include "inc/functions.h"

#include <sstream>

#include <errno.h>
#include <sys/wait.h>
#include <iostream>
#include <string>
#include <boost/regex.hpp>


/** *************************************************************
 * void runImage runs a (virtual machine) image using fork()
 *		calling runImage(DataEntry*)
 ***************************************************************/
void runImage(fltk::Widget*, void* p)
{
  string confxml;
  
  /* printf("runImage called\n"); */
  if ( p == NULL ) {
    return;
  }
  
  DataEntry& dat = *((DataEntry*) p);
  
  if(dat.imgtype == VMWARE) {
    confxml = writeConfXml(dat);
  }
  
  pid_t pid;
  int status;
  pid = fork();

  switch( pid )  {
    case -1:
      cout << "Something went wrong while forking!" << endl;
      return;
      break;
    case 0:
      exit(0);
      break;
    default:
      if( waitpid( pid, &status, 0 ) == -1 ) {
        cerr << "No child with this pid (" << pid << ")" << endl;
      }
      runImage(dat, confxml);
      break;
  }
}

/**
 * Helper-function for runImage(Widget, void) 
 * - runs the chosen virtualizer image
 **/
string runImage(DataEntry& dat, string confxml)
{
  //cout << dat.imgtype << endl << VMWARE << endl;
  if (dat.imgtype == VMWARE) {
    //cout << confxml << endl;
    char* arg[] = { "/var/X11R6/bin/run-vmware.sh",
            (char*)confxml.c_str(),
            NULL };
    
    //cout << arg << endl; //"run-vmware.sh imagename os (Window-Title) network"
    execvp("/var/X11R6/bin/run-vmware.sh",  arg);
  }
  if(! dat.command.empty() ) {
    char* arg[] = { (char*) dat.command.c_str(), '\0' };
    execvp((char*) dat.command.c_str(), arg);
  }
  return string();
}




/**
 * Helper-Function: Get folder name
 */
char* getFolderName() {
  const int MAX_LENGTH = 200;

  /* Var for the folder name */
  char* pname = (char*) malloc(MAX_LENGTH);
  int result;

  result = readlink("/proc/self/exe", pname, MAX_LENGTH);
  if (result > 0) {
    pname[result] = 0; /* add the NULL - not done by readlink */
  }

  int i=result-1;
  while(pname[i] != '/' && i >= 0) {
    pname[i] = '\0';
    i--;
  }
  if(pname[i] == '/' ) {
    pname[i] = '\0';
  }

  return pname;

}


string writeConfXml(DataEntry& dat) {

  //char* pname = getFolderName();
  string pname = string().append("/var/lib/vmware/runscripts");
  xmlNodePtr cur = 0;
  xmlNodePtr root = 0;
  
  string pskript = pname  +"/printer.sh";
  
  cur = xmlDocGetRootElement(dat.xml);
  if(cur == NULL) {
    printf("Empty XML Document %s!", dat.xml_name.c_str());
    return dat.xml_name.c_str();
  }
  
  // xmlNode "eintrag"
  root = cur->children;
  while(xmlStrcmp(root->name, (const xmlChar*)"eintrag") != 0) {
    root = root->next;
  }
  if(xmlStrcmp(root->name, (const xmlChar *)"eintrag") != 0){
    fprintf(stderr, "%s is not a valid xml file!", dat.xml_name.c_str());
    return dat.xml_name.c_str();
  }
  
  // add "printers" and "scanners" - XML-Nodes
  addPrinters(root, (char*)pskript.c_str());
  
  //char* pname = getFolderName();
  pskript = pname + "/scanners.sh";
  addScanners(root, (char*)pskript.c_str());
  
  //xmlSaveFile("-", dat.xml);
  srand(time(NULL));
  
  string xmlfile;
  ostringstream i;
  i <<  "/tmp/run" << rand() << ".xml";
  xmlfile = i.str();
  
  //ofstream file("/tmp/debug", ios_base::app);
  //file << xmlfile << rand()<< endl;
  
  xmlSaveFile( (char*) xmlfile.c_str(), dat.xml);
  return xmlfile;
}
