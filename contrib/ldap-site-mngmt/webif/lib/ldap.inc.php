<?php
/**
* ldap.inc.php - LDAP-Bibliothek
* Diese Bibliothek enth�lt alle Funktionen f�r den Zugriff auf den LDAP-Server.
*
* @param string ldapError
* @param resource ds
*
* @author Timothy Burk, Mahir Yildirim, Johannes Sprenger, Daniel H�fler
* @copyright Timothy Burk, Mahir Yildirim, Johannes Sprenger, Daniel H�fler
*/
//Konfiguration laden
require_once("config.inc.php");

$ldapError = null;

/**
* uniLdapConnect($userRdn, $userPwd) - F�hrt den Bind am Gruppe1-LDAP-Server durch
*
* @param string userRdn UID f�r den Login
* @param string userPwd Loginpasswort
*
* @return boolean Erfolg bzw. Misserfolg
*
* @author Timothy Burk
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
* rzLdapConnect($userRdn, $userPwd) - F�hrt den Bind am RZ-LDAP-Server durch
*
* @param string userRdn UID f�r den Login
* @param string userPwd Loginpasswort
*
* @return boolean Erfolg bzw. Misserfolg
*
* @author Timothy Burk
*/
function rzLdapConnect($userRdn = "", $userPwd = "") {
   global $ldapError, $suffix_ext;
   if(!(defined("LDAP_HOST_EXT") && defined("LDAP_PORT_EXT"))) {
       $ldapError = "RZ: Hostname und/oder Port des LDAP-Servers wurden nicht angegeben!";
       return FALSE;
   }
   if($ds = ldap_connect(LDAP_HOST_EXT, LDAP_PORT_EXT)) {
       # Connect zum LDAP-Server OK
       if(ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3)) {
           # Optionen gesetzt
           if($userRdn != "" && $userPwd != "") {
             # Anmeldung als User.
             if($result = @ldap_bind($ds, "uid=".$userRdn.",ou=people,".$suffix_ext, $userPwd)) {
               # Bind erfolgreich ausgeführt
               return $ds;
             } else {
               # Bind nicht erfolreich.
               if(ldap_error($ds) == "Invalid credentials") {
                 $ldapError .= "RZ Bind nicht erfolgreich: die Zugangsdaten sind nicht korrekt.<br>\n";
               } else {
                 $ldapError .= "RZ Bind als User nicht erfolgreich: ".ldap_error($ds)."<br>\n";
               }
               return false;
             }
           } else {
             # Anonymer Bind.
             if($result = ldap_bind($ds)) {
               # Anonymer Bind erfolgreich ausgef�hrt
               return $ds;
             } else {
               # Anonymer Bind nicht erfolreich.
               $ldapError .= "RZ Anonymer Bind nicht erfolgreich: ".ldap_error($ds)."<br>\n";
               return false;
             }
           }
       } else {
         # Optionen setzen fehlgeschlagen
         $ldapError .= "RZ Protokollversion setzen fehlgeschlagen: ".ldap_error($ds)."<br>\n";
       }
   } else {
       # Connect fehlgeschlagen.
       $ldapError .= "RZ Connect fehlgeschlagen: ".ldap_error($ds)."<br>\n";
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
     * @author Timothy Burk
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
/**
* uniLdapAdd($ds, $dn, $daten, [$objectclass])
*
* F�gt ein neues Objekt in die LDAP-Datenbank ein.
*
* @param resource $ds Datenbankhandler
* @param string $dn Distinguished Name des neuen Eintrages
* @param array $daten Assoziatives Array mit den gew�nschten Attributen
* @param string $objectclass Objektklasse des neuen Eintrages (Standard = "")
*
* @return boolean TRUE wenn Eintrag erfolgreich, FALSE wenn ein Fehler aufgetreten ist.
*
* @see ldap_add()
*
* @author Timothy Burk
*/
function uniLdapAdd($ds, $dn, $daten, $objectclass = "") {
    if($objectclass != "") {
        $daten['objectclass'] = $objectclass;
    }
    if(ldap_add($ds, $dn, $daten)) {
        return true;
    } else {
        return false;
    }
}

/**
* uniLdapModify($ds, $dn, $daten_alt, $daten_neu, [$i])
*
* Universalfunktion zum �ndern von Attributen und Werten.
* Bei �nderungsskripten muss zuerst ein Formular mit den alten Daten gef�llt werden. Die hierf�r
* durchgef�hrte Suche wird in einem unbehandelten Array in der SESSION gespeichert und wieder
* ausgelesen, sobald die �nderungen gespeichert werden sollen. Es wird anschlie�end an diese Funktion
* (als $daten_alt)gegeben, die das Array mit ldapArraySauber von allen unn�tigen Eintr�gen befreit.
* $daten_alt entspricht dann strukturell dem POST-Array des �nderungsformulars ($daten_neu).
* Letzteres wird nun durch laufen, alle Eintr�ge werden mit ihrer Entsprechnung aus $daten_alt verglichen
* und ggf. werden dann Attribute ge�ndert, gel�scht oder hinzugef�gt.
*
* @param resource $ds Datenbankhandler
* @param string $dn Distinguished Name des Eintrages
* @param array $daten_alt Dreidimensionales mixed Array der Form $array[int][string][int], so wie es von uniLdapSearch zur�ckgeliefert wird.
* @param array $daten_neu Zweidimensionales mixed Array der Form $array[string][int], so wie ein Formular in $_POST gespeichert ist.
* @param int $i Gibt an, welcher Eintrag der ersten Dimension von $daten_alt verwendet werden soll. (Standard: $i=0)
*
* @return boolean TRUE wenn �nderung erfolgreich, FALSE wenn ein Fehler aufgetreten ist.
*
* @see ldap_mod_replace()
* @see ldap_mod_add()
* @see ldap_mod_del()
* @see ldapArraySauber()
* @see numArraySauber()
*
* @author Timothy Burk
*/
function uniLdapModify($ds, $dn, $daten_alt, $daten_neu, $i = 0) {
    $meldung = "";
    $daten_alt = ldapArraySauber($daten_alt, FALSE);
    $daten_alt = $daten_alt[$i];
    foreach($daten_neu as $key => $value_neu) {
        $key = strtolower($key);
        if(!(is_array($value_neu))) {
            # Wenn $value_neu ein Skalar ist...
            # (d.h., das Attribut $key darf nur einen Wert annehmen)
            $value_neu = htmlentities(str_replace(chr(160),"",trim($value_neu)));               // ungewollte Leerzeichen und &nbsp; l�schen
            if (isset($daten_alt[$key])) {
				$daten_alt[$key] = str_replace(chr(160),"",trim($daten_alt[$key]));   // ungewollte Leerzeichen und &nbsp; l�schen
			} else {
				$daten_alt[$key] = "";
			}
            if($daten_alt[$key] == "" && $value_neu != "") {
              # FALL 1:
              # Alter Wert ist leer, neuer Wert ist nicht leer.
              # F�ge neues Attribut hinzu.
                if(ldap_mod_add($ds, $dn, array($key => $value_neu))) {
                    $meldung .= "Add successfull: ".$key." -> ".$value_neu."<br>";
                } else {
                    $meldung .= "Add error: ".$key." -> ".$value_neu."<br>";
                }

            } else if($daten_alt[$key] != "" && $value_neu == "") {
              # FALL 2:
              # Alter Wert ist nicht leer, neuer Wert ist leer.
              # L�sche Attribut.
                if(ldap_mod_del($ds, $dn, array($key => $daten_alt[$key]))) {
                    $meldung .= "Delete successfull: ".$key." -> ".$daten_alt[$key]."<br>";
                } else {
                    $meldung .= "Delete error: ".$key." -> ".$daten_alt[$key]."<br>";
                }

            } else if($daten_alt[$key] != "" && $value_neu != "" && $daten_alt[$key] != $value_neu) {
              # FALL 3:
              # Alter und neuer Wert sind nicht leer und beide sind ungleich.
              # �ndere das Attribut. Der bisherige Wert wird �berschrieben.
                if(ldap_mod_replace($ds, $dn, array($key => $value_neu))) {
                    $meldung .= "Replace successfull: ".$key." -> ".$value_neu."<br>";
                } else {
                    $meldung .= "Replace error: ".$key." -> ".$value_neu."<br>";
                }

            } else {
              # In allen anderen F�llen ist keine �nderung n�tig
            }
        } else {
            # Wenn $value_neu ein Array ist...
            # (d.h., das Attribut $key darf mehrere Werte annehmen)
            $value_neu = numArraySauber($value_neu);
            if (isset($daten_alt[$key])) {
				$value_alt = numArraySauber($daten_alt[$key]);
		        foreach($value_alt as $item) {
			        #$item = htmlentities($item);
				    # L�sche alle alten Werte des Attributes $key.
					if(ldap_mod_del($ds, $dn, array($key => $item))) {
	                    $meldung .= "Delete successfull: ".$key." -> ".$item."<br>";
		            } else {
	                    $meldung .= "Delete error: ".$key." -> ".$item."<br>";
		            }
	            }
			}
            foreach($value_neu as $item) {
                $item = htmlentities($item);
                # F�ge alle neuen Werte des Attributes $key ein.
                if(ldap_mod_add($ds, $dn, array($key => $item))) {
                    $meldung .= "Add successfull: ".$key." -> ".$item."<br>";
                } else {
                    $meldung .= "Add error: ".$key." -> ".$item."<br>";
                }

            }
        }
    }
    #return $meldung;
    if(eregi("error",$meldung)) {
        return FALSE;
    } else {
        return TRUE;
    }
}

/**
* uniLdapDelete l�scht beliebige Eintr�ge mit dessen Subtree aus der Datenbank.
* Dabei wird der wird der Baum ab dem Eintrag $dn zu allen Bl�ttern durchlaufen (Es
* k�nnen nur Bl�tter gel�scht werden!!) und die Eintr�ge von hinten her bis einschlie�lich
* $dn gel�scht
*
* @param resource ds LDAP Directory Handle
* @param string dn Distiguished Name
*
* @return boolean
*
* @author Daniel H�fler
*/

function uniLdapDelete($ds, $dn) {
    # �berpr�fung, ob zu l�schender Eintrag vorhanden ist
    if(!uniLdapSearch($ds, $dn, "objectclass=*", array("*"), "", "one", 0, 0)) {
        $ldapError .= "L�schen fehlgeschlagen: Eintrag nicht gefunden".ldap_error($ds)."<br>\n";
        return false;
    }
    # Auslesen der Daten unterhalb von $dn
    $daten = uniLdapSearch($ds, $dn, "objectclass=*", array("*"), "", "list", 0, 0);
    # for-Schleife wird nur ausgef�hrt, falls sich unterhalb von $dn Eintr�ge befinden
    for($i = 0; $i < $daten['count']; $i++){
        uniLdapDelete($ds, $daten[$i]['dn']);
    }
    # l�schen der Bl�tter
    if(ldap_delete($ds, $dn)) {
        return true;
    } else {
        $ldapError .= "L�schen fehlgeschlagen".ldap_error($ds)."<br>\n";
        return false;
    }
}

############################################################################################
#
# Ab hier LDAP Funktionen (Tarik Gasmi) nutzen die zuvor definierten Funktionen
# von Timothy Burk, u.A.
#
############################################################################################
#  Weitere LDAP Funktionen 

#
# LDAP Funktionen um alle Objekte der AU eines bestimmten Typs mit gew�hlten Attributen zu holen
#
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
   	if($attributes != false ){return $host_array;} 
		else{return $result;}
	}
}

