<?php

//Konfiguration laden
require_once("config3.inc.php");

$ldapError = null;

/**
* uniLdapConnect($userRdn, $userPwd) - F�hrt den Bind am LDAP-Server durch
*
* @param string userRdn UID f�r den Login
* @param string userPwd Loginpasswort
*
* @return boolean Erfolg bzw. Misserfolg
*
*/
function uniLdapConnect($userRdn = "", $userPwd = "") {
   global $ldapError, $suffix;
   if(!(defined("LDAP_HOST") && defined("LDAP_PORT"))) {
       $ldapError = "Hostname und/oder Port des LDAP-Servers wurden nicht angegeben!";
       return FALSE;
   }
   if($ds = ldap_connect(LDAP_HOST, LDAP_PORT)) {
       # Connect zum LDAP-Server OK
       if(ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3)) {
           # Optionen gesetzt
           #if (ldap_start_tls($ds)){
              if($userRdn != "" && $userPwd != "") {
                # Anmeldung als User.
                if($result = @ldap_bind($ds, "uid=".$userRdn.",ou=people,".$suffix, $userPwd)) {
                  # Bind erfolgreich ausgef�hrt
                  return $ds;
                } else {
                  # Bind nicht erfolreich.
                  if(ldap_error($ds) == "Invalid credentials") {
                    $ldapError .= "Bind nicht erfolgreich: die Zugangsdaten sind nicht korrekt.<br>\n";
                  } else {
                    $ldapError .= "Bind als User nicht erfolgreich: ".ldap_error($ds)."<br>\n";
                  }
                  #print_r(ldap_error($ds));echo "<br><br>";
                  return false;
                }
              } else {
                # Anonymer Bind.
                if($result = ldap_bind($ds)) {
                  # Anonymer Bind erfolgreich ausgef�hrt
                  return $ds;
                } else {
                  # Anonymer Bind nicht erfolreich.
                  $ldapError .= "Anonymer Bind nicht erfolgreich: ".ldap_error($ds)."<br>\n";
                  return false;
                }
              }
          #} else {
          #   # TLS starten fehlgeschlagen
          #   $ldapError .= "TLS starten fehlgeschlagen: ".ldap_error($ds)."<br>\n";
          #}
       } else {
         # Optionen setzen fehlgeschlagen
         $ldapError .= "Protokollversion setzen fehlgeschlagen: ".ldap_error($ds)."<br>\n";
       }
   } else {
       # Connect fehlgeschlagen.
       $ldapError .= "Connect fehlgeschlagen: ".ldap_error($ds)."<br>\n";
   }
}


     /**
     * uniLdapSearch($ds, $base, $filter, $attributes, $sort, $mode, $resultLimit, $timeout)
     * Sucht Eintr�ge im LDAP-Server.
     *
     * Durchsucht den LDAP-Server vom Punkt $base ab nach Eintr�gen, die $filter entsprechen. Falls in $sort ein Feldname angegeben
     * wurde, so wird danach sortiert. (ACHTUNG: die Funktion ldap_sort() ist nicht dokumentiert! Ich wei� nicht ob sie Sortierung
     * nach mehreren Feldern zul�sst und wie sie sich verh�lt, wenn zu einem Attribut mehrere Werte existieren.) $mode definiert die
     * Art der Suche, wohingegen $resultLimit und $timeout die Anzahl der Ergebnis-Eintr�ge bzw. die maximalen Suchdauer einschr�nken.
     * Zur�ckgegeben werden die Attribute, die im Array $attributes aufgef�hrt sind. Im Erfolgsfalle wird ein multidimensionales Array
     * zur�ckgeliefert, im Fehlerfalle FALSE. Dann steht die Fehlermeldung in der Variablen $ldapError.
     *
     * @param string $base die DN, das Verzeichnis, in dem die Suche startet
     *
     * @param string $filter die Suchbedingungen
     *
     * @param array attributes die Attributnamen, deren Werte im Ergebnis enthalten sein sollen.
     *
     * @param string $sort Sortiert die Ergebnis-Eintr�ge nach dem angegebenen Feldnamen (undokumentiert! s.o.)
     *
     * @param string $mode Der Modus: "one" liefert einen Eintrag, "list" alle Eintr�ge des Verzeichnisses und "sub"
     *                     schlie�t alle Untervezeichnisse mit ein.
     *
     * @param int $resultLimit die maximale Anzahl zur�ckgegebener Eintr�ge
     *
     * @param int $timeout die maximale Suchzeit, bevor der LDAP-Server abbrechen soll
     *
     * @return mixed multidimensionales array mit den Eintr�gen im Erfolgsfall, FALSE wenn ein Fehler auftrat
     *
     * @see ldap_read()
     * @see ldap_list()
     * @see ldap_search()
     * @see ldap_sort()
     * @see ldap_get_entries()
     * @see ldap_free_result()
     *
     */
