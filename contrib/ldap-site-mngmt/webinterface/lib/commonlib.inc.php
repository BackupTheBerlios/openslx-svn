<?php


/**
* attributesToString($entry, $name, $delemiter = "", $pattern = "", $empty = "&nbsp") -
* Gibt die Attribute eines LDAP-Eintrages formatiert aus
*
* Gibt die Attribute des Schl�ssels $name des LDAP-Eintraes $entry aus. Mehrere Werte werden mit $delemiter
* voneinander getrennt. F�r jeden Wert des Attributes wird in $pattern an die Stelle "$name" (Dallarzeichen plus die Bezeichnung)
* das aktuelle Attribut eingef�gt - �hnlich (aber nicht gleich!) der String-Interpretation von PHP. Falls $pattern = "" wird
* einfach der Wert zur�ck gegeben. Falls f�r den Schl�ssel keine Attribut-Werte definiert sind, wird $empty zur�ck gegeben
*
* @param array entry LDAP-Array
* @param string name Hashbezeichnung
* @param string delimiter Trennzeichen
* @param string pattern Muster
* @param string empty Zeichen f�r leere Felder
*
* @return string Array-Werte als String
*
* @author Timothy Burk, lt. Musterl�sung
*
*/

    function attributesToString($entry, $name, $delimiter = "", $pattern = "", $empty = "") {
        $buffer = "";
        $name=strtolower($name);
        if (isset($entry[$name])) {
            $count = $entry[$name]['count'];
            for ($i = 0; $i < $count; $i++) {
                if ($pattern) {
                    $tmp = $pattern;
                    $buffer .= str_replace('$' . $name, $entry[$name][$i], $tmp);
                } else {
                    $buffer .= $entry[$name][$i];
                }
                if ($delimiter && ($i + 1) < $count) {
                    $buffer .= $delimiter;
                }
            }
        }

        if ("" == $buffer && $empty) {
            $buffer = $empty;
        }
        return $buffer;
    }

/*
 * oneAttribute($entry, $name, $empty = "", $i = 0) {
 * liefert den ($i-ten) Wert des Attributes $name aus $entry
 * Eingabe ist entweder ein Datensatz aus dem ldapsearch-Ergebnis, oder
 * ein um die Meta-Infos (count) bereinigtes Ergebnis
 * sorry f�r die mangelhafte Doku - Thomas
 */

    function oneAttribute($entry, $name, $empty = "", $i = 0) {
        $buffer = "";
        if (isset($entry[$name][$i])) {
            $buffer = $entry[$name];
        } else if (isset($entry[$name])) {
            $buffer = $entry[$name];
        }

        if ("" == $buffer && $empty) {
            $buffer = $empty;
        }
        return $buffer;
    }


     /**
     * redirect($seconds, $url, $msg = "", $addSessionId = TRUE) - leitet den Benutzer auf eine andere Seite weiter
     *
     * Leitet den Benuzter nach $seconds Sekunden auf die Seite $url weiter. W�hrend der Wartezeit bekommt der Benutzer
     * die Information $msg mitgeteilt (Achtung: keine automatische Formatierung der $msg). Wenn $addSessionId TRUE ist,
     * dann wird an den URL die SessionId angeh�ngt.
     *
     * @author Timothy Burk, lt. Musterl�sung
     */

    function redirect($seconds, $url, $msg = "", $addSessionId = TRUE) {
        if ($addSessionId) {
            if (strpos($url, "?") === FALSE) {
                $url .= "?";
            } else  {
                $url .= "&";
            }
            $url .= SID;
        }

        echo "<html>\n" .
             "  <head>\n" .
             '    <meta http-equiv="refresh" content="' . $seconds . "; URL=$url" . '">' . "\n" .
             "  </head>\n";
        if ($msg) {
            echo "  <body>\n" .
                 $msg .
                 "  </body>\n";
        }
        echo "</html>\n";
    }



/**
* getRights($ds, $userDn) - ermittelt die Rechte eines Users.
*
* Die Funktion erwartet ein Directory-Handle und den vollst�ndigen Distiguished Name des
* Users. R�ckgabewert ist ein numerisches eindimensionales Array, welches die Rechte enth�lt.
*
* @param resource ds LDAP Directory Handle
* @param string userDn Distinguishedname des Users
*
* @return array rechte
*
* @author Timothy Burk
*/

