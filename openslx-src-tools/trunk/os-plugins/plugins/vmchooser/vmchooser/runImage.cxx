#include <fltk/Widget.h>

#include "inc/DataEntry.h"
#include "inc/SWindow.h"
#include <sys/wait.h>
#include <iostream>

/** *************************************************************
 * void runImage runs a Image - building the commandline
 * 				and executes it using system()
 ***************************************************************/
void runImage(fltk::Widget*, void* p)
{
  /* printf("runImage called\n"); */
  if ( p == NULL ) {
    return;
  }
  
  DataEntry& dat = *((DataEntry*) p);
  
  string comm = buildCommand(dat);

  /* No command here - faulty session ?!? */
  if( comm.empty() ) {
    return;
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
      system( comm.c_str() );
      exit(0);
      break;
    default:
      if( waitpid( pid, &status, 0 ) == -1 ) {
        cerr << "No child with this pid (" << pid << ")" << endl;
      }
      else {
        exit(0);
      }
      break;
  }
}

/**
 * Helper-function for runImage(Widget, void) - builds the command
 **/
string buildCommand(DataEntry& dat)
{
  if (dat.imgtype == VMWARE) {
	// run-vmware.sh imagename os(Window-Title) network
	return string("/var/X11R6/bin/run-vmware.sh \"/var/lib/vmware/")
	.append(dat.imgname)
	.append("\" \"")
	.append(dat.os)
	.append("\" \"")
	.append(dat.network)
	.append("\"");
  }
  if(! dat.command.empty() ) {
    return dat.command;
  }
  return string();
}
