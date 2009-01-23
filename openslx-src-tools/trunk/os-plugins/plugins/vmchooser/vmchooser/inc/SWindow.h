
#ifndef SWindow_h
#define SWindow_h

#include <fltk/Window.h>
#include <fltk/ReturnButton.h>
#include <fltk/Browser.h>
#include <fltk/TextDisplay.h>
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

  // Browser to select sessions
  fltk::Browser sel;

  // TextDisplay to display info about current session
  fltk::TextDisplay info;
  // TextBuffer buf is used for info
  fltk::TextBuffer buf;
  
  // currently selected Browser-Item
  fltk::Item* curr;

  // Two groups - Linux and VMWare
  fltk::ItemGroup* entgroup;
  fltk::ItemGroup* lin_entgroup;

  // Arrays with data from .xml and .desktop files
  DataEntry** ent;
  DataEntry** lin_ent;
  
  
  

  /**
   * ctor with some reasonable default values
   */
  SWindow(char* p = "Choose your session!") :
    fltk::Window(fltk::USEDEFAULT,fltk::USEDEFAULT,500,650,p, true),
    go(10,630, 490, 20, "Ausführen"),
    sel(10,10, 480, 500),
    info(10, 510, 480, 110),
    buf()
  {
    border(false);
    go.callback(cb_return,this);
    sel.callback(cb_select, this);
    
    
    // Array for width of Select-Columns 
    // (one Column for a lock-symbol)
    int widths[] = { 450, 20 };
    sel.column_widths(widths);
    info.callback(cb_info, this);
    resizable(sel);
    end();
    
    info.wrap_mode(true, 0);
    //sel.style(fltk::Browser::default_style);
    sel.indented(1);
    
    /* Getting foldername of the pictures - obsolete ? */
//    pathsize = 200;
    
    /* Var for the folder name */
//     pname = (char*) malloc(pathsize);
//     int result;
//     
//     result = readlink("/proc/self/exe", pname, pathsize);
//     if (result > 0) {
//       pname[result] = 0; /* add the NULL - not from readlink */
//     }
  };

public:
  static SWindow* getInstance() {
    static SWindow instance;
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
  static void cb_info(fltk::Widget*, void* w) {
    ((SWindow*)w)->cb_info();
  };

  void cb_return();
  void cb_select();
  void cb_info();

  void set_entries(DataEntry** ent, char* slxgroup);
  void set_lin_entries(DataEntry** ent, char* slxgroup);
  
  char** get_symbol(DataEntry* dat);

  void free_entries();
  void unfold_entries();

};


#endif

