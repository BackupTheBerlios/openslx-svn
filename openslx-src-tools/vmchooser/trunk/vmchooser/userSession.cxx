


#include "inc/DataEntry.h"
#include "inc/functions.h"

#include <cstdlib>
#include <cstring>
#include <string>
#include <iostream>
#include <fstream>

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
    fname.append("/.vmchooser");

    // write file with ofstream
    ofstream fout(fname.c_str(),ios::trunc); // overwrite file
    fout << dat->short_description << endl;
}



/**
 * @function readSession: Read predefined session from users home folder
 * 
 * @return: if not found, return null, else filename for Image XML/ Linux .desktop file
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
    fname.append("/.vmchooser");

    // read presaved session with ifstream
    ifstream fin(fname.c_str());
    if (!fin) {
      cout << ".vmchooser file not found .. continue with global default" << endl;
      return NULL;
    }
    string sessname;
    getline(fin,sessname);
    char* blub = (char*) malloc(sessname.size());
    strncpy(blub,sessname.c_str(),sessname.size()+1);

    if(!sessname.empty()) {
        return blub;
    }
    else {
        return NULL;
    }

}
