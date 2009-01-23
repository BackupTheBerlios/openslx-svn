
#ifndef SWindow_h
#define SWindow_h

#include <fltk/Window.h>
#include <fltk/ReturnButton.h>
#include <fltk/Browser.h>
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
    fltk::Window(fltk::USEDEFAULT,fltk::USEDEFAULT,500,550,p, true),
    go(160, 520, 320, 20, "Ausführen"),
    exit_btn(10, 520, 140, 20, "Abbrechen"),
    sel(10,10, 480, 500)
  {
    border(false);
    go.callback(cb_return,this);
    sel.callback(cb_select, this);
    exit_btn.callback(cb_exit, this);
    
    // Array for width of Select-Columns 
    // (one Column for a lock-symbol)
    int widths[] = { 450, 20 };
    sel.column_widths(widths);
    resizable(sel);
    end();
    //sel.style(fltk::Browser::default_style);
    sel.indented(1);
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
  
  static void cb_exit(fltk::Widget*, void* w) {
    exit(0);
  }

  void cb_return();
  void cb_select();

  void set_entries(DataEntry** ent, char* slxgroup);
  void set_lin_entries(DataEntry** ent, char* slxgroup);
  
  char** get_symbol(DataEntry* dat);

  void free_entries();
  void unfold_entries();
  
  void sort_entries();

};


#endif