function get_dnshosts_subtree($attributes) 
{
	global $ds, $suffix, $ldapError, $auDN;
	
	if(!($result = uniLdapSearch($ds, $auDN, "(&(objectclass=Host)(ipaddress=*))", $attributes, "", "sub", 0, 0))) {
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
   	if($attributes != false ){return $host_array;} 
		else{return $result;}
	}
}


function check_host_fqdn($hostname) 
{
	global $ds, $suffix, $rootAU, $assocdom, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $rootAU, "(&(objectclass=Host)(hostname=$hostname)(domainname=$assocdom))", array(), "", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	} 
	else{
		$result = ldapArraySauber($result);
		#print_r($result);printf("<br><br>");
   	if( !$result ){
   		#print "OK<br>";
   		return 1;
   	}else{
   		#print "FQDN MATCH<br>";
   		return 0;
   	}
	}
}

function return_zone_hostdn($zone,$hostname) 
{
	global $ds, $suffix, $rootAU, $assocdom, $ldapError;
	
	$matching_hostdn = "";
	
	if(!($result = uniLdapSearch($ds, $rootAU, "(&(objectclass=Host)(hostname=$hostname)(domainname=$zone))", array(), "", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}else{
		$result = ldapArraySauber($result);
   	$matching_hostdn = $result[0][dn];
	}
	return $matching_hostdn;
}

function get_aus_of_zone($zonename) {
	
	global $ds, $suffix, $rootAU, $assocdom, $ldapError;
	$au_array = array();
	
	if ( $zonename == "") {
		$zonename = $assocdom;
	}
	if(!($result = uniLdapSearch($ds, $rootAU, "(&(objectclass=administrativeUnit)(associateddomain=$zonename))", array("dn"), "", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}else{
		$result = ldapArraySauber($result);
		#print_r($result);printf("<br><br>");
		foreach ($result as $item){
			$au_array [] = $item['dn'];
		}
	}
	return $au_array;
}

# Variante ohne Domainname in Hostobjekt
function check_host_fqdn2($hostname,$zonename) 
{
	global $ds, $suffix, $rootAU, $assocdom, $ldapError;
	
	if ( !$zonename ) {
		$zonename = $assocdom;
	}
	$hostname_check = 1;
	$aus_in_zone = get_aus_of_zone($zonename);
	
	if ($aus_in_zone) {
		foreach ($aus_in_zone as $au) {
			if(!($result = uniLdapSearch($ds, "cn=computers,".$au, "(&(objectclass=Host)(hostname=$hostname))", array(), "", "list", 0, 0))) {
		 		# redirect(5, "", $ldapError, FALSE);
		  		echo "no search"; 
		  		die;
			} 
			else{
				$result = ldapArraySauber($result);
				#print_r($result);printf("<br><br>");
		   	if( $result ){
		   		$hostname_check = 0;
		   	}
			}
		}
	}
	return $hostname_check;
}
# Variante ohne Domainname in Hostobjekt
function check_hostarray_fqdn2($hostarray,$zonename) 
{
	global $ds, $suffix, $rootAU, $assocdom, $ldapError;
	
	if ( !$zonename ) {
		$zonename = $assocdom;
	}
	$matching_hostnames = array();
	#$hostname_check = 1;
	$aus_in_zone = get_aus_of_zone($zonename);
	
	if ($aus_in_zone) {
		foreach ($hostarray as $host) {
			foreach ($aus_in_zone as $au) {
				if(!($result = uniLdapSearch($ds, "cn=computers,".$au, "(&(objectclass=Host)(hostname=$host[hostname]))", array("hostname"), "", "list", 0, 0))) {
			 		# redirect(5, "", $ldapError, FALSE);
			  		echo "no search"; 
			  		die;
				} 
				else{
					$result = ldapArraySauber($result);
					#print_r($result);printf("<br><br>");
			   	if( $result ){
						$matching_hostnames [] = $host['hostname'];
			   		#$hostname_check = 0;
			   	}
				}
			}
		}
	}
	return $matching_hostnames;
	#return $hostname_check;
}

function get_groups($auDN,$attributes) 
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, "cn=groups,".$auDN, "(objectclass=groupOfComputers)", $attributes, "cn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	} 
	else{
		$result = ldapArraySauber($result); 
		# print_r($result);printf("<br><br>");
		$group_array = array();
		foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att]; 
   		}
   		$atts['auDN'] = $auDN;
   		$group_array[] = $atts;
   	}
   	if($attributes != false ){return $group_array;}
		else{return $result;}
	}
}