function uniLdapSearch($ds, $base, $filter, $attributes, $sort, $mode, $resultLimit, $timeout) {
   global $ldapError;
   $abfrage = false;
   if($mode == "one") {
     if($resource = ldap_read($ds, $base, $filter, $attributes, 0, $resultLimit, $timeout)) {
         # Abfrage erfolgreich!
         $abfrage = true;
     } else {
         # Abfrage fehlgeschlagen.
         $ldapError .= "Abfrage mit Mode $mode ist fehlgeschlagen: ".ldap_error($ds)."<br>\n";
         return false;
     }
   } else if($mode == "list") {
     if($resource = ldap_list($ds, $base, $filter, $attributes, 0, $resultLimit, $timeout)) {
         # Abfrage erfolgreich!
         ldap_sort($ds,$resource,$sort);
         $abfrage = true;
     } else {
         # Abfrage fehlgeschlagen.
         $ldapError .= "Abfrage mit Mode $mode ist fehlgeschlagen: ".ldap_error($ds)."<br>\n";
         return false;
     }
   } else if($mode == "sub") {
      if($resource = ldap_search($ds, $base, $filter, $attributes, 0, $resultLimit, $timeout)) {
         # Abfrage erfolgreich!
         ldap_sort($ds,$resource,$sort);
         $abfrage = true;
     } else {
         # Abfrage fehlgeschlagen.
         $ldapError .= "Abfrage mit Mode $mode ist fehlgeschlagen: ".ldap_error($ds)."<br>\n";
         return false;
     }
   } else {
     # Kein g�ltiger Modus angegeben.
     $ldapError .= "Es wurde kein g�ltiger Modus angegeben.";
     return false;
   }
   if($abfrage && ($entries = ldap_get_entries($ds, $resource))) {
     # Auslesen des Verzeichnisses erfolgreich.
     ldap_free_result($resource);
     return $entries;
   } else {
     # Auslesen des Verzeichnisses nicht erfolgreich.
     $ldapError .= "Auslesen des Verzeichnisses nicht erfolgreich: ".ldap_error($ds)."<br>\n";
     return false;
   }
}




#
# LDAP Funktionen um alle Objekte der AU eines bestimmten Typs mit gew�hlten Attributen zu holen
#
# alle Attribute array("hostname","domainname","ipaddress","hwaddress","description")

