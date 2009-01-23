#ifndef _FUNCTIONS_H_
#define _FUNCTIONS_H_

#include <fltk/Widget.h>

#include <glob.h>

#include "DataEntry.h"

DataEntry** readXmlDir(char* path); /* Attention: returns malloced array */
DataEntry** readLinSess(char* path);

void runImage(fltk::Widget* , void* p); /* This is thought as a callback-function for the Select-Browser */
string runImage(DataEntry&); /* building command for different Virtualizer */

glob_t* globber(char* path, char* filetype); /* Globs for a specific filetype */


#endif /* _FUNCTIONS_H_ */

