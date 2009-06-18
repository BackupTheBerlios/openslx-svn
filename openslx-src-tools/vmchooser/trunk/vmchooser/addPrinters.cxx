

#include "inc/functions.h"

#include <iostream>
#include <string>
#include <vector>
#include <queue>

#include <boost/filesystem.hpp>

namespace bfs=boost::filesystem;

/**
 * function addPrinters(xmlNode* node, char* script)
 * ----------------------------------------------------------
 * runs content of script (absolute path of a script-file)
 *  -> this expects the script to print out printer information
 *    in the following format
 *
 * printserver\tprinter\tprinter description
 *
 * all other output has to be directed to /dev/null
 *
 * then this function add some printer-nodes to the xml-file
 * in "settings/eintrag/printers"
 * (which will be created also if needed.)
 * in the following form: <br/>
 *
 * &lt;printer name=&quot;printer&quot; path=&quot;//printserver/printer&quot; &gt;
 *  Printerdescription
 * &lt;/printer&gt;
 */
bool addPrinters(xmlNode* node, char* script) {

  if(node == NULL) {
    return false;
  }

  bool printer = false;
  vector<string> info_printer;

  const int MAX_LENGTH = 300;
  char line[MAX_LENGTH];
  char delims[] = "\t";
  string strline;
  FILE* inp = 0;

  unsigned int tindex = 0;
  xmlNodePtr cur = node->children;
  xmlNodePtr printernode = NULL;

  // Get <printers> node
  while(cur != NULL) {
    if (!xmlStrcmp(cur->name, (const xmlChar *)"printers")){
      printer = true;
      printernode = cur;
      break;
    }
    cur = cur->next;
  }
  if(! printer) {
    printernode = xmlNewNode(NULL, (const xmlChar*) "printers");
    if(printernode != NULL ) {
      xmlAddChild(node, printernode);
    }
    else {
      cerr << "No <printers> node created" << endl;
    }
  }

  // Parse input of printer-Skript (called by "char* script")
  // and write into <printer> nodes
  if( bfs::is_regular_file(bfs::path(script)) )
  if( (inp = popen(script, "r" )) ) {
    while(fgets(line, MAX_LENGTH, inp ) != NULL) {
      strline = string(line);
      if(strline.length() > 3) {

        queue<unsigned int> temp;
        temp.push( strline.find_first_of( delims , 0) );

        while( temp.back() != string::npos ) {
          temp.push( strline.find_first_of( delims, temp.back()+1 ) );
        }

        unsigned int t_front;
        string tstr = string("");
        while( tindex != string::npos ) {

          // build printer-info element
          t_front = temp.front();

          if(tindex == 0) {
            tstr = strline.substr(0, t_front);
          }
          else if(t_front != string::npos) {
            tstr = strline.substr(tindex+1, t_front-tindex-1) ;
          }
          else {
            tstr = strline.substr( tindex+1, strline.length() - tindex-2 );
          }
          if(tstr.length() > 2) {
            info_printer.push_back( tstr );
            // DEBUG
            cout << info_printer.back() << endl;
          }
          tindex = t_front;
          temp.pop();
        }

        // Construct <printer> nodes
        xmlNodePtr pNode = xmlNewNode(NULL, (const xmlChar*) "printer");
        xmlNewProp(pNode, (const xmlChar*) "name", (const xmlChar*) info_printer.at(1).c_str());
        xmlNewProp ( pNode, (const xmlChar*) "path", (const xmlChar*)
            string( string( "\\\\" ) + info_printer.at(0) + string( "\\" ) + info_printer.at(1) ).c_str() );

        if(info_printer.size() > 2) {
          xmlAddChild( pNode, xmlNewText( (const xmlChar*) info_printer.at(2).c_str() ) );
        }

        if(pNode != NULL) {
          xmlAddChild( printernode, pNode);
        }

        info_printer.clear();
        tindex = 0;
      }
    }
    pclose(inp);
  }
  return true;
}





