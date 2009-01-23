
#include "inc/SWindow.h"

#include <iostream>

#include <img/gnome.xpm>
#include <img/kde.xpm>
#include <img/linux.xpm>
#include <img/xp.xpm>
#include <img/xp_locked.xpm>


using namespace fltk;
using namespace std;

/********************************************************
 * Callback for ReturnButton at the bottom of the GUI
 * ----------------------------------------------------
 * Should start chosen session entry
 *********************************************************/
void SWindow::cb_return()
{
  //cout << " Pressed Button!" << endl;
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
    if(curr->user_data()) {
      runImage(curr, (DataEntry*) curr->user_data() );
    }
    return;
  }
  curr = (Item*) sel.item();
  //cout << it->user_data() << endl;
  if(curr->user_data()) {
    DataEntry* dat = (DataEntry*) curr->user_data();
    info.text(dat->description.c_str());
  }
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
        
        // Why is just "new" working here ???
        ((Widget*) w)->image(new xpmImage(get_symbol(ent[i])));
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

  entgroup =  (ItemGroup*)sel.add_group("VMWARE SESSIONS", &sel);
  for (int i=0; ent[i] != NULL; i++)
    {
      if(ent[i]->pools.empty() || ent[i]->pools.find(slxgroup) != string::npos) {
        Item* w= (Item*)sel.add_leaf(ent[i]->short_description.c_str(), entgroup, (void*)ent[i] );
        
        // Why is just "new" working here ??
        ((Widget*) w)->image(new xpmImage(get_symbol(ent[i])));
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
    	return xp_locked_xpm;
    }
    else {
    	return xp_xpm;
    }
  }
  if(dat->imgtype == LINUX) {
    if(dat->short_description.find("KDE")!= string::npos) {
    	return kde_xpm;
    }
    if(dat->short_description.find("GNOME")!= string::npos) {
    	return gnome_xpm;
    }
    return linux_xpm;
  }
  return linux_xpm;
}