function getRoles($ds, $userDN) {
   global $ldapError, $suffix, $uid;
   
   if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(&(member=$userDN)(cn=*))", array("dn","cn"), "dn", "sub", 0, 0))) {
       redirect(5, "index.php", $ldapError, FALSE);
       die;
   }
   $result = ldapArraySauber($result);
   $clean = array();
 
   foreach($result as $item) {
      $dn = ldap_explode_dn($item['dn'], 0);
      $dnsub = array_slice($dn,3);
      $auDN = implode(',',$dnsub); 
      $element['au'] = $auDN;
      $element['role'] = $item['cn'];
      $clean[] = $element;
   }
   
   $res = array();   
	foreach($clean as $item){           	   		   
      $au = $item['au'];
      $role = $item['role'];
      if(array_key_exists($au,$res)){
      	$res[$au][] = $role;
      }
  		else{
        	$res[$au] = array($role);
      }
	}
	$i=0;
	foreach (array_keys($res) as $key){
		$au_roles[$i]['au'] = $key;
		$au_roles[$i]['role'] = $res[$key];
		$i++;
	}
   return $au_roles; 
}


/**
* createMenu($rechte) - erstellt die Menuleiste abh�ngig von der Rechten des Users.
*
* Die Navigationsleiste wird dynamisch erzeugt und von dieser Funktion direkt in das
* entsprechende Template geparst. Dabei werden nur die Schaltfl�chen zur Verf�gung
* gestellt, die der User mit seinen Rechten anzeigen darf.
*
* @param array rechte Eindimensionales Array mit den Rechten des Users
* @param int mainnr Nummer des aktiven Hauptmenus
*
* @author Timothy Burk
*/

function createMainMenu($rollen , $mainnr) {
   
   global $template, $START_PATH, $auDN;
    
   # pre-checks
   $mipbs = get_maxipblocks_au($auDN);
   #echo "MIPB: "; print_r ($mipbs); echo "<br>";
   if ($mipbs[0] != ""){
      $dhcplink = "dhcp/dhcpsubnets.php?mnr=0";
   }else{
      $dhcplink = "dhcp/no_dhcp.php";
   }
   
   # Struktur der Registerkartenleiste
   $mainmenu = array(array("link" => "au/au.php",
                             "text" => "AU Home",
                             "zugriff" => "alle"),
                       #array("link" => "roles/roles.php",
                       #      "text" => "Admin Rollen",
                       #      "zugriff" => array("MainAdmin","DhcpAdmin")),
                       #array("link" => "ip/ip.php",
                       #      "text" => "IP Management",
                       #      "zugriff" => array("MainAdmin","HostAdmin","DhcpAdmin")),
							  array("link" => "computers/hostoverview.php?sort=hostname",
                             "text" => "Rechner",
                             "zugriff" => array("MainAdmin","HostAdmin","DhcpAdmin")),
                       array("link" => $dhcplink,
                             "text" => "DHCP",
                             "zugriff" => array("MainAdmin","DhcpAdmin")),
                       array("link" => "rbs/rbs.php",
                             "text" => "RemoteBoot/PXE",
                             "zugriff" => array("MainAdmin","RbsAdmin")),
                       array("link" => "dns/dns.php",
                             "text" => "DNS",
                             "zugriff" => array("MainAdmin","ZoneAdmin")));
	 

   # Zusammenstellen der Menuleiste
   $template->define_dynamic("Mainmenu", "Mmenu");
      $i=0;
      foreach($mainmenu as $item) {
         if($item['zugriff'] === "alle" || vergleicheArrays($rollen , $item['zugriff'])) {
            if ($i==0) {
               if ($mainnr==0) {
                  $zwisch="";
                  $lastaktive=true;
                  $farb="#505050";
               }
               else {
                  $zwisch="";
                  $farb="#A0A0A0";
                  $lastaktive=false;
               }
            }
            else {
               if ($mainnr==$i) {
                  $zwisch="";
                  $lastaktive=true;
                  $farb="#505050";
               }
               else {
                  $farb="#A0A0A0";
                  if ($lastaktive) {$zwisch="";}
                  else {$zwisch="";}
                  $lastaktive=false;
               }
            }
            $template->assign(array("MZWISCHEN" => $zwisch,
                                    "MFARBE" => $farb,
                                    "MLINK_M" => $START_PATH.$item["link"],
                                    "MTEXT_M" => $item["text"]));
            $template->parse("MAINMENU_LIST", ".Mainmenu");
         }
         $i=$i+1;
      }
      if ($lastaktive) {$template->assign(array("MENDE" => ""));}
      else {
         $template->assign(array("MENDE" => ""));
      }
      
}



/**
* vergleicheArrays($a, $b) - Ermitteln der Schnittmenge zweier Arrays
*
* @param array a
* @param array b
*
* @return boolean TRUE, wenn die Schnittmenge von a und b nicht leer ist, sonst FALSE
*
* @author Timothy Burk
*/

