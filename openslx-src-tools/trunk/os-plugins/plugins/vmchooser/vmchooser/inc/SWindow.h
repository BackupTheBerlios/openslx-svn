
#ifndef SWindow_h
#define SWindow_h

#include <fltk/Window.h>
#include <fltk/ReturnButton.h>
#include <fltk/MultiBrowser.h>
#include <fltk/TextDisplay.h>
#include <fltk/ItemGroup.h>

#include "DataEntry.h"
#include <map>

class SWindow : public fltk::Window {

private:

  fltk::ReturnButton go;
  fltk::MultiBrowser sel;
  fltk::TextDisplay info;
  fltk::TextBuffer buf;

  fltk::ItemGroup* entgroup;
  fltk::ItemGroup* lin_entgroup;

  DataEntry** ent;
  DataEntry** lin_ent;
  SWindow(char* p = "Choose your session!") :
    fltk::Window(fltk::USEDEFAULT,fltk::USEDEFAULT,500,650,p, true),
    go(10,630, 490, 20, "Ausführen"),
    sel(10,10, 480, 500),
    info(10, 510, 480, 110),
    buf()
  {
    go.callback(cb_return,this);
    sel.callback(cb_select, this);
    info.callback(cb_info, this);
    end();
  };

public:
  static SWindow* getInstance() {
    static SWindow instance;
    return &instance;
  }

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

  void set_entries(DataEntry** ent);
  void set_lin_entries(DataEntry** ent);

  void free_entries();

};


#endif

