
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
  bool version = false;
  char* lsesspath = NULL;
  int width=0, height=0;
  
  opt->setVerbose();
  opt->autoUsagePrint(true);
  
  opt->addUsage("");
  opt->addUsage("SessionChooser Usage:");
  opt->addUsage("\t{-p |--path=} path to vmware (.xml) files");
  opt->addUsage("\t{-l |--lpath=} path to linux session (.desktop) files");
  opt->addUsage("\t{-s |--size=} [widthxheight]");
  opt->addUsage("\t{-v |--version} print out version");
  opt->addUsage("\t{-h |--help} prints help");
  opt->addUsage("");
  
  opt->setFlag("help",'h');
  opt->setFlag("version",'v');
  opt->setOption("path", 'p');
  opt->setOption("lpath", 'l');
  opt->setOption("size",'s');
  
  opt->processCommandArgs(argc, argv);
  
  /** HELP  */
  if(opt->getFlag("help") || opt->getFlag('h')) {
    opt->printUsage();
    return 0;
  }
  
  /** XML - PATH */
  if(opt->getValue('p')!=NULL) {
    xmlpath = opt->getValue('p');
  }
  if(opt->getValue("path")!= NULL) {
    xmlpath = opt->getValue("path");
  }
  if (xmlpath == NULL) {
    // Default Path comes here
    xmlpath = (char *) "/var/lib/vmware/vmconfigs/";
  }
 
  /* VERSION  */
  if(opt->getFlag('v') || opt->getFlag("version")) {
    version = true;
  }
  
  /** LINUX SESSION PATH */
  if(opt->getValue('l')!=NULL) {
    lsesspath = opt->getValue('l');
  }
  if(opt->getValue("lpath")!= NULL) {
    lsesspath = opt->getValue("lpath");
  }
  if (lsesspath == NULL) {
    lsesspath = (char *) "/usr/share/xsessions/";
  }
  
  /** Size of Window */
  string size;
  unsigned int i;
  
  if(opt->getValue('s')!=NULL) {
    size = opt->getValue('s');
  }
  if(opt->getValue("size")!= NULL) {
    size = opt->getValue("size");
  }
  
  if (size.empty()) {
    width = 500;
    height = 550;
  }
  else {
    i = size.find_first_of("x");
    if( i == string::npos) {
      cerr << "Please write <width>x<height> as argument for -s|--size." << endl;
      return 1;
    }
    height = atoi(size.substr(i+1).c_str());
    width = atoi(size.substr(0, size.size()-i).c_str());
  }
  
  delete opt;
 
  // just print out version information - helps testing
  cout << "virtual machine chooser 0.0.2"<< endl;
  if(version) {
    exit(1);
  }


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
  
  SWindow& win = *SWindow::getInstance(width, height);
  
  if(lsessions[0] != NULL) {
    win.set_lin_entries(lsessions);
  }
  if (sessions[0] != NULL) {
          win.set_entries(sessions);
  }
  
  //cout << win.pname << endl;

  
  win.unfold_entries();
  win.show(); // argc,argv
  win.border(false);

  bool retval = run();
  
  win.free_entries();
  
  return retval;
}

