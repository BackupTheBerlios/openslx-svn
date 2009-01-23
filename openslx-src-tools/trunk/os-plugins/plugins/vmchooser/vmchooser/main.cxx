
#include <fltk/run.h>

#include <iostream>
#include <stdlib.h>
#include "inc/SWindow.h"
#include "inc/DataEntry.h"
#include "inc/functions.h"
#include "inc/anyoption.h"

using namespace std;
using namespace fltk;


/**
 * MAIN
 *
 * ----------------------
 *
 *  main procedure of vmchooser
 *
 *
 *
 */
int main(int argc, char** argv) {
  AnyOption* opt = new AnyOption();
  char* xmlpath = NULL;
  char* slxgroup = NULL;
  char* lsesspath = NULL;
  
  opt->setVerbose();
  opt->autoUsagePrint(true);
  
  opt->addUsage("");
  opt->addUsage("SessionChooser Usage:");
  opt->addUsage("\t{-p |--path=} path to vmware (.xml) files");
  opt->addUsage("\t{-l |--lpath=} path to linux session (.desktop) files");
  opt->addUsage("\t{-g |--group=} group name");
  opt->addUsage("\t{-h |--help} prints help");
  opt->addUsage("");
  
  opt->setFlag("help",'h');
  opt->setOption("path", 'p');
  opt->setOption("lpath", 'l');
  opt->setOption("group",'g');
  
  opt->processCommandArgs(argc, argv);
  
  /** HELP  */
  if(opt->getFlag("help") || opt->getFlag('h')) {
    opt->printUsage();
    return 1;
  }
  
  /** XML - PATH */
  if(opt->getValue('p')!=NULL) {
    xmlpath = opt->getValue('p');
  }
  if(opt->getValue("path")!= NULL) {
    xmlpath = opt->getValue("path");
  }
  if (xmlpath == NULL) {
    //xmlpath="../../../../../../../session-choosers/xml/";
    xmlpath = "/var/lib/vmware/";
  }
  
  /** SLX GROUP */
  if(opt->getValue('g')!=NULL) {
    slxgroup = opt->getValue('g');
  }
  if(opt->getValue("group")!= NULL) {
    slxgroup = opt->getValue("group");
  }
  if (slxgroup == NULL) {
    slxgroup = "default";
  }
  
  /** LINUX SESSION PATH */
  if(opt->getValue('l')!=NULL) {
    lsesspath = opt->getValue('l');
  }
  if(opt->getValue("lpath")!= NULL) {
    lsesspath = opt->getValue("lpath");
  }
  if (lsesspath == NULL) {
    lsesspath = "/usr/share/xsessions/";
  }
  
  delete opt;
  
  /* read xml files */
  DataEntry** sessions = NULL;
  DataEntry** lsessions = NULL;
  if (xmlpath != NULL) {
          sessions = readXmlDir(xmlpath);
  } else {
          fprintf(stderr,"Please give a path to xml directory for session images!");
          exit(1);
  }
  lsessions = readLinSess(lsesspath);
  
  SWindow& win = *SWindow::getInstance();
  
  if(lsessions != NULL) {
    win.set_lin_entries(lsessions, slxgroup);
  }
  if (sessions != NULL) {
          win.set_entries(sessions, slxgroup);
  }
  
  //cout << win.pname << endl;

  
  win.unfold_entries();
  win.show(); // argc,argv
  win.border(false);

  bool retval = run();
  
  win.free_entries();
  
  return retval;
}

