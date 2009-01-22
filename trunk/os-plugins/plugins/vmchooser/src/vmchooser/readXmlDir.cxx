/**
 * author: Bastian Wissler
 * purpose: Scan a given folder for XML-Files and get information
 *	    about installed Images / SessionManagers
 */
#include <stdio.h>
#include <glob.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <libxml/parser.h>
#include <libxml/tree.h>

#include "inc/DataEntry.h"


#ifdef LIBXML_TREE_ENABLED

char* getAttribute(xmlNode* from, char* name)
{
  xmlNode* temp;
  for (temp = from->children;temp != NULL; temp = from->next)
    {
      if (temp->type == XML_ELEMENT_NODE && strcmp((const char*) temp->name, name)  )
        {
          return (char*) xmlGetProp(temp, (const xmlChar*) "param");
        }
      else
        {
          continue;
        }
    }
  return NULL;
}

DataEntry* get_entry(xmlNode * root)
{
  xmlNode *eintrag = NULL;
  char *tempc = NULL;
  DataEntry* de = (DataEntry*) malloc( sizeof(DataEntry) );

  eintrag = root->children;

  if (eintrag == NULL )
    {
      fprintf(stderr, "Out of memory!\n");
      return NULL;
    }
  if (! strcmp((const char*) eintrag->name, "eintrag") )
    {
      fprintf(stderr, "Didn't find \"eintrag\"-element!");
      return NULL;
    }
  tempc = (char*) getAttribute(eintrag,"short_description");
  if (tempc != NULL )
    {
      de->short_description = tempc;
    }
  tempc = NULL;

  if (de->short_description.empty())
    {
      free(de);
      fprintf(stderr, "No short_description given\n");
      return NULL;
    }

  tempc = getAttribute(eintrag,"long_description");
  if (tempc != NULL )
    {
      de->description = tempc;
    }
  tempc = NULL;

  tempc = getAttribute(eintrag,"creator");
  if (tempc != NULL )
    {
      de->creator = tempc;
    }
  tempc = NULL;

  tempc = getAttribute(eintrag,"email");
  if (tempc != NULL )
    {
      de->email = tempc;
    }
  tempc = NULL;

  tempc = getAttribute(eintrag,"phone");
  if (tempc != NULL )
    {
      de->phone = tempc;
    }
  tempc = NULL;

  tempc = getAttribute(eintrag,"name");
  if (tempc != NULL )
    {
      de->imgname = tempc;
    }
  tempc = NULL;

  tempc = getAttribute(eintrag,"os");
  if (tempc != NULL )
    {
      de->os = tempc;
    }
  tempc = NULL;

  tempc = getAttribute(eintrag,"network");
  if (tempc != NULL )
    {
      de->network = tempc;
    }
  tempc = NULL;

  tempc = getAttribute(eintrag,"virtualmachine");
  if (tempc != NULL )
    {
      if ( strcmp(tempc,"vmware") )
        {
          de->imgtype = VMWARE;
        }
      else
        {
          de->imgtype = VBOX;
        }
    }
  tempc = NULL;

  tempc = getAttribute(eintrag,"active");
  if (tempc != NULL )
    {
      de->active = (strstr(tempc,"true")!= NULL?true:false);
    }
  tempc = NULL;

  tempc = getAttribute(eintrag,"pools");
  if (tempc != NULL )
    {
      de->pools = tempc;
    }
  tempc = NULL;

  tempc = getAttribute(eintrag,"xdm");
  if (tempc != NULL )
    {
      de->xdm = tempc;
    }
  tempc = NULL;

  tempc = getAttribute(eintrag,"priority");
  if (tempc != NULL )
    {
      de->priority = atoi(tempc);
    }
  tempc = NULL;

  return de;
}

static int errorfunc(const char* errpath, int errno)
{
  fprintf(stderr, "GLOB(): Fehler aufgetreten unter %s mit Fehlernummer %d \n",errpath, errno);
  return 0;
}


static glob_t* globber(char* path, const char* filetype)
{
  glob_t* gResult = (glob_t*) malloc(sizeof(glob_t));
  char* temp = (char*) malloc(strlen(path)+strlen(filetype)-1);
  strcpy(temp, path);
  strcat(temp, filetype);

  if (glob(path, GLOB_NOSORT, &errorfunc, gResult))
    {
      fprintf(stderr, "Fehler beim öffnen des Ordners!\n");
      return NULL;
    }
  return gResult;

}


DataEntry** readXmlDir(char* path)
{
  LIBXML_TEST_VERSION
  if ( path== NULL)
    {
      return NULL;
    }
  glob_t *gResult = globber(path, "/*.xml");

  if ( gResult == NULL )
    {
      return NULL;
    }

  if ( gResult->gl_pathc == 0 )
    {
      return NULL;
    }
  xmlDoc *doc = NULL;
  xmlNode *root_element = NULL;
  int c = 0;

  DataEntry** result = (DataEntry**) malloc(gResult->gl_pathc * sizeof(DataEntry*) +1);

  for (int i=0; gResult->gl_pathv[i] != NULL; i++)
    {
      if (strstr(gResult->gl_pathv[i], "Vorlage") != NULL)
        {
          continue;
        }
      /* DEBUG */
      /* printf("%s\n", gResult->gl_pathv[i]);
       */
      struct stat m;
      stat(gResult->gl_pathv[i], &m);

      if ( S_ISDIR(m.st_mode) )
        {
          continue;
        }

      doc = xmlReadFile(gResult->gl_pathv[i], NULL, XML_PARSE_RECOVER);
      if (doc == NULL)
        {
          fprintf(stderr, "error: could not parse file %s\n", gResult->gl_pathv[i]);
          continue;
        }

      root_element = xmlDocGetRootElement(doc);
      if (!root_element)
        {
          fprintf(stderr, "Some error regarding reading of xml file!");
          exit(1);
        }

      result[c] = get_entry(root_element);
      if (result[c] != NULL)
        {
          c++;
        }
      xmlFreeDoc(doc);
    }

  free(gResult);
  result[c] = NULL;
  return result;

}

#else

#error "Tree Support for libxml2 must be available!"

#endif
