
#include "inc/SWindow.h"

#include "inc/functions.h"
#include <iostream>
#include <map>

#include <string.h>

#include "img/gnome_32.xpm"
#include "img/kde_32.xpm"
#include "img/linux_32.xpm"
#include "img/xp_32.xpm"
#include "img/xp_locked_32.xpm"
#include "img/xfce_32.xpm"
/* Added to support default icons */
#include "img/vmware_32.xpm"
#include "img/macos_32.xpm"
#include "img/bsd_32.xpm"
#include "img/gentoo_32.xpm"
#include "img/suse_32.xpm"
#include "img/ubuntu_32.xpm"


using namespace fltk;
using namespace std;


/********************************************************
 * default constructur for the main window
 * ----------------------------------------------------
 * if you want to use default sizes, call first ctor
 ********************************************************/
SWindow::SWindow(int w, int h, char* p)
: fltk::Window(w,h,p),
  go(w/3 + 10, h-40, (2*w)/3 - 20 , 30, "START"),
  exit_btn(10, h-40, w/3 -10, 30, "EXIT"),
  sel(10,10, w-20, h-50),
  ent(NULL),
  entgroup(NULL),
  lin_entgroup(NULL),
  lin_ent(NULL)
{
//  sel.indented(1);
  begin();
  add_resizable(sel);
  add(exit_btn);
  add(go);
  width = w;
  height = h;

  border(false);
  go.callback(cb_return,this);
  sel.callback(cb_select, this);
  exit_btn.callback(cb_exit, this);

  Style* btn_style = new Style(*fltk::ReturnButton::default_style);
  Style* sel_style = new Style(*fltk::Browser::default_style);



  Font* f1 = font("sans");
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

  const int widths[]   = { -1,-1,-1,-1, 0 };
  sel.column_widths(widths);

  end();
  sel.take_focus();
};


/********************************************************
 * Callback for ReturnButton at the bottom of the GUI
 * ----------------------------------------------------
 * Should start chosen session entry -> if something is selected
 *********************************************************/
void SWindow::cb_return()
{
  //if(!sel.item()) return;
  //curr = (Item*) sel.item();

  if(curr != 0 && curr->user_data()) {
    DataEntry* dat = (DataEntry*) curr->user_data();
    //cout << dat->short_description << endl;
    if(dat) {
      runImage(curr, dat);
    }
  }
}


/*******************************************************
 *  Callback for Selection-Browser in the center
 * ----------------------------------------------------
 * Starts the session if required -> Mouse Click
 *******************************************************/
void SWindow::cb_select()
{
  oldcurr = curr;
  curr = (Item*)  sel.item();
  if(!sel.item()) return;
  //cout << "cb_select called with" << sel.item() << endl;
  sel.select_only_this();
  if (sel.item_is_parent() )
    {
      sel.set_item_opened(true);
      return;
    }

  if( curr == oldcurr ) {
    // start image if it has data associated
    // -> double click
    //cout << ((DataEntry*)curr->user_data())->short_description << endl;
    if(curr->user_data()) {
      runImage(curr, (DataEntry*) curr->user_data() );
    }
    return;
  }
}


/**********************************************************
 * Put entries in a Linux-Session Group into Browser
 *********************************************************/
void SWindow::set_lin_entries(DataEntry** ent)
{
  this->lin_ent = ent;
  lin_entgroup = (ItemGroup*) sel.add_group("LINUX DESKTOP", &sel);
  map<string, DataEntry*> mapEntry;
  for (int i=0; ent[i] != '\0'; i++)
  {
    mapEntry.insert(make_pair(ent[i]->short_description, ent[i]));
  }
  map<string, DataEntry*>::iterator it= mapEntry.begin();
  for(;it!=mapEntry.end(); it++) {
//    Item* w= (Item*)sel.add_leaf(it->second->short_description.c_str() , lin_entgroup, (void*)it->second );
    Item* w= (Item*)lin_entgroup->add(it->second->short_description.c_str(), (void*)it->second );
    xpmImage* xpm = new xpmImage(get_symbol(it->second));
    ((Widget*) w)->image(xpm);
    w->tooltip(it->second->description.c_str());
    w->callback(&runImage, (void*)it->second);

  }
  lin_entgroup->end();
}


