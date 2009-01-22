
#include <fltk/run.h>

#include <iostream>
#include <stdlib.h>
#include "inc/SWindow.h"
#include "inc/DataEntry.h"
#include "inc/functions.h"

using namespace std;
using namespace fltk;

/**
 * MAIN
 *
 */
int main(int argc, char** argv)
{

  if (argc > 1 )
    {
      if (strcmp(argv[1],"-h") | strcmp(argv[1], "--help") )
        {
          /* print help */
          printf("SessionChooser \n");
          printf("\t{-p |--path=}[path to xml files]\n");
          printf("\t{-g |--group=}[group name]\n");
          printf("\t{-h |--help}[ as first parameter - prints help ]\n");
          exit(0);
        }
    }

  char* xmlpath = NULL;
  char* slxgroup = NULL;

  for (int i=0; i<argc; i++)
    {
      /* Get path parameter - path to XML files */
      if (strstr(argv[i],"-p") != NULL)
        {
          i++;
          xmlpath = argv[i];
        }
      if (strstr(argv[i],"--path=") != NULL)
        {
          char* temp = strpbrk("=", argv[i] );
          xmlpath = (temp ++);
        }

      /* Get group parameter - SLXGroup */
      if (strstr(argv[i],"-g") != NULL)
        {
          i++;
          slxgroup = argv[i];
        }
      if (strstr(argv[i],"--group=") != NULL)
        {
          char* temp = strpbrk("=", argv[i] );
          slxgroup =( temp ++ );
        }
    }

  if (xmlpath == NULL)
    {
      xmlpath = "xmltest";
    }
  if (slxgroup == NULL)
    {
      slxgroup = "default";
    }


  /* read xml files */
  DataEntry** sessions = NULL;
  if (xmlpath != NULL)
    {
      sessions = readXmlDir(xmlpath);
    }
  else
    {
      fprintf(stderr,"Please give a path to xml directory for session images!");
      exit(1);
    }

  SWindow& win = *SWindow::getInstance();

  if (sessions != NULL)
    {
      win.set_entries(sessions);
    }

  win.show(argc,argv);

  return run();
}

