
#ifndef SWindow_h
#define SWindow_h

#include <fltk/Window.h>
#include <fltk/ReturnButton.h>
#include <fltk/Browser.h>
#include <fltk/Font.h>
//#include <fltk/TextDisplay.h>
#include <fltk/ItemGroup.h>
#include <fltk/Item.h>
#include <fltk/SharedImage.h>
#include <fltk/Image.h>
#include <fltk/xpmImage.h>


#include "DataEntry.h"
#include "functions.h"
#include <map>
#include <unistd.h>
#include <iostream>

class SWindow : public fltk::Window {

private:
  // ReturnButton to start the session
  fltk::ReturnButton go;
  
  // Button to exit
  fltk::Button exit_btn;

  // Browser to select sessions
  fltk::Browser sel;

  // currently selected Browser-Item
  fltk::Item* curr;
  fltk::Item* oldcurr;

  // Two groups - Linux and VMWare
  fltk::ItemGroup* entgroup;
  fltk::ItemGroup* lin_entgroup;

  // Arrays with data from .xml and .desktop files
  DataEntry** ent;
  DataEntry** lin_ent;
  
  
  int width;
  int height;
  
  
  

  /**
   * ctor with some reasonable default values
   */
  //SWindow(char* p = "Choose your session!");
  SWindow(int w, int h, char* p = (char *) "Choose your session!");

public:
  static SWindow* getInstance(int w, int h) {
    static SWindow instance(w,h);
    return &instance;
  }
  
  
  int pathsize;
  char* pname; /* Holds the current absolute path */

  ~SWindow() { };

  static void cb_return(fltk::Widget*, void* w) {
    ((SWindow*)w)->cb_return();
  };
  static void cb_select(fltk::Widget*, void* w) {
    ((SWindow*)w)->cb_select();
  };
  
  static void cb_exit(fltk::Widget*, void* w) {
    exit(0);
  }

  void cb_return();
  void cb_select();

  void set_entries(DataEntry** ent);
  void set_lin_entries(DataEntry** ent);
  
  const char** get_symbol(DataEntry* dat);

  void free_entries();
  void unfold_entries(bool,bool);
  
  void sort_entries();

};


#endif