function vergleicheArrays($a, $b) {
    if((sizeof(array_unique($a)) + sizeof($b)) > sizeof(array_unique(array_merge($a, $b)))) {
        return TRUE;
    } else {
        return FALSE;
    }
}


/**
* inputArraySauber($Array)
*
* L�scht aus einem Array, welches POST-Daten enth�lt leere Felder. N�tig f�r die Formatierung
* vor dem Anlegen neuer Objekte.
*
* @param array _POST-Array
*
* @return array Bereinigtes Array.
*
* @author Timothy Burk
*/
function inputArraySauber($Array) {
    $b = array();
    foreach($Array as $key => $a) {
      if(!is_array($a)) {
          trim($a);
      }
      if (!$a == "") {
         if(is_array($a)) {
             $b[$key] = $a;
         } else {
             $b[$key] = htmlentities($a);
         }
      }
    }
    return $b;
}


/**
* numArraySauber($Array)
*
* L�scht aus einemn numerischen Array leere Felder.
*
* @param array Numerisches Array
*
* @return array Bereinigtes Array.
*
* @author Timothy Burk
*/
function numArraySauber($Array) {
    $b = array();
    $arr = array();
    if(!(is_array($Array))) {
      $arr[] = $Array;
    } else {
      $arr = $Array;
    }
    foreach($arr as $key => $a) {
      if (!$a == "") {
         $b[] = $a;
      }
    }
    return $b;
}

/**
* ldapArraySauber($Array, [$delEmpty])
*
* Bereinigt ein dreidimensionales Array, so wie es aus der Funktion uniLdapSearch kommt.
* Dabei werden alle count-Felder sowie alle numerischen Felder in denen der Schl�ssel
* gespeichert ist entfernt. Attributarrays mit nur einem Element werden gel�scht, das Element
* wir als Skalar gespeichert.
* Wenn $delEmpty = TRUE ist, werden nur nichtleere Felder gespeichert.
*
* @param array $Array uniLdapSearch()-Ausgabe
* @param boolean $delEmpty (Standard: $delEmpty = FALSE)
*
* @return array Bereinigtes Array.
*
* @author Timothy Burk
*/
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

/**
* personOptionen($rechte)
*
* Enth�lt die m�glichen Optionen, die auf einen User angewandt werden k�nnen als
* zweidimensionales Array mit folgenden Attributen:
* [ziel]: Aufzurufendes PHP-Skript
* [text]: Beschriftung der Schaltfl�che
* [desc]: Beschreibung der Funktion
* [rechte][]: Array mit den erforderlichen Rechten f�r die jeweilige Option. array("alle") steht f�r "ohne Einschr�nkung".
*
* Dieses in dieser Funktion gespeicherte Array wird abh�ngig von den �bergebenen
* Rechten um nicht erlaubte Optionen reduziert und dann ausgegeben.
*
* @param array $rechte Eindimensionales Array $_SESSION['rechte']
*
* @return array Zweidimensionales Array mit den erlaubten Optionen.
*
* @author Timothy Burk
*/
function personOptionen($rechte) {
    global $utc_uid, $utc_cn, $START_PATH;
    $optionen = array();
    $optionen[] = array("ziel" => $START_PATH."person/datensatz.php?aktion=edit",
                        "text" => "Userdaten bearbeiten",
                        "desc" => "Anzeigen und �ndern der pers�nlichen Daten des Users.",
                        "rechte" => array("writeMitarbeiter"),
                        "hidden" => array("aktion" => "edit"));
    $optionen[] = array("ziel" => $START_PATH."person/datensatz.php",
                        "text" => "Datensatz l�schen",
                        "desc" => "Der User wird vollst�ndig mit allen Daten aus der Datenbank gel�scht.",
                        "rechte" => array("writeMitarbeiter"),
                        "hidden" => array("aktion" => "delete"));
    $optionen[] = array("ziel" => $START_PATH."person/datensatz.php",
                        "text" => "User (de)aktivieren",
                        "desc" => "Diese Funktion legt einen User durch die Deaktivierung im Archiv ab. Von dort kann der Datensatz weiterhin eingesehen und ggf. reaktiviert werden.",
                        "rechte" => array("writeMitarbeiter"),
                        "hidden" => array("aktion" => "archiv"));
    $optionen[] = array("ziel" => $START_PATH."person/vertrag_show.php",
                        "text" => "Vertr�ge bearbeiten",
                        "desc" => "Bearbeiten oder Anlegen eines Vertrages. Sie k�nnen dabei zwischen verschiedenen Vertragsarten w�hlen.",
                        "rechte" => array("writeVertrag", "readVertrag"));
    $optionen[] = array("ziel" => $START_PATH."urlaub/krank_angabe.php",
                        "text" => "Krankheitstage",
                        "desc" => "Krankheitsdaten bearbeiten.",
                        "rechte" => array("writeKrankheitUrlaub"),
                        "hidden" => array("uidToChange" => $utc_uid, "GName" => $utc_cn));
    $optionen[] = array("ziel" => $START_PATH."urlaub/liste.php",
                        "text" => "Urlaubstage anzeigen",
                        "desc" => "Urlaubstage des Users in grafischer �bersicht anzeigen.",
                        "rechte" => array("readKrankheitUrlaub"),
                        "hidden" => array("wer" => $utc_uid, "wann" => "g", "sub" => $utc_cn));
    $optionen[] = array("ziel" => $START_PATH."person/rechte_show.php",
                        "text" => "Rechte vergeben",
                        "desc" => "Diese Option dient dazu, dem User bestimmte Rechte zuzuweisen, beispielsweise das Recht Urlaub zu beantragen, Vertragsdaten andere User zu bearbeiten oder einzusehen usw..",
                        "rechte" => array("writeRechte"));
    $optionen[] = array("ziel" => $START_PATH."person/suchen.php",
                        "text" => "Abbrechen",
                        "desc" => "&nbsp;",
                        "rechte" => array("alle"));

    $opt_reduced = array();
    foreach($optionen as $option) {
        if(in_array("alle",$option['rechte']) || vergleicheArrays($option['rechte'],$rechte)) {
            array_push($opt_reduced, $option);
        }
    }
    return $opt_reduced;
}


