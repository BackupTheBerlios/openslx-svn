#include <fltk/Widget.h>

#include "inc/DataEntry.h"
#include "inc/SWindow.h"
#include <sys/wait.h>
#include <iostream>
#include <string>
#include <boost/regex.hpp>

/** *************************************************************
 * void runImage runs a (virtual machine) image using fork()
 ***************************************************************/
void runImage(fltk::Widget*, void* p)
{
  /* printf("runImage called\n"); */
  if ( p == NULL ) {
    return;
  }
  
  DataEntry& dat = *((DataEntry*) p);
  
  pid_t pid;
  int status;
  pid = fork();

  switch( pid )  {
    case -1:
      cout << "Something went wrong while forking!" << endl;
      return;
      break;
    case 0:
      runImage(dat);
      break;
    default:
      exit(0);
      if( waitpid( pid, &status, 0 ) == -1 ) {
        cerr << "No child with this pid (" << pid << ")" << endl;
        return;
      }
      else {
        exit(0);
      }
      break;
  }
}

/**
 * Helper-function for runImage(Widget, void) 
 * - runs the chosen virtualizer image
 **/
string runImage(DataEntry& dat)
{
  if (dat.imgtype == VMWARE) {
  	char* arg[] = { strcat("/var/lib/vmware/",dat.imgname.c_str()),
		(char*) dat.os.c_str(),
		(char*)dat.network.c_str(), '\0' };
	// run-vmware.sh imagename os (Window-Title) network
	execvp("/var/X11R6/bin/run-vmware.sh", arg );
  }
  if(! dat.command.empty() ) {
    execvp((char*) dat.command.c_str(), NULL);
  }
  return string();
}
