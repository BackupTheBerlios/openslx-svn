#ifndef _FUNCTIONS_H_
#define _FUNCTIONS_H_

#include <fltk/Widget.h>

#include <glob.h>

#include "DataEntry.h"

/* Attention: both return malloced array */
DataEntry** readXmlDir(char* path);
DataEntry** readLinSess(char* path);

/* This is thought as a callback-function for the Select-Browser */
void runImage(fltk::Widget* , void* p);

/* building & executing command for different Virtualizer */
string runImage(DataEntry&, string confxml);

/* Globs for a specific filetype (2. argument) */
glob_t* globber(char* path, char* filetype);

/* Gets folder name of this program */
char* getFolderName();

/* Reads output from a skript (2. argument) */
/* Adds the elements into xmlNode "printers" (1. argument) */
bool addPrinters(xmlNode* node, char* script); 
bool addScanners(xmlNode* node, char* script); 
void addInfo(xmlNode* node); /* This is defined in addPrinters.cxx */

/* Write configuration xml */
string writeConfXml(DataEntry& dat);



/** Extra functions - defined in userSession.cxx */
void saveSession(DataEntry* dat);
char* readSession(void);


#endif /* _FUNCTIONS_H_ */

