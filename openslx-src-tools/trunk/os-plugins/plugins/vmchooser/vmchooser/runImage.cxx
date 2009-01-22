#include <fltk/Widget.h>

#include "inc/DataEntry.h"
#include "inc/SWindow.h"


void runImage(fltk::Widget*, void* p)
{
  if ( p == NULL )
    {
      return;
    }
  DataEntry& dat = *((DataEntry*) p);
  SWindow& win = *SWindow::getInstance();

  if (! dat.command.empty())
    {
      system(dat.command.c_str());
      win.hide();
    }
  exit(0);
}


string buildCommand(DataEntry& dat)
{
  if (dat.imgtype == VMWARE)
    {
      return string("vmrun ").append(dat.imgname);
    }
  return string();
}
