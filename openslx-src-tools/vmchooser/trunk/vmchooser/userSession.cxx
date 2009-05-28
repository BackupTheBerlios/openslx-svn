


#include "inc/DataEntry.h"
#include "inc/functions.h"

#include <cstdlib>
#include <cstring>
#include <string>
#include <iostream>
#include <fstream>
#include<boost/filesystem/operations.hpp>

namespace bfs=boost::filesystem;
using namespace std;

/**
 * @function saveSession: Saves chosen session to prechoose this session next time.
 *
 * @param dat: Pointer to the wanted Image/Linux Session
 * @return void
 *
 */
void saveSession(DataEntry* dat) {

    // get home folder
    char* home = getenv("HOME");
    if(home == NULL) {
        cout << "HOME is not set. Not storing session." << endl;
        return;
    }

    // build path
    string fname = home;
    string shome = home;
    fname.append("/.openslx/vmchooser");
    if(!bfs::exists(fname) ) {
        if(!bfs::exists(shome.append("/.openslx")) ) {
            bfs::create_directory(shome);
        }
    }

    // write file with ofstream
    ofstream fout(fname.c_str(),ios::trunc); // overwrite file
    fout << dat->short_description << endl;
}



/**
 * @function readSession: Read predefined session from users home folder
 * 
 * @return: if not found, return null, else description for Image XML/ Linux .desktop file
 */
char* readSession() {

    // read HOME variable
    char* home = getenv("HOME");
    if(home==NULL) {
        cout << "HOME is not set. Not reading session." << endl;
        return NULL;
    }

    // build file name
    string fname = home;
    fname.append("/.openslx/vmchooser");

    // read presaved session with ifstream
    if(!bfs::exists(fname)) {
        return NULL;
    }
    ifstream fin(fname.c_str());
    if (!fin) {
      cout << "some error occured reading file!" << endl;
      return NULL;
    }

    string sessname;
    getline(fin,sessname);
    char* blub = (char*) malloc(sessname.size()+1);
    strncpy(blub,sessname.c_str(),sessname.size()+1);

    if(!sessname.empty()) {
        // blub has to be freed ;-) 
        // but this is not very important here - or is it?
        return blub;
    }
    else {
        free(blub);
        return NULL;
    }

}