function get_groups_member($auDN,$attributes,$member) 
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, "cn=groups,".$auDN, "(&(objectclass=groupOfComputers)(member=$member))", $attributes, "cn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	} 
	else{
		$result = ldapArraySauber($result); 
		# print_r($result);printf("<br><br>");
		$group_array = array();
		foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att]; 
   		}
   		$atts['auDN'] = $auDN;
   		$group_array[] = $atts;
   	}
   	if($attributes != false ){return $group_array;}
		else{return $result;}
	}
}

function get_machineconfigs($baseDN,$attributes) 
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $baseDN, "(objectclass=MachineConfig)", $attributes, "", "list", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	elseif(count($result) == 0){return $result;}
	else{
		$result = ldapArraySauber($result);
		# print_r($result);printf("<br><br>");
		$mc_array = array();
		foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['baseDN'] = $baseDN;
   		$atts['auDN'] = $auDN;
   		$mc_array[] = $atts;
   	}
   	if($attributes != false ){return $mc_array;} 
		else{return $result;}
	}
}

function get_pxeconfigs($baseDN,$attributes) 
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $baseDN, "(objectclass=PxeConfig)", $attributes, "", "list", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}
	elseif(count($result) == 0){return $result;}
	else{
		$result = ldapArraySauber($result);
		# print_r($result);printf("<br><br>");
		$pxe_array = array();
		foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['baseDN'] = $baseDN;
   		$atts['auDN'] = $auDN;
   		$pxe_array[] = $atts;
   	}
   	if($attributes != false ){return $pxe_array;} 
		else{return $result;}
	}
}