/**********************************************************
 * Put entries in a VMWARE-Session Group into Browser
 *********************************************************/
void SWindow::set_entries(DataEntry** ent)
{
  this->ent = ent;
  sort_entries();

  entgroup =  (ItemGroup*)sel.add_group("VMWARE SESSIONS", &sel);
  for (int i=0; ent[i] != '\0'; i++)
  {
    if(!ent[i]->active) continue;
    Item* w= (Item*)sel.add_leaf(ent[i]->short_description.c_str(), entgroup, (void*)ent[i] );

    xpmImage* xpm = new xpmImage(get_symbol(ent[i]));
    ((Widget*) w)->image(xpm);
    w->tooltip(ent[i]->description.c_str());
    w->callback(&runImage, (void*)ent[i]);

  }
  entgroup->end();

}

/**************************************************************
 * free arrays (which are dynamically allocated)
 **************************************************************/
void SWindow::free_entries()
{
  for (int i=0; ent[i] != '\0'; i++)
    {
      free(ent[i]);
    }
  free(ent);
}



/******************************************************
 * Small helper function to unfold the 2 parent groups
 *
 * ADDED: Now reads session from ~/.openslx/vmchooser via helper
 *
 * WARNING: this->ent and/or this->lin_ent
 *          has to assigned before         WARNING
 ******************************************************/
void SWindow::unfold_entries(bool lin_entries, bool vm_entries, char* defsession) {
  int ind = 0;
  if(lin_entries) {
    sel.goto_index(ind);
    if(sel.item_is_parent() ) {
      sel.set_item_opened(true);
    }
    ind++;
  }
  if(vm_entries) {
    sel.goto_index(ind);
    if(sel.item_is_parent() ) {
      sel.set_item_opened(true);
    }
  }

  if(! (lin_entries || vm_entries) ) {
    return;
  }
  sel.next_visible();
  sel.select_only_this(ind);
  curr = (Item*) sel.item();
  //sel.set_focus();
  //sel.set_item_selected(true,1);
  //sel.indented(false);

  char* prename = readSession();
  DataEntry* dp = NULL;
  if(defsession) {
	  prename = defsession;
  }
  if ( prename == '\0' ) {
    return;
  } else {
    sel.goto_index(0);
    Item* it = (Item*) sel.next();

    while( it ) {
	  dp = (DataEntry*) it->user_data();
	  if(!dp) {
		  it = (Item*) sel.next();
		  continue;
	  }
      if( dp->short_description.find(prename) != string::npos ) {
          sel.select_only_this(0);
          curr = it;
          return;
      }
      it = (Item*) sel.next();
    }
  }
}


/******************************************************
 * Helper function to get symbols for entries
 ******************************************************/
const char** SWindow::get_symbol(DataEntry* dat) {
  if(dat->imgtype == VMWARE) {
	if(dat->os.find("win") != string::npos || dat->os.find("Win") != string::npos) {
		if(dat->locked) {
			return xp_locked_32_xpm;
		}
		else {
			return xp_32_xpm;
		}
	}

	if(dat->icon.find("gentoo") != string::npos || dat->icon.find("Gentoo") != string::npos ) {
		return gentoo_32_xpm;
	}
	if(dat->icon.find("suse") != string::npos || dat->icon.find("Suse") != string::npos ) {
		return suse_32_xpm;
	}
	if(dat->icon.find("ubuntu") != string::npos || dat->icon.find("Ubuntu") != string::npos ) {
		return ubuntu_32_xpm;
	}
	if(dat->os.find("linux") != string::npos) {
		return linux_32_xpm;
	}
	if(dat->icon.find("bsd") != string::npos
			|| dat->icon.find("BSD") != string::npos
			|| dat->icon.find("Bsd") != string::npos) {
		return bsd_32_xpm;
	}
	if(dat->icon.find("mac") != string::npos
			|| dat->icon.find("Mac") != string::npos
			|| dat->icon.find("apple") != string::npos) {
		return macos_32_xpm;
	}

	return vmware_32_xpm;
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

  return linux_32_xpm;
}


/******************************************************
 * Sort entries to consider priorities
 *
 * -> puts smallest priority number on top
 ******************************************************/
void SWindow::sort_entries() {
  if(ent == '\0' ) {
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
