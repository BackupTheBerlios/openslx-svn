
#include <fltk/run.h>

#include <iostream>
#include <stdlib.h>
#include "inc/SWindow.h"
#include "inc/DataEntry.h"
#include "inc/functions.h"
#include "inc/anyoption.h"

#include <libxml/parser.h>
#include <libxml/tree.h>
#include <libxml/xpath.h>

using namespace std;
using namespace fltk;

// defined in readXmlDir.h
extern DataEntry* get_entry(xmlDoc * doc);

SWindow* mainwin;
/**
 * MAIN
 *
 * ----------------------
 *
 *  main function of vmchooser
 *
 *
 *
 */
int main(int argc, char** argv) {
  AnyOption* opt = new AnyOption();
  char* xmlpath = NULL;
  char* lsesspath = NULL;
  int width=0, height=0;

  //opt->setVerbose();
  opt->autoUsagePrint(false);

  opt->addUsage("");
  opt->addUsage("SessionChooser Usage: vmchooser [OPTS|image.xml]");
  opt->addUsage("\t{-p |--path=} path to vmware (.xml) files");
  opt->addUsage("\t{-l |--lpath=} path to linux session (.desktop) files");
  opt->addUsage("\t{-s |--size=} [widthxheight]");
  opt->addUsage("\t{-v |--version} print out version");
  opt->addUsage("\t{-h |--help} prints help");
  opt->addUsage("");
  opt->addUsage("Run with xml-file as additional argument to start image at once.");

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

  /**
   * 	XML - PATH
   *
   *	1. read from stage3.conf
   *	2. option -p
   *	3. option --path
   *	4. default value "/var/lib/virt/vmware/"
   *
   **/

  ifstream ifs ( "/etc/opt/openslx/vmchooser-stage3.conf" , ifstream::in );
  if(ifs) {
	  int n = 255;
	  char buf[n];
	  string s = "";
	  while(!ifs.eof()) {
		  ifs.getline(buf, n);
		  s = buf;
		  if(s.substr(0,17) == "vmchooser_xmlpath") {
			  xmlpath = (char*)strdup(s.substr(19,s.length()-20).append("/").c_str());
		  }
	  }

  }

  if(opt->getValue('p')!=NULL) {
    xmlpath = opt->getValue('p');
  }

  if(opt->getValue("path")!= NULL) {
    xmlpath = opt->getValue("path");
  }

  if (xmlpath == NULL) {
    // Default Path comes here
    xmlpath = (char *) "/var/lib/virt/vmware/";
  }

  /* VERSION  */
  if(opt->getFlag('v') || opt->getFlag("version")) {
    // just print out version information - helps testing
    cout << "virtual machine chooser 0.0.10"<< endl;
    delete opt;
    return 0;

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


  // additional xml argument -> start image directly
  if(opt->getArgc() > 0) {
    // read xml image
    xmlDoc* doc = xmlReadFile(opt->getArgv(0), NULL, XML_PARSE_RECOVER);
    if (doc == NULL) {
      fprintf(stderr, "Error: could not parse file %s\n", opt->getArgv(0));
      return 1;
    }

    DataEntry* result = get_entry(doc);
    runImage(*result, opt->getArgv(0));
  }

  delete opt;


  /* read xml files */
  DataEntry** sessions = NULL;
  DataEntry** lsessions = NULL;
  sessions = readXmlDir(xmlpath);
  lsessions = readLinSess(lsesspath);

  SWindow& win = *SWindow::getInstance(width, height);
  mainwin = &win;
  bool lin_entries=false;
  bool vm_entries=false;

  if(lsessions != NULL) {
    win.set_lin_entries(lsessions);
    lin_entries = true;
  }
  if (sessions != NULL) {
    win.set_entries(sessions);
    vm_entries = true;
  }

  win.unfold_entries(lin_entries, vm_entries);
  win.show(); // argc,argv
  win.border(false);
  free(xmlpath);

  bool retval = run();

  win.free_entries();

  return retval;
}