function get_pxeconfigs2($clientDN,$attributes) 
{
	global $auDN, $ds, $suffix, $ldapError;
	
	if ($clientDN == ""){
		$filter = "(objectclass=PxeConfig)";
	}else{
		$filter = "(&(objectclass=PxeConfig)(pxeclientdn=$clientDN))";
	}
	
	if(!($result = uniLdapSearch($ds, "cn=pxe,".$auDN, $filter, $attributes, "", "list", 0, 0))) {
		# redirect(5, "", $ldapError, FALSE);
		echo "no search"; 
		die;
	}
	elseif(count($result) == 0){return $result;}
	else{
		$result = ldapArraySauber($result);
		# print_r($result);printf("<br><br>");
		$pxe_array = array();
		foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['baseDN'] = $baseDN;
   		$atts['auDN'] = $auDN;
   		$pxe_array[] = $atts;
   	}
   	if($attributes != false ){return $pxe_array;} 
		else{return $result;}
	}
}

function get_menuentries($baseDN,$attributes) 
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $baseDN, "(objectclass=MenuEntry)", $attributes, "menuposition", "list", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}
	elseif(count($result) == 0){return $result;}
	else{
		$result = ldapArraySauber($result);
		# print_r($result);printf("<br><br>");
		$menent_array = array();
		foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['baseDN'] = $baseDN;
   		$atts['auDN'] = $auDN;
   		$menent_array[] = $atts;
   	}
   	if($attributes != false ){return $menent_array;} 
		else{return $result;}
	}
}

