
#include "inc/SWindow.h"

#include <iostream>

#include <img/gnome_32.xpm>
#include <img/kde_32.xpm>
#include <img/linux_32.xpm>
#include <img/xp_32.xpm>
#include <img/xp_locked_32.xpm>
#include <img/xfce_32.xpm>


using namespace fltk;
using namespace std;


/********************************************************
 * default constructur for the main window
 * ----------------------------------------------------
 * if you want to set the size, call second ctor
 ********************************************************/
// SWindow::SWindow(char* p):
//       fltk::Window(fltk::USEDEFAULT,fltk::USEDEFAULT,500,550,p, true),
//       go(160, 520, 320, 20, "Ausführen"),
//       exit_btn(10, 520, 140, 20, "Abbrechen"),
//       sel(10,10, 480, 500)
// {
//   border(false);
//   go.callback(cb_return,this);
//   sel.callback(cb_select, this);
//   exit_btn.callback(cb_exit, this);
//     
//     // Array for width of Select-Columns 
//     // (one Column for a lock-symbol)
//   int widths[] = { 450, 20 };
//   sel.column_widths(widths);
//   resizable(sel);
//   end();
//     //sel.style(fltk::Browser::default_style);
//   sel.indented(1);
// };


/********************************************************
 * second constructur for the main window
 * ----------------------------------------------------
 * if you want to use default sizes, call first ctor
 ********************************************************/
SWindow::SWindow(int w, int h, char* p):
    fltk::Window(fltk::USEDEFAULT,fltk::USEDEFAULT,w,h,p, true),
    go(w/3 + 10, h-30, (2*w)/3 - 10 , 30, "Ausführen"),
    exit_btn(10, h-30, w/3 -10, 30, "Abbrechen"),
    sel(10,10, w-20, h-40)
{
  border(false);
  go.callback(cb_return,this);
  sel.callback(cb_select, this);
  exit_btn.callback(cb_exit, this);
    
    // Array for width of Select-Columns 
    // (one Column for a lock-symbol)
  
//   int v = w-20;
//   int widths[] = { (7*v)/8, v/8 };
//   sel.column_widths(widths);
//   resizable(sel);
  end();
  
  Style* btn_style = new Style(*fltk::ReturnButton::default_style);
  Style* sel_style = new Style(*fltk::Browser::default_style);
  
  
  sel.indented(1);
  
  Font* f1 = font("sans bold");
  //Font* f1bold = f1->bold();
  
  btn_style->textsize(16);
  btn_style->labelsize(16);
  btn_style->labelfont(f1);
  btn_style->textfont(f1);
  
  sel_style->textfont(f1);
  sel_style->textsize(16);
  
  exit_btn.style(btn_style);
  go.style(btn_style);
  sel.style(sel_style);
};


/********************************************************
 * Callback for ReturnButton at the bottom of the GUI
 * ----------------------------------------------------
 * Should start chosen session entry -> if something is selected
 *********************************************************/
void SWindow::cb_return()
{
  if(curr != 0 && curr->user_data()) {
    DataEntry* dat = (DataEntry*) curr->user_data();
    runImage(curr, dat);
  }
}


/*******************************************************
 *  Callback for Selection-Browser in the center
 * ----------------------------------------------------
 * Changes info-Text at the bottom
 *******************************************************/
void SWindow::cb_select()
{
  sel.select_only_this();
  if (sel.item_is_parent() )
    {
      sel.set_item_opened(true);
    }
  if( curr == sel.item() ) {
    //Doubleclick
    cout << ((DataEntry*)curr->user_data())->short_description << endl;
    if(curr->user_data()) {
      runImage(curr, (DataEntry*) curr->user_data() );
    }
    return;
  }
  curr = (Item*) sel.item();
//   if(curr->user_data()) {
//     DataEntry* dat = (DataEntry*) curr->user_data();
//     info.text(dat->description.c_str());
//   }
}


