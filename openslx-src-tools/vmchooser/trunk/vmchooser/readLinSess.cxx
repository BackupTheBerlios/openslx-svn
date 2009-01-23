
/**
 *
 * @author Bastian Wissler
 * @description: Scan a given folder for XML-Files and get information
 *	    about installed Images / SessionManagers
 */

#include <stdio.h>
#include <glob.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <fstream>
#include <iostream>

#include "inc/DataEntry.h"
#include "inc/functions.h"

static int errorfunc(const char* errpath, int errno)
{
        fprintf(stderr, "GLOB(): Fehler aufgetreten unter %s mit Fehlernummer %d \n",errpath, errno);
        return 0;
}


static glob_t* globber(char* path, const char* filetype)
{
        glob_t* gResult = (glob_t*) malloc(sizeof(glob_t));
        char* temp = (char*) malloc(strlen(path)+strlen(filetype)-1);
        strcpy(temp, path);
        strcat(temp, filetype);

        if (glob(temp, GLOB_NOSORT, &errorfunc, gResult)) {
                fprintf(stderr, "Fehler beim Öffnen des Ordners!\n");
                return NULL;
        }
        return gResult;

}

DataEntry** readLinSess(char* path)
{
	
	int MAX_LENGTH = 200;
	char line[MAX_LENGTH];
	char* found;
	char* val;
	
	if ( path== NULL) {
                return NULL;
        }
	glob_t *gResult = globber(path, "*.desktop");
	if ( gResult== NULL) {
                return NULL;
        }
        if ( gResult->gl_pathc == 0 ) {
                return NULL;
        }
        DataEntry** result = (DataEntry**) malloc(gResult->gl_pathc * sizeof(DataEntry*) +1);
        
        int c = 0;
        
        for (int i=0; gResult->gl_pathv[i] != NULL; i++) {
          if(string(gResult->gl_pathv[i]).find("default.desktop") != string::npos ) {
            continue;
          }
          
          ifstream desk(gResult->gl_pathv[i]);
          DataEntry* de = new DataEntry();
          de->imgtype = LINUX;
          while( desk.getline(line, MAX_LENGTH) ) {
                found = strstr(line, "Name=");
                if(found != NULL) {
                        val = strtok(found, "=");
                        val = strtok(NULL, "=");
                        de->short_description = string(val);
                }
                found = NULL;

                found = strstr(line, "Exec=");
                if(found != NULL) {
                        val = strtok(found, "=");
                        val = strtok(NULL, "=");
                        de->command = string(val);
                }
                found = NULL;

                found = strstr(line, "Comment=");
                if(found != NULL && de->description.empty()) {
                        val = strtok(found, "=");
                        val = strtok(NULL, "=");
                        de->description = string(val);
                }
                found = NULL;

                found = strstr(line, "Comment[de]=");
                if(found != NULL) {
                        val = strtok(found, "=");
                        val = strtok(NULL, "=");
                        de->description = string(val);
                }
                found = NULL;
          }
          
	  if(! (de->short_description.empty() || de->command.empty()) ) {
	  	result[c] = de;
		c++;
	  }
	  else {
		delete de;
	  } 
        }
        result[c] = NULL;
	
	return result;
}