function get_rbservices($auDN,$attributes) 
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, "cn=rbs,".$auDN, "(objectclass=RBService)", $attributes, "cn", "list", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}
	elseif(count($result) == 0){return $result;}
	else{
		$result = ldapArraySauber($result);
		# print_r($result);printf("<br><br>");
		$rbs_array = array();
		foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['auDN'] = $auDN;
   		$rbs_array[] = $atts;
   	}
   	if($attributes != false ){return $rbs_array;} 
		else{return $result;}
	}
}

function get_subnets($auDN,$attributes)
{ 
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, "cn=dhcp,".$auDN, "(objectclass=dhcpSubnet)", $attributes, "cn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	} 
	else { 
		$result = ldapArraySauber($result); 
		$subnet_array = array();
   	foreach ($result as $item){ 
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['auDN'] = $auDN;
   		$subnet_array[] = $atts;
   	}
		if($attributes != false ){return $subnet_array;}
		else{return $result;} 
   }
}


function get_dhcppools($auDN,$attributes)
{ 
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, "cn=dhcp,".$auDN, "(objectclass=dhcpPool)", $attributes, "cn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";  
  		die;
	} 
	else {
		$result = ldapArraySauber($result); 
	
		$pool_array = array();
   	foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['auDN'] = $auDN;
   		$pool_array[] = $atts;
   	}  
		if($attributes != false ){return $pool_array;}
		else{return $result;}
   }
}

function get_dhcppools_subnet($subnetDN,$attributes)
{ 
	global $ds, $suffix, $auDN, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $auDN, "(&(objectclass=dhcpPool)(dhcphlpcont=$subnetDN))", $attributes, "cn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";  
  		die;
	} 
	else {
		$result = ldapArraySauber($result); 
	
		$pool_array = array();
   	foreach ($result as $item){
   	   $poolexpdn = ldap_explode_dn($item['dn'], 1);
   	   $poolau = $poolexpdn[2];
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['poolAU'] = $poolau;
   		$pool_array[] = $atts;
   	}  
		if($attributes != false ){return $pool_array;}
		else{return $result;}
   }
}

