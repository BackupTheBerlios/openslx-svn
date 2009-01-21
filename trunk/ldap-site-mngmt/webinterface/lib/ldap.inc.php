<?php
/**
* ldap.inc.php - LDAP-Bibliothek
* Diese Bibliothek enthält alle Funktionen für den Zugriff auf den LDAP-Server.
*
* @param string ldapError
* @param resource ds
*
* @author Timothy Burk, Mahir Yildirim, Johannes Sprenger, Daniel Höfler
* @copyright Timothy Burk, Mahir Yildirim, Johannes Sprenger, Daniel Höfler
*/
//Konfiguration laden
require_once("config.inc.php");

$ldapError = null;

/**
* uniLdapConnect($userRdn, $userPwd) - Führt den Bind am Gruppe1-LDAP-Server durch
*
* @param string userRdn UID für den Login
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
                  # Bind erfolgreich ausgeführt
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
                  # Anonymer Bind erfolgreich ausgeführt
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
* rzLdapConnect($userRdn, $userPwd) - Führt den Bind am RZ-LDAP-Server durch
*
* @param string userRdn UID für den Login
* @param string userPwd Loginpasswort
*
* @return boolean Erfolg bzw. Misserfolg
*
* @author Timothy Burk
*/
function rzLdapConnect($userRdn = "", $userPwd = "") {
   global $ldapError, $suffix_rz;
   if(!(defined("LDAP_HOST_RZ") && defined("LDAP_PORT_RZ"))) {
       $ldapError = "Hostname und/oder Port des LDAP-Servers wurden nicht angegeben!";
       return FALSE;
   }
   if($ds = ldap_connect(LDAP_HOST_RZ, LDAP_PORT_RZ)) {
       # Connect zum LDAP-Server OK
       if(ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3)) {
           # Optionen gesetzt
           if($userRdn != "" && $userPwd != "") {
             # Anmeldung als User.
             if($result = @ldap_bind($ds, "uid=".$userRdn.",ou=people,".$suffix_rz, $userPwd)) {
               # Bind erfolgreich ausgeführt
               return $ds;
             } else {
               # Bind nicht erfolreich.
               if(ldap_error($ds) == "Invalid credentials") {
                 $ldapError .= "Bind nicht erfolgreich: die Zugangsdaten sind nicht korrekt.<br>\n";
               } else {
                 $ldapError .= "Bind als User nicht erfolgreich: ".ldap_error($ds)."<br>\n";
               }
               return false;
             }
           } else {
             # Anonymer Bind.
             if($result = ldap_bind($ds)) {
               # Anonymer Bind erfolgreich ausgeführt
               return $ds;
             } else {
               # Anonymer Bind nicht erfolreich.
               $ldapError .= "Anonymer Bind nicht erfolgreich: ".ldap_error($ds)."<br>\n";
               return false;
             }
           }
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
     * Sucht Einträge im LDAP-Server.
     *
     * Durchsucht den LDAP-Server vom Punkt $base ab nach Einträgen, die $filter entsprechen. Falls in $sort ein Feldname angegeben
     * wurde, so wird danach sortiert. (ACHTUNG: die Funktion ldap_sort() ist nicht dokumentiert! Ich weiß nicht ob sie Sortierung
     * nach mehreren Feldern zulässt und wie sie sich verhält, wenn zu einem Attribut mehrere Werte existieren.) $mode definiert die
     * Art der Suche, wohingegen $resultLimit und $timeout die Anzahl der Ergebnis-Einträge bzw. die maximalen Suchdauer einschränken.
     * Zurückgegeben werden die Attribute, die im Array $attributes aufgeführt sind. Im Erfolgsfalle wird ein multidimensionales Array
     * zurückgeliefert, im Fehlerfalle FALSE. Dann steht die Fehlermeldung in der Variablen $ldapError.
     *
     * @param string $base die DN, das Verzeichnis, in dem die Suche startet
     *
     * @param string $filter die Suchbedingungen
     *
     * @param array attributes die Attributnamen, deren Werte im Ergebnis enthalten sein sollen.
     *
     * @param string $sort Sortiert die Ergebnis-Einträge nach dem angegebenen Feldnamen (undokumentiert! s.o.)
     *
     * @param string $mode Der Modus: "one" liefert einen Eintrag, "list" alle Einträge des Verzeichnisses und "sub"
     *                     schließt alle Untervezeichnisse mit ein.
     *
     * @param int $resultLimit die maximale Anzahl zurückgegebener Einträge
     *
     * @param int $timeout die maximale Suchzeit, bevor der LDAP-Server abbrechen soll
     *
     * @return mixed multidimensionales array mit den Einträgen im Erfolgsfall, FALSE wenn ein Fehler auftrat
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
     # Kein gültiger Modus angegeben.
     $ldapError .= "Es wurde kein gültiger Modus angegeben.";
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
* Fügt ein neues Objekt in die LDAP-Datenbank ein.
*
* @param resource $ds Datenbankhandler
* @param string $dn Distinguished Name des neuen Eintrages
* @param array $daten Assoziatives Array mit den gewünschten Attributen
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
* Universalfunktion zum Ändern von Attributen und Werten.
* Bei Änderungsskripten muss zuerst ein Formular mit den alten Daten gefüllt werden. Die hierfür
* durchgeführte Suche wird in einem unbehandelten Array in der SESSION gespeichert und wieder
* ausgelesen, sobald die Änderungen gespeichert werden sollen. Es wird anschließend an diese Funktion
* (als $daten_alt)gegeben, die das Array mit ldapArraySauber von allen unnötigen Einträgen befreit.
* $daten_alt entspricht dann strukturell dem POST-Array des Änderungsformulars ($daten_neu).
* Letzteres wird nun durch laufen, alle Einträge werden mit ihrer Entsprechnung aus $daten_alt verglichen
* und ggf. werden dann Attribute geändert, gelöscht oder hinzugefügt.
*
* @param resource $ds Datenbankhandler
* @param string $dn Distinguished Name des Eintrages
* @param array $daten_alt Dreidimensionales mixed Array der Form $array[int][string][int], so wie es von uniLdapSearch zurückgeliefert wird.
* @param array $daten_neu Zweidimensionales mixed Array der Form $array[string][int], so wie ein Formular in $_POST gespeichert ist.
* @param int $i Gibt an, welcher Eintrag der ersten Dimension von $daten_alt verwendet werden soll. (Standard: $i=0)
*
* @return boolean TRUE wenn Änderung erfolgreich, FALSE wenn ein Fehler aufgetreten ist.
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
            $value_neu = htmlentities(str_replace(chr(160),"",trim($value_neu)));               // ungewollte Leerzeichen und &nbsp; löschen
            if (isset($daten_alt[$key])) {
				$daten_alt[$key] = str_replace(chr(160),"",trim($daten_alt[$key]));   // ungewollte Leerzeichen und &nbsp; löschen
			} else {
				$daten_alt[$key] = "";
			}
            if($daten_alt[$key] == "" && $value_neu != "") {
              # FALL 1:
              # Alter Wert ist leer, neuer Wert ist nicht leer.
              # Füge neues Attribut hinzu.
                if(ldap_mod_add($ds, $dn, array($key => $value_neu))) {
                    $meldung .= "Add successfull: ".$key." -> ".$value_neu."<br>";
                } else {
                    $meldung .= "Add error: ".$key." -> ".$value_neu."<br>";
                }

            } else if($daten_alt[$key] != "" && $value_neu == "") {
              # FALL 2:
              # Alter Wert ist nicht leer, neuer Wert ist leer.
              # Lösche Attribut.
                if(ldap_mod_del($ds, $dn, array($key => $daten_alt[$key]))) {
                    $meldung .= "Delete successfull: ".$key." -> ".$daten_alt[$key]."<br>";
                } else {
                    $meldung .= "Delete error: ".$key." -> ".$daten_alt[$key]."<br>";
                }

            } else if($daten_alt[$key] != "" && $value_neu != "" && $daten_alt[$key] != $value_neu) {
              # FALL 3:
              # Alter und neuer Wert sind nicht leer und beide sind ungleich.
              # Ändere das Attribut. Der bisherige Wert wird überschrieben.
                if(ldap_mod_replace($ds, $dn, array($key => $value_neu))) {
                    $meldung .= "Replace successfull: ".$key." -> ".$value_neu."<br>";
                } else {
                    $meldung .= "Replace error: ".$key." -> ".$value_neu."<br>";
                }

            } else {
              # In allen anderen Fällen ist keine Änderung nötig
            }
        } else {
            # Wenn $value_neu ein Array ist...
            # (d.h., das Attribut $key darf mehrere Werte annehmen)
            $value_neu = numArraySauber($value_neu);
            if (isset($daten_alt[$key])) {
				$value_alt = numArraySauber($daten_alt[$key]);
		        foreach($value_alt as $item) {
			        #$item = htmlentities($item);
				    # Lösche alle alten Werte des Attributes $key.
					if(ldap_mod_del($ds, $dn, array($key => $item))) {
	                    $meldung .= "Delete successfull: ".$key." -> ".$item."<br>";
		            } else {
	                    $meldung .= "Delete error: ".$key." -> ".$item."<br>";
		            }
	            }
			}
            foreach($value_neu as $item) {
                $item = htmlentities($item);
                # Füge alle neuen Werte des Attributes $key ein.
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
* uniLdapDelete löscht beliebige Einträge mit dessen Subtree aus der Datenbank.
* Dabei wird der wird der Baum ab dem Eintrag $dn zu allen Blättern durchlaufen (Es
* können nur Blätter gelöscht werden!!) und die Einträge von hinten her bis einschließlich
* $dn gelöscht
*
* @param resource ds LDAP Directory Handle
* @param string dn Distiguished Name
*
* @return boolean
*
* @author Daniel Höfler
*/

function uniLdapDelete($ds, $dn) {
    # Überprüfung, ob zu löschender Eintrag vorhanden ist
    if(!uniLdapSearch($ds, $dn, "objectclass=*", array("*"), "", "one", 0, 0)) {
        $ldapError .= "Löschen fehlgeschlagen: Eintrag nicht gefunden".ldap_error($ds)."<br>\n";
        return false;
    }
    # Auslesen der Daten unterhalb von $dn
    $daten = uniLdapSearch($ds, $dn, "objectclass=*", array("*"), "", "list", 0, 0);
    # for-Schleife wird nur ausgeführt, falls sich unterhalb von $dn Einträge befinden
    for($i = 0; $i < $daten['count']; $i++){
        uniLdapDelete($ds, $daten[$i]['dn']);
    }
    # löschen der Blätter
    if(ldap_delete($ds, $dn)) {
        return true;
    } else {
        $ldapError .= "Löschen fehlgeschlagen".ldap_error($ds)."<br>\n";
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
# LDAP Funktionen um alle Objekte der AU eines bestimmten Typs mit gewählten Attributen zu holen
#
function get_hosts($auDN,$attributes) 
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, "cn=computers,".$auDN, "(objectclass=Host)", $attributes, "hostname", "sub", 0, 0))) {
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
	
	if(!($result = uniLdapSearch($ds, "cn=rbs,".$auDN, "(objectclass=RBService)", $attributes, "", "list", 0, 0))) {
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

function get_dhcpsubnets($auDN,$attributes) 
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
?> 
