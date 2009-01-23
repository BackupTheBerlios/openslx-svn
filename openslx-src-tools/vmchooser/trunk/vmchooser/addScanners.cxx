

#include "inc/functions.h"

#include <iostream>
#include <string>
#include <vector>
#include <queue>

/**
 * function addScanners(xmlNode* node, char* script)
 * ----------------------------------------------------------
 * runs content of script (absolute path of a script-file)
 *  -> this expects the script to print out scanner information
 *    in the following format
 * 
 * scanserver\tscanner\tscanner description
 * 
 * all other output has to be directed to /dev/null
 * 
 * then this function add some scanner-nodes to the xml-file
 * in "settings/eintrag/scanners" 
 * (which will be created also if needed.)
 * in the following form: <br/>
 * 
 * &lt;scanner name=&quot;scanner&quot; path=&quot;//scanserver/scanner&quot; &gt;
 *  Scannerdescription
 * &lt;/scanner&gt;
 */
bool addScanners(xmlNode* node, char* script) {
  
  if(node == NULL) {
    return false;
  }
  
  bool scanner = false;
  vector<string> info_scanner;
  
  const int MAX_LENGTH = 300;
  char line[MAX_LENGTH];
  char delims[] = "\t";
  string strline;
  FILE* inp = 0;
  
  unsigned int tindex = 0;
  xmlNodePtr cur = node->children;
  xmlNodePtr scannernode = NULL;
  
  // Get <scanners> node
  while(cur != NULL) {
    if (!xmlStrcmp(cur->name, (const xmlChar *)"scanners")){
      scanner = true;
      scannernode = cur;
      break;
    }
    cur = cur->next;
  }
  if(! scanner) {
    scannernode = xmlNewNode(NULL, (const xmlChar*) "scanners");
    if(scannernode != NULL ) {
      xmlAddChild(node, scannernode);
    }
    else {
      cerr << "No <scanners> node created" << endl;
    }
  }
  
  // Parse input of scanner-Skript (called by "char* script")
  // and write into <scanner> nodes
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
          
          // build scanner-info element
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
            info_scanner.push_back( tstr );
            // DEBUG
            cout << info_scanner.back() << endl;
          }
          tindex = t_front;
          temp.pop();
        }
        
        // Construct <scanner> nodes 
        xmlNodePtr pNode = xmlNewNode(NULL, (const xmlChar*) "scanner");
        xmlNewProp(pNode, (const xmlChar*) "name", (const xmlChar*) info_scanner.at(1).c_str());
        xmlNewProp ( pNode, (const xmlChar*) "path", (const xmlChar*)
            string( string( "\\\\" ) + info_scanner.at(0) + string( "\\" ) + info_scanner.at(1) ).c_str() );

        if(info_scanner.size() > 2) {
          xmlAddChild( pNode, xmlNewText( (const xmlChar*) info_scanner.at(2).c_str() ) );
        }
        
        if(pNode != NULL) {
          xmlAddChild( scannernode, pNode);
        }
        
        info_scanner.clear();
        tindex = 0;
      }
    }
    pclose(inp);
    return true;
  }
  fprintf(stderr, "Couldn't run \"%s\" script!", script);
  return false;
}