function get_dhcppools_subnet_au($subnetDN,$au,$attributes)
{ 
	global $ds, $suffix, $auDN, $ldapError;
	
	if(!($result = uniLdapSearch($ds, "cn=dhcp,".$au, "(&(objectclass=dhcpPool)(dhcphlpcont=$subnetDN))", $attributes, "cn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";  
  		die;
	} 
	else {
		$result = ldapArraySauber($result); 
	
		$pool_array = array();
   	foreach ($result as $item){
   	   $poolexpdn = ldap_explode_dn($item['dn'], 1);
   	   $poolau = $poolexpdn[2];
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['poolAU'] = $poolau;
   		$pool_array[] = $atts;
   	}  
		if($attributes != false ){return $pool_array;}
		else{return $result;}
   }
}

function get_dhcppoolranges($poolDN)
{ 
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $poolDN, "(objectclass=dhcpPool)", array("dhcprange"), "", "one", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";  
  		die;
	} 
	else {
		$result = ldapArraySauber($result); 
	   #print_r($result); echo "<br><br>";
		$ranges_array = array();
		if ( count($result[0]['dhcprange']) == 1 ){
		   $ranges_array [] = $result[0]['dhcprange'];
		}
		elseif ( count($result[0]['dhcprange']) > 1 ){
		   foreach ($result[0]['dhcprange'] as $range){
	   	   $ranges_array [] = $range;
	   	}
		}
		return $ranges_array;
   }
} 

function get_childau($auDN,$attributes)
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $auDN, "(objectclass=AdministrativeUnit)", $attributes, "ou", "list", 0, 0))) {
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

function get_childau_sub($auDN,$attributes)
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $auDN, "(objectclass=AdministrativeUnit)", $attributes, "dn", "sub", 0, 0))) {
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

function get_au_data($auDN,$attributes)
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $auDN, "(objectclass=AdministrativeUnit)", $attributes, "ou", "one", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";  
  		die;
	} 
	else {
		$result = ldapArraySauber($result); 
	
		$au_array = array();
   	foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['auDN'] = $auDN;
   		$au_array[] = $atts;
   	} 
		if($attributes != false ){return $au_array;}
		else{return $result;}
   }
}

function get_domain_data($auDN,$attributes)
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $suffix, "(&(objectclass=dnsdomain)(associatedname=$auDN))", $attributes, "", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";  
  		die;
	} 
	else {
		$result = ldapArraySauber($result); 
	
		$domain_array = array();
   	foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['auDN'] = $auDN;
   		$domain_array[] = $atts;
   	} 
		if($attributes != false ){return $domain_array;}
		else{return $result;}
   }
}


function get_roles($auDN) 
{
	global $ds, $suffix, $domDN, $ldapError;
	
	if(!($result = uniLdapSearch($ds, "cn=roles,".$auDN, "(|(objectclass=GroupOfNames)(objectclass=Admins))", array("cn","member"), "cn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
  	}
	else{
		$result = ldapArraySauber($result);
		$roles_array = array();
		#print_r($result);
		foreach ($result as $item){
			if ( count($item['member']) > 1 ){
				foreach ($item['member'] as $member){
			  	 	$roles_array[$item['cn']][] = $member;
   			}
   		}
   		if ( count($item['member']) == 1 ){
   			$roles_array[$item['cn']][] = $item['member'];
   		}
   	}
   	return $roles_array; 
	}
}

function get_roles_dns($domDN) 
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, "cn=roles,".$domDN, "(objectclass=GroupOfNames)", array("cn","member"), "cn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
  	}	
  	else{	
		$result = ldapArraySauber($result);
		$roles_array = array();
		foreach ($result as $item){
			if ( count($item['member']) > 1){
				foreach ($item['member'] as $member){
			   	$roles_array[$item['cn']][] = $member;
   			}
   		}else{
   			$roles_array[$item['cn']][] = $item['member'];
   		}
   	}
   	return $roles_array; 
	}
}


function get_users(){

	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, "ou=people,".$suffix, "(objectclass=inetOrgPerson)", array("dn","cn","sn","uid"), "", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
  	}	
  	else{
		$result = ldapArraySauber($result);
		$users_array = array();
		# foreach ($result as $item){
   	#  	$users_array[$item['cn']] = $item['member'];
   	# } 
   	#  return $users_array;
   	return $result; 
	}
}

function get_user_data($userDN,$attributes)
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $userDN, "(objectclass=inetOrgPerson)", $attributes, "", "one", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";  
  		die;
	} 
	else {
		$result = ldapArraySauber($result); 	
   	foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$user_data = $atts;
   	} 
		if($attributes != false ){return $user_data;}
		else{return $result;}
   }
} 