/**
* makeArrFromAttribute($a, $attribute)
*
* Ein zweidimensionales Array wird nach der ersten Dimension durchlaufen.
* Dabei werden die Werte des angegebenen Attributes $attribute f�r alle
* Eintr�ge extrahiert und in einem neuen Array gespeichert, welches
* anschlie�end zur�ckgegeben wird.
*
* @param array $a Zweidimensionales Array
* @param string $attribute Schl�sselname der zweiten Dimension
*
* @return array Eindimensionales numerisches Array mit den Attributwerten.
*
* @author Timothy Burk
*/
function makeArrFromAttribute($a, $attribute) {
    $c = array();
    foreach($a as $b) {
        $c[] = $b[$attribute];
    }
    return $c;
}
?>

<?php


/**
*  sortArrayByKey sortiert die 1.Dimension von bis zu 5-dimensionalen Arrays
*  nach den Werten in einem beliebigen Schl�ssel in beliebiger Dimension
*
*  PS: die Funktion sortArrayByKey ist nur sinnvoll, wenn sich die Array-Eintr�ge
*      der 1.Dim sehr �hnlich sind, sprich bei Suchergebnissen!!
*
*  @param array $array : das zu sortierende Array
*  @param string $sortKey : der Schl�ssel, nach dem sortiert werden soll
*                           Bsp.:
*                           es soll nach $array[$i][$j][$k]['sortkey'] sortiert werden
*                          => $sortKey = "$j#$k#sortkey"
*  @param string $sortDirection : die Sortierrichtung, g�ltige Werte sind "up", "down"
*
*
*  @author Daniel H�fler
*/
function sortArrayByKey($array, $sortKey, $sortDirection = "up") {
    $sortKeyArray = explode("#", $sortKey);
    $count = count($sortKeyArray);
    if($count < 5) {
        switch($count) {
            case 0:
                foreach($array as $key => $item) {
                $toSortKeys[$key] = $item;
                }
                break;
            case 1:
                foreach($array as $key => $item) {
                $toSortKeys[$key] = $item[$sortKeyArray[0]];
                }
                break;
            case 2:
                foreach($array as $key => $item) {
                $toSortKeys[$key] = $item[$sortKeyArray[0]][$sortKeyArray[1]];
                }
                break;
            case 3:
                foreach($array as $key => $item) {
                $toSortKeys[$key] = $item[$sortKeyArray[0]][$sortKeyArray[1]][$sortKeyArray[2]];
                }
                break;
            case 4:
                foreach($array as $key => $item) {
                $toSortKeys[$key] = $item[$sortKeyArray[0]][$sortKeyArray[1]][$sortKeyArray[2]][$sortKeyArray[3]];
                }
                break;
        }
    } else {
        echo "zu viele Dimensionen!! H�chstens 4 Dimensionen m�glich";
        return false;
    }
    if($sortDirection == "up") {
        asort($toSortKeys);
    } elseif($sortDirection == "down") {
        arsort($toSortKeys);
    } else {
        echo "Keine g�ltige Sortierrichtung!!    W�hlen sie \"up\" oder \"down\"\n";
        return false;
    }
    $sortArray = array();
    foreach($toSortKeys as $key => $item) {
        $sortArray[$key] = $array[$key];
    }
    return($sortArray);
}

?>