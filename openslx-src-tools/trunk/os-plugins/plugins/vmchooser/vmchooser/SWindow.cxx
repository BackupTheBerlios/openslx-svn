
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

/**
 * Callback for TextDisplay at the bottom - change it?
 */
void SWindow::cb_info()
{
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
        
        ((Widget*) w)->image(new xpmImage(get_symbol(ent[i])));
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
 ******************************************************/
void SWindow::sort_entries() {
  if(this->ent == NULL ) {
    return;
  }
  DataEntry* ptr;
  
  // worst case sort - but it is enough for this few entries
  for(int i=0; ent[i] != '\0'; i++) {
    for(int j=0; ent[j] != '\0'; j++) {
      if(ent[j]->priority > ent[i]->priority && j>i) {
        // swap element i with j (as i is alway larger j)
        ptr = ent[i];
        ent[i] = ent[j];
        ent[j] = ptr;
      }
    }
  }
}
