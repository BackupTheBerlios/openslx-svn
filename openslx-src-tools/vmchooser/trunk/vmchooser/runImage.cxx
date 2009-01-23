#include <fltk/Widget.h>
#include <fltk/ask.h>
#include <fltk/run.h>

#include "inc/DataEntry.h"
#include "inc/SWindow.h"
#include "inc/functions.h"

#include <sstream>

#include <errno.h>
#include <sys/wait.h>
#include <iostream>
#include <string>
#include <boost/regex.hpp>


/* define MAX_LENGTH for string in getFolderName */
const int MAX_LENGTH = 200;
extern SWindow* mainwin;

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
  
  if(dat.imgtype == VMWARE || dat.imgtype == VBOX ) {
    confxml = writeConfXml(dat);
  }
  
  pid_t pid;
  // in case you want to wait hours on your thread
  //int status;
  pid = fork();
  char* argv[] = { "mesgdisp",  ///opt/openslx/plugin-repo/vmchooser/
        (char*) string("\n\nStarte Image: ").append(dat.short_description)
        .append("\n").c_str(), NULL };

  switch( pid )  {
    case -1:
      fltk::alert("Error occured during forking a thread of execution!");
      return;
      break;
    case 0:
      mainwin->destroy();
      fltk::wait();
      cout << "calling " << argv[1] << endl;
      execvp(argv[0], argv);
      break;
    default:
      // this is not really useful, as this
      // blocks execution for about 5 seconds
      // sometimes ;-)
      //if( waitpid( pid, &status, 0 ) == -1 ) {
      //  cerr << "No child with this pid (" << pid << ")" << endl;
      //  fltk::alert("Failed to create child thread!");
      //  return;
      //}
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
    char* arg[] = { (char *) "/var/X11R6/bin/run-vmware.sh",
            (char*)confxml.c_str(),
            NULL };
    
    //cout << arg << endl; //"run-vmware.sh imagename os (Window-Title) network"
    execvp("/var/X11R6/bin/run-vmware.sh",  arg);
  }
  if (dat.imgtype == VBOX) {
    char* arg[] = { (char *) "/var/X11R6/bin/run-virtualbox.sh",
            (char*)confxml.c_str(),
            NULL };
    
    //cout << arg << endl; //"run-vmware.sh imagename os (Window-Title) network"
    execvp("/var/X11R6/bin/run-virtualbox.sh",  arg);

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
  
  pskript = pname + "/scanner.sh";
  addScanners(root, (char*)pskript.c_str());

  // add hostname and username information
  addInfo(root);
  
 
  srand(time(NULL));
  string xmlfile;
  ostringstream i;
  i <<  "/tmp/run" << rand() << ".xml";
  xmlfile = i.str();

  //xmlSaveFile("-", dat.xml);
  xmlSaveFile( (char*) xmlfile.c_str(), dat.xml);
  return xmlfile;
}