/**********************************************************
 * Put entries in a Linux-Session Group into Browser
 *********************************************************/
void SWindow::set_lin_entries(DataEntry** ent, char* slxgroup)
{
  this->lin_ent = ent;
  lin_entgroup = (ItemGroup*) sel.add_group("LINUX DESKTOP", &sel);

  for (int i=0; ent[i] != NULL; i++)
    {
      if( ent[i]->pools.empty() || ent[i]->pools.find(slxgroup) != string::npos) {
        Item* w= (Item*)sel.add_leaf(ent[i]->short_description.c_str() , lin_entgroup, (void*)ent[i] );
        
        xpmImage* xpm = new xpmImage(get_symbol(ent[i]));
        ((Widget*) w)->image(xpm);
        xpm->setsize(100,100);
        w->tooltip(ent[i]->description.c_str());
        w->callback(&runImage, (void*)ent[i]);
      }
    }

  lin_entgroup->end();
}


/**********************************************************
 * Put entries in a VMWARE-Session Group into Browser
 *********************************************************/
void SWindow::set_entries(DataEntry** ent, char* slxgroup)
{
  this->ent = ent;
  sort_entries();
  
  entgroup =  (ItemGroup*)sel.add_group("VMWARE SESSIONS", &sel);
  for (int i=0; ent[i] != NULL; i++)
    {
      if(ent[i]->pools.empty() || ent[i]->pools.find(slxgroup) != string::npos) {
        Item* w= (Item*)sel.add_leaf(ent[i]->short_description.c_str(), entgroup, (void*)ent[i] );
        
        xpmImage* xpm = new xpmImage(get_symbol(ent[i]));
        ((Widget*) w)->image(xpm);
        w->tooltip(ent[i]->description.c_str());
        w->callback(&runImage, (void*)ent[i]);
        
        xpm->setsize(100,100);
      }
    }

  entgroup->end();
}

/**************************************************************
 * free arrays (which are dynamically allocated)
 **************************************************************/
void SWindow::free_entries()
{
  for (int i=0; ent[i] != NULL; i++)
    {
      free(ent[i]);
    }
  free(ent);
}



/******************************************************
 * Small helper function to unfold the 2 parent groups
 ******************************************************/
void SWindow::unfold_entries() {
  sel.goto_index(0);
  if(sel.item_is_parent() ) {
    sel.set_item_opened(true);
  }
  sel.goto_index(1);
  if(sel.item_is_parent() ) {
    sel.set_item_opened(true);
  }
  sel.deselect();
}


/******************************************************
 * Helper function to get symbols for entries
 ******************************************************/
char** SWindow::get_symbol(DataEntry* dat) {
  if(dat->imgtype == VMWARE) {
    if(dat->locked) {
    	return xp_locked_32_xpm;
    }
    else {
    	return xp_32_xpm;
    }
  }
  if(dat->imgtype == LINUX) {
    if(dat->short_description.find("KDE")!= string::npos) {
    	return kde_32_xpm;
    }
    if(dat->short_description.find("GNOME")!= string::npos) {
      return gnome_32_xpm;
    }
    if(dat->short_description.find("Xfce")!= string::npos) {
      return xfce_32_xpm;
    }
    return linux_32_xpm;
  }
  return xp_32_xpm;
}


/******************************************************
 * Sort entries to consider priorities
 *
 * -> puts smallest priority number on top
 ******************************************************/
void SWindow::sort_entries() {
  if(this->ent == NULL ) {
    return;
  }
  DataEntry* ptr;
  
  // worst case sort - but it is enough for this few entries
  for(int i=0; ent[i] != '\0'; i++) {
    for(int j=0; ent[j] != '\0'; j++) {
      if(ent[j]->priority < ent[i]->priority && j > i) {
        // swap element i with j (as i is alway larger j)
        ptr = ent[i];
        ent[i] = ent[j];
        ent[j] = ptr;
      }
    }
  }
}