function get_dc_data($dcDN,$attributes)
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $dcDN, "(objectclass=dnsdomain)", $attributes, "", "one", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";  
  		die;
	} 
	else {
		$result = ldapArraySauber($result); 	
   	foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$dc_data = $atts;
   	} 
		if($attributes != false ){return $dc_data;}
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



function get_zone_entries($dcDN,$attributes) 
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $dcDN, "(|(objectclass=dNSZone)(objectclass=dNSZoneIncludeDirective))", $attributes, "", "list", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	} 
	else{
		$result = ldapArraySauber($result);
		# print_r($result);printf("<br><br>");
		$zone_array = array();
		foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['dcDN'] = $dcDN;
   		$zone_array[] = $atts;
   	}
   	if($attributes != false ){return $zone_array;} 
		else{return $result;}
	}
}


function get_zone_entries_assocname($dcDN,$attributes,$assocname) 
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $dcDN, "(&(|(objectclass=dNSZone)(objectclass=dNSZoneIncludeDirective))(associatedname=$assocname))", $attributes, "", "list", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	} 
	else{
		$result = ldapArraySauber($result);
		# print_r($result);printf("<br><br>");
		$zone_array = array();
		foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['dcDN'] = $dcDN;
   		$zone_array[] = $atts;
   	}
   	if($attributes != false ){return $zone_array;} 
		else{return $result;}
	}
}

function get_dn_menuposition($pxeDN,$pos)
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $pxeDN, "(menuposition=$pos)", array("dn"), "", "list", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";  
  		die;
	} 
	else {
		$result = ldapArraySauber($result); 
		return $result[0]['dn'];
   }
}

function get_dhcpservices($auDN,$attributes) 
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, "cn=dhcp,".$auDN, "(objectclass=dhcpService)", $attributes, "", "list", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}
	elseif(count($result) == 0){return $result;}
	else{
		$result = ldapArraySauber($result);
		# print_r($result);printf("<br><br>");
		$dhcp_array = array();
		foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['auDN'] = $auDN;
   		$dhcp_array[] = $atts;
   	}
   	if($attributes != false ){return $dhcp_array;} 
		else{return $result;}
	}
}

function get_dhcpclasses($auDN,$attributes) 
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, "cn=dhcp,".$auDN, "(objectclass=dhcpClass)", $attributes, "", "list", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}
	elseif(count($result) == 0){return $result;}
	else{
		$result = ldapArraySauber($result);
		# print_r($result);printf("<br><br>");
		$dhcp_array = array();
		foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['auDN'] = $auDN;
   		$dhcp_array[] = $atts;
   	}
   	if($attributes != false ){return $dhcp_array;} 
		else{return $result;}
	}
}

function get_dhcpsubclasses($classDN,$attributes) 
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $classDN, "(objectclass=dhcpSubClass)", $attributes, "", "list", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}
	elseif(count($result) == 0){return $result;}
	else{
		$result = ldapArraySauber($result);
		# print_r($result);printf("<br><br>");
		$dhcp_array = array();
		foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['auDN'] = $auDN;
   		$dhcp_array[] = $atts;
   	}
   	if($attributes != false ){return $dhcp_array;} 
		else{return $result;}
	}
}

function get_dhcpcondstatements($attributes) 
{
	global $ds, $rootAU, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $rootAU, "(objectclass=dhcpCondStatement)", $attributes, "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}
	elseif(count($result) == 0){return $result;}
	else{
		$result = ldapArraySauber($result);
		#print_r($result);printf("<br><br>");
		$dhcp_array = array();
		foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['dn'] = $item['dn'];
   		$dhcp_array[] = $atts;
   	}
   	if($attributes != false ){return $dhcp_array;} 
		else{return $result;}
	}
}

function get_au_dhcpsubnets($auDN,$attributes) 
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, "cn=dhcp,".$auDN, "(objectclass=dhcpSubnet)", $attributes, "", "list", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}
	elseif(count($result) == 0){return $result;}
	else{
		$result = ldapArraySauber($result);
		# print_r($result);printf("<br><br>");
		$dhcp_array = array();
		foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['auDN'] = $auDN;
   		$dhcp_array[] = $atts;
   	}
   	if($attributes != false ){return $dhcp_array;} 
		else{return $result;}
	}
}

