
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
 * ----------------------
 *
 *  main procedure of vmchooser
 *
 *
 *
 */
int main(int argc, char** argv)
{

        if (argc > 1 && !(strcmp(argv[1],"-h") | strcmp(argv[1], "--help")) ) {
		/* print help */
		printf("SessionChooser \n");
		printf("\t{-p |--path=}[path to vmware (.xml) files]\n");
		printf("\t{-l |--lpath=}[path to linux session (.desktop) files]\n");
		printf("\t{-g |--group=}[group name]\n");
		printf("\t{-h |--help}[ as first parameter - prints help ]\n");
		exit(0);
        }

        char* xmlpath = NULL;
        char* slxgroup = NULL;
        char* lsesspath = NULL;

        for (int i=0; i<argc; i++) {
                /* Get path parameter - path to XML files */
                if (strstr(argv[i],"-p") != NULL) {
                        i++;
                        xmlpath = argv[i];
                }
                if (strstr(argv[i],"--path=") != NULL) {
                        char* temp = strpbrk("=", argv[i] );
                        xmlpath = (temp ++);
                }
                
                /* Get path for linux sessions */
                if (strstr(argv[i],"-l") != NULL) {
                        i++;
                        lsesspath = argv[i];
                }
                if (strstr(argv[i],"--lpath=") != NULL) {
                        char* temp = strpbrk("=", argv[i] );
                        lsesspath = (temp ++);
                }

                /* Get group parameter - SLXGroup */
                if (strstr(argv[i],"-g") != NULL) {
                        i++;
                        slxgroup = argv[i];
                }
                if (strstr(argv[i],"--group=") != NULL) {
                        char* temp = strpbrk("=", argv[i] );
                        slxgroup =( temp ++ );
                }
        }

        if (xmlpath == NULL) {
        	xmlpath="../../../../../../../session-choosers/xml/";
                //xmlpath = "/var/lib/vmware/";
        }
        if (slxgroup == NULL) {
                slxgroup = "default";
        }
        if (lsesspath == NULL) {
                lsesspath = "/usr/share/xsessions/";
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
        
        SWindow& win = *SWindow::getInstance();
        
        if(lsessions != NULL) {
          win.set_lin_entries(lsessions, slxgroup);
        }
        if (sessions != NULL) {
                win.set_entries(sessions, slxgroup);
        }
        
        //cout << win.pname << endl;

	
	win.unfold_entries();
        win.show(argc,argv);
	win.border(false);

	bool retval = run();
	
	win.free_entries();
	
        return retval;
}

