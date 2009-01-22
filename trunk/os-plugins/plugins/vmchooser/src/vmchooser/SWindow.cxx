
#include "inc/SWindow.h"
#include <iostream>

using namespace fltk;
using namespace std;

void SWindow::cb_return()
{
  // TODO start something
  cout << " Pressed Button!" << endl;
}


void SWindow::cb_select()
{
  if (sel.item_is_parent() )
    {
      sel.set_item_opened(true);
    }
}


void SWindow::cb_info()
{
}

void SWindow::set_lin_entries(DataEntry** ent)
{
  this->lin_ent = ent;
  lin_entgroup = (ItemGroup*) sel.add_group("------- LINUX DESKTOP ------");
  for (int i=0; ent[i] != NULL; i++)
    {
      sel.add_leaf(ent[i]->short_description.c_str() , lin_entgroup, (void*)ent[i] );
    }

  lin_entgroup->end();
}

void SWindow::set_entries(DataEntry** ent)
{
  this->ent = ent;

  entgroup =  (ItemGroup*)sel.add_group("-------- VMWARE ----------");
  for (int i=0; ent[i] != NULL; i++)
    {
      sel.add_leaf(ent[i]->short_description.c_str(), lin_entgroup, (void*)ent[i] );
    }
  for (int c=0; c < 5; c++) 
    {
      sel.add_leaf("Blubber 1", entgroup);
    }
  entgroup->end();
}


void SWindow::free_entries()
{
  for (int i=0; ent[i] != NULL; i++)
    {
      free(ent[i]);
    }
  free(ent);
}