# alle Subnets im AU-Subtree (auch Child AUs)
function get_dhcpsubnets($auDN,$attributes) 
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $auDN, "(objectclass=dhcpSubnet)", $attributes, "", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}
	elseif(count($result) == 0){return $result;}
	else{
		$result = ldapArraySauber($result);
		# print_r($result);printf("<br><br>");
		$dhcp_array = array();
		foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$atts['auDN'] = $auDN;
   		$dhcp_array[] = $atts;
   	}
   	if($attributes != false ){return $dhcp_array;} 
		else{return $result;}
	}
}

function get_dhcpsubnets_from_nets($nets,$attributes) 
{
	global $ds, $rootAU, $suffix, $ldapError, $all_roles;
	
	$dhcpsubnets = array();
	foreach ($nets as $subnet) {
	
		if(!($result = uniLdapSearch($ds, $rootAU, "(&(objectclass=dhcpSubnet)(cn=$subnet))", $attributes, "", "sub", 0, 0))) {
	 		# redirect(5, "", $ldapError, FALSE);
	  		echo "no search"; 
	  		die;
		}
		else{
			$result = ldapArraySauber($result);
			#print_r($result);printf("<br><br>");
			if($result) {
			$atts = array();
			foreach ($result as $item){
				$atts[dn] = $item[dn]; 
				foreach ($attributes as $att){
	   			$atts[$att] = $item[$att];
	   		}
	   		###
	   		# in fkt auslagern
	   		$subexpdn_atts = array_slice(ldap_explode_dn($item[dn] , 0),3);
	   		$subnetaudn = implode(",",$subexpdn_atts);
	   		$subnetadmin = 0;
				if ($all_roles[$subnetaudn]['roles']) {
					foreach ($all_roles[$subnetaudn]['roles'] as $role) {
						switch ($role){ 
						case 'MainAdmin':
							$subnetadmin = 1;
							break;
						case 'DhcpAdmin':
							$subnetadmin = 1;
							break;
						}
					}
				}
				#if (count($subexpdn) < count($auexpdn)){
				if (!$subnetadmin){	
					$atts[access] = "readonly";
				}
	   		###
	   	}
	   	$dhcpsubnets [] = $atts;
	   	}
		}		
	}
	return $dhcpsubnets;
}

function get_service_subnets($dhcpserviceDN,$attributes) 
{
	global $ds, $suffix, $ldapError;
	
	$filter = "(&(dhcphlpcont=".$dhcpserviceDN.")(objectclass=dhcpSubnet))";
	if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, $filter, $attributes, "", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}
	elseif(count($result) == 0){return $result;}
	else{
		$result = ldapArraySauber($result);
		# print_r($result);
		$dhcpsubnets = array();
		foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$expdn = ldap_explode_dn($item['dn'],1);
   		$au = array_slice($expdn, 3, 1);
   		$atts['auDN'] = implode ( ',', $au );
   		$dhcpsubnets [] = $atts;
   	}
   	#print_r($dhcpsubnets);
   	if($attributes != false ){
   	   return $dhcpsubnets;
   	} 
		else{return $result;}
	}
}

function get_pool_subnet_data($dhcprange,$attributes) {

	global $ds, $suffix, $ldapError;
	
	$iprange = explode('_',$dhcprange);
	$fs = explode('.',$iprange[0]);
   $fe = explode('.',$iprange[1]);
   if ( $fs[0] == $fe[0] && $fs[1] == $fe[1] && $fs[2] == $fe[2] && $fs[3] <= $fe[3] ) {
	   # DHCP Subnet DN finden
		$subnet = implode(".", array($fs[0],$fs[1],$fs[2],"0"));
		if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(&(objectclass=dhcpSubnet)(cn=$subnet))", $attributes, "", "sub", 0, 0))) {
   		# redirect(5, "", $ldapError, FALSE);
      	echo "no search"; 
        	die;
      }
      $result = ldapArraySauber($result);
      #print_r($result);echo "<br><br>";
      if (count($result[0]) != 0){		
			return $result[0];
		}else{
			print "kein DHCP Subnet gefunden!<br><br>";
			return 0;
		}
	}else{
		print "DHCP Range $dhcprange nicht korrekt!<br><br>";
		return 0;
	}
}

?> 