# $auDN = "ou=Lehrpool1,ou=Rechenzentrum,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de";
# $attributes array("hostname","domainname","ipaddress","hwaddress","description");
function get_hosts($auDN,$attributes,$sortattr) 
{
	global $ds, $suffix, $ldapError;
	
	if ( $sortattr == ""){
		$sortattr = "hostname";
	}
	
	if(!($result = uniLdapSearch($ds, "cn=computers,".$auDN, "(objectclass=Host)", $attributes, $sortattr, "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	} 
	else{
		$result = ldapArraySauber($result);
		# print_r($result);printf("<br><br>");
		$host_array = array();
		foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['auDN'] = $auDN;
   		$host_array[] = $atts;
   	}
   	if($attributes != false ){
   		return $host_array;
   	} 
		else{
			return $result;
		}
	}
}

function get_hosts_to_macaddress($hostdn,$macaddress,$attributes,$sortattr) 
{
	global $ds, $suffix, $rootAU, $ldapError;

	if ( $sortattr == ""){
		$sortattr = "hostname";
	}
	
	if(!($result = uniLdapSearch($ds, $rootAU, "(&(objectclass=Host)(hwaddress=$macaddress))", $attributes, $sortattr, "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	} 
	else{
		$result = ldapArraySauber($result);
		#print_r($result);printf("<br><br>");
		$host_array = array();
		foreach ($result as $item){
			if ($item['dn'] != $hostdn) {
				foreach ($attributes as $att){
	   			$atts[$att] = $item[$att];
	   			$atts['dn'] = $item['dn'];
	   		}
	   		$atts['auDN'] = $auDN;
	   		$host_array[] = $atts;
   		}
   	}
   	if($attributes != false ){return $host_array;} 
		else{return $result;}
	}
}



function get_all_aus($attributes)
{
	global $ds, $auDN, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(objectclass=AdministrativeUnit)", $attributes, "ou", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";  
  		die;
	} 
	else {
		$result = ldapArraySauber($result); 
	
		$childau_array = array();
   	foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['auDN'] = $auDN;
   		$childau_array[] = $atts;
   	} 
		if($attributes != false ){return $childau_array;}
		else{return $result;}
   }
} 


function get_node_data($nodeDN,$attributes)
{
	global $ds, $suffix, $ldapError;
	
	$node_data = array();
	
	if(!($result = uniLdapSearch($ds, $nodeDN, "(objectclass=*)", $attributes, "", "one", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
 		# redirect(0, $START_PATH."/au/au.php", "", TRUE);
  		echo "no search";
  		die;
	} 
	else {
		$result = ldapArraySauber($result); 	
   	foreach ($result as $item){
			foreach ($attributes as $att){
   			$node_data[$att] = $item[$att];
   		}
   	} 
		if($attributes != false ){return $node_data;}
		else{return $result;}
   }
}

function ldapArraySauber($Array, $delEmpty = FALSE) {
    $b = array();
    foreach($Array as $key => $item) {
        if(is_array($item)) {
            foreach($item as $key_attr => $attr) {
                if(!is_int($key_attr)) {
                    if(is_array($attr)) {
                      if($attr['count'] == 1) {
                        $attr[0] = str_replace(chr(160),"",trim($attr[0]));
                        if(($delEmpty && $attr[0] != "") || !($delEmpty)) {
                            $b[$key][$key_attr] = $attr[0];
                        }
                      } else {
                        for($i=0; $i < $attr['count']; $i++) {
                            $attr[$i] = str_replace(chr(160),"",trim($attr[$i]));
                            if(($delEmpty && $attr[$i] != "") || !($delEmpty)) {
                                $b[$key][$key_attr][$i] = $attr[$i];
                            }
                        }
                      }
                    } else {
                        $attr = str_replace(chr(160),"",trim($attr));
                        if(($delEmpty && $attr != "") || !($delEmpty)) {
                            $b[$key][$key_attr] = $attr;
                        }
                    }
                }
            }
        } else {
            if(is_int($key)) {
                $item = str_replace(chr(160),"",trim($item));
                if(($delEmpty && $item != "") || !($delEmpty)) {
                    $b[$key] = $item;
                }
            }
        }
    }
    return $b;
} 

#objectclass ( 1.3.6.1.4.1.7579.1005.5.3
#	NAME 'Host'
#	DESC 'Computer'
#	SUP top
#	MUST ( HostName $ DomainName )
#	MAY ( IPAddress $ HWAddress $ description $ HlpRBService $ geoLocation $ geoAttribut ) )



# ldapsearch -x -H ldap://132.230.9.131:389 -b "ou=Lehrpool1,ou=Rechenzentrum,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de" -D "uid=marcoh,ou=people,dc=uni-freiburg,dc=de" -W -v "objectclass=Host" 

