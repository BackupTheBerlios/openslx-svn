<?php
/**
* login_sicher.php führt einen Bind mit den eingegebenen Benutzerdaten durch.
* Dabei erfolgt die initiale Authentifizierung am RZ-LDAP und am LSM-LDAP. Zentral geänderte
* Passwörter werden bei Abweichung in den LSM-LDAP nachgezogen.
* Bei erfolgreichem nicht anonymem Bind werden die Benutzerrechte ausgelesen und davon abhängig
* die entsprechende Administrativen Bereiche (AU) auf der Startseite präsentiert. 
* dn, uid, userPassword, cn und die Rechte (Rollen) werden in der Session gespeichert, so dass
* alle weiteren Binds am LSM LDAP mittels dieser Daten erfolgen.
*/
session_cache_expire(30);
session_start();

# Bibliotheken einbinden
include("lib/ldap.inc.php");
include("lib/commonlib.inc.php");

$uid = $_POST['uid'];
$userPassword = $_POST['userPassword'];
# $userDn_rz = "uid=".$uid.",ou=people,".$suffix_rz;
$userDN = "uid=".$uid.",ou=people,".$suffix;
#echo "uid: "; print_r($uid); echo "<br>";
#echo "pw: "; print_r($userPassword); echo "<br>";

checkLogin($uid,$userPassword);

/**
* checkLogin($uid, $userPassword) - Authentifizierung am RZ-LDAP und LSM-LDAP
*
* Wenn RZ-LDAP-Login UND LSM-LDAP-Login erfolgreich sind, dann ist der User
* bereits im LSM-LDAP eingetragen.
* -> Mache Datenabgleich und anschließenden Login am LSM-LDAP
* Wenn RZ-LDAP-Login erfolgreich, LSM-LDAP-Login jedoch nicht erfolgreich ist,
* dann unterscheide zwischen zwei Möglichkeiten:
* 1. Der User ist im LSM-LDAP nicht angelegt,
* 2. Der User ist im LSM-LDAP zwar angelegt, aber das Passwort wurde auf dem RZ-LDAP inzwischen geändert.
* -> Login als Dummy und Check, ob UID vorhanden
* Wenn RZ-LDAP-Login nicht erfolgreich, LSM-LDAP-Login jedoch erfolgreich ist,
* dann ist der User auf dem RZ-LDAP nicht gespeichert.
* -> Login am LSM-LDAP
* In anderen Fällen waren die Zugangsdaten nicht korrekt.
* -> Redirect auf index.php.
*
* @param string UID
* @param string Password
*
* @see userLogin()
* @see datenabgleich()
* @see dummyUidCheck()
* @see userAnlegen()
*
* @author Timothy Burk
*/

function checkLogin($uid = "", $userPassword = "") {
    global $userDn_rz, $userDN, $suffix, $suffix_rz, $ldapError, $standpwd;
    # Abfrage, ob das Loginformular Daten enthält
    if (!(($uid == "") || ($userPassword == ""))) {
        # UID und Passwort wurden eingegeben
        # Fallunterscheidung welche Logins möglich sind
		  if ( $ds_rz = rzLdapConnect($uid,$userPassword) ) {
            # RZ-LDAP-Login erfolgreich,
            # -> Mache Datenabgleich und anschließenden Login am LSM-LDAP
            datenabgleich($uid, $ds_rz);
            ldap_unbind($ds_rz);
 			# echo "RZ Bind OK<br>";
            if (dummyUidCheck($uid)) {
            	 userLogin($uid, $standpwd);
            } else {
            	 # Nachricht User melden bei ... d.h. von Hand anlegen zur Kontrolle
                #userAnlegen($uid,$userPassword,$ds_rz);
	             ldap_unbind($ds_rz);
	             redirect(3, "index.php", "<h3>Benutzer lokal nicht angelegt!<h3>".$ldapError, FALSE);
            	 die;
            }
        } elseif (!($ds_rz = rzLdapConnect($uid,$userPassword)) && ($ds = uniLdapConnect($uid,$userPassword)))  {
            # Wenn RZ-LDAP-Login nicht erfolgreich, LSM-LDAP-Login erfolgreich,
            # dann ist der User auf dem RZ-LDAP nicht gespeichert.
            # -> Login am LSM-LDAP (z.B. für lokale Spezialuser ... )
 			# echo "RZ Bind FAILED / LSM Bind OK<br>";
            ldap_unbind($ds);
            userLogin($uid, $userPassword);
        } else {
            # In anderen Fällen waren die Zugangsdaten nicht korrekt.
            # -> Redirect auf index.php.
            redirect(3, "index.php", "<h3>Bitte geben Sie korrekte Zugangsdaten ein.<h3>".$ldapError, FALSE);
            die;
        }

    } else {
        # UID und/oder Passwort wurden NICHT eingegeben
        redirect(3, "index.php", "<h3>Bitte geben Sie User-Id und Passwort ein.</h3>".$ldapError, FALSE);
        die;
    }
}


/**
* dummyUidCheck($uid) - überprüft, ob UID im LSM-LDAP vorhanden ist.
*
* Über den Dummyuser wird eine Verbindung zum LSM-LDAP aufgebaut und die angegebene
* UID wird gesucht.
*
* @param string UID
*
* @return boolean TRUE = UID vorhanden, FALSE = UID nicht gefunden
*/
function dummyUidCheck($uid) {
    global $userDN, $suffix, $ldapError, $dummyUid, $dummyPassword;
    # Bei Erfolg stellen wir eine Verbindung mit unserem LDAP her. Dazu nutzen wir den Dummy:
    if(!($ds_dummy = uniLdapConnect($dummyUid, $dummyPassword))) {
        redirect(5, "index.php", "Dummy-Login fehlgeschlagen!<br>".$ldapError, FALSE);
        die;
    }
    # Im nächsten Schritt wird überprüft, ob ein Eintrag mit der UID $uid schon vorliegt:
    if(!($person_daten = uniLdapSearch($ds_dummy, "ou=people,".$suffix, "uid=$uid", array(""), "", "list", 0, 0))) {
        redirect(5, "index.php", $ldapError, FALSE);
        die;
    }
    if($person_daten['count'] == 0) {
        # Eintrag ist nicht vorhanden. -> Anlegen
        ldap_unbind($ds_dummy);
        return FALSE;
    } else {
        ldap_unbind($ds_dummy);
        return TRUE;
    }
}

/**
* userAnlegen($uid,$userPassword,$ds_rz)
*
* Legt mithilfe des Dummyusers einen noch nicht lokal geführten User im LSM-LDAP
* mit den nötigen Daten des Rechenzentrums-Usereintrags an.
*
* @param string UID
* @param string Password
* @param resource RZ-LDAP Directory Handle
*/
function userAnlegen($uid,$userPassword,$ds_rz) {
    global $userDN, $suffix, $suffix_rz, $ldapError, $dummyUid, $dummyPassword;
    # Bei Erfolg stellen wir eine Verbindung mit unserem LDAP her. Dazu nutzen wir den Dummy:
    if(!($ds_dummy = uniLdapConnect($dummyUid, $dummyPassword))) {
        redirect(5, "index.php", "Dummy-Login fehlgeschlagen!<br>".$ldapError, FALSE);
        die;
    }
    # Im nächsten Schritt wird überprüft, ob ein Eintrag mit der UID $uid schon vorliegt:
    $ruffelder = array("uid", "sn", "givenname", "userpassword");

    if(!($person_daten = uniLdapSearch($ds_rz, "ou=people,".$suffix_rz, "uid=$uid", $ruffelder, "", "list", 0, 0))) {
        redirect(5, "index.php", $ldapError, FALSE);
        die;
    }
    $person_daten = ldapArraySauber($person_daten);
    $person_daten = $person_daten[0];
    #print_r($person_daten);
    foreach($ruffelder as $ruffeld) {
        $ruffeld = str_replace("ruf","",$ruffeld);
        $lsmfelder[] = $ruffeld;
    }
    $i = 0;
    $neuerEintrag = array();
    $neuerEintrag['objectClass'][] = "top";
	 $neuerEintrag['objectClass'][] = "inetOrgPerson";
    foreach($lsmfelder as $lsmfeld) {
        if (isset($person_daten[$ruffelder[$i]])) {
            $neuerEintrag[$lsmfeld] = $person_daten[$ruffelder[$i]];
        } else {
            $neuerEintrag[$lsmfeld] = '';
        }
        $i++;
    }
    # CN erstellen
    $neuerEintrag['cn'] = $neuerEintrag['givenname']." ".$neuerEintrag['sn'];
    $neuerEintrag = inputArraySauber($neuerEintrag);
    #echo "<br>";print_r($neuerEintrag);echo "<br>";
    
    if(!($add = ldap_add($ds_dummy, $userDN, $neuerEintrag))) {
        redirect(50, "index.php", "<b>Eintrag nicht erfolgreich</b><br>".$ldapError, FALSE);
        die;
    }
}

/**
* datenabgleich($uid, $userPassword, $ds_rz, $ds) - überschreibt bei jedem Login die Daten des
* LSM-LDAP mit denen des RZ-LDAP mithilfe des Dummyusers.
*
* @param string UID
* @param string Password
* @param resource ds_rz RZ-LDAP Directory Handle
* @param resource ds LSM-LDAP Directory Handle nach Bind mit Dummyuser
*/
function datenabgleich($uid, $ds_rz) {
    global $userDN, $suffix, $suffix_rz, $ldapError, $dummyUid, $dummyPassword;
    
    if(!($ds_dummy = uniLdapConnect($dummyUid, $dummyPassword))) {
        redirect(5, "index.php", "Dummy-Login fehlgeschlagen!<br>".$ldapError, FALSE);
        die;
    }
    
    $ruffelder = array("sn", "givenname");
	
	 # RZ Personendaten
    if(!($rz_person_daten = uniLdapSearch($ds_rz, "ou=people,".$suffix_rz, "uid=$uid", $ruffelder, "", "list", 0, 0))) {
        redirect(5, "index.php", $ldapError, FALSE);
        die;
    }
    $rz_person_daten = ldapArraySauber($rz_person_daten);
    $rz_person_daten = $rz_person_daten[0];
    #print_r($rz_person_daten); echo "<br>";
    # LSM Personendaten
    if(!($lsm_person_daten = uniLdapSearch($ds_dummy, "ou=people,".$suffix_rz, "uid=$uid", $ruffelder, "", "list", 0, 0))) {
        redirect(5, "index.php", $ldapError, FALSE);
        die;
    }
    $lsm_person_daten = ldapArraySauber($lsm_person_daten);
    $lsm_person_daten = $lsm_person_daten[0];
    #print_r($lsm_person_daten); echo "<br>";
    
    foreach($ruffelder as $ruffeld) {
        $ruffeld = str_replace("ruf","",$ruffeld);
        $lsmfelder[] = $ruffeld;
    }
    $i = 0;
    $modEintrag = array();
    foreach($lsmfelder as $lsmfeld) {
        if ( $rz_person_daten[$ruffelder[$i]] != $lsm_person_daten[$ruffelder[$i]]) {
            $eintrag = $rz_person_daten[$ruffelder[$i]];
            $change = 1;
        } else {
            $eintrag = '';
        }
        $modEintrag[$lsmfeld] = $eintrag; //$person_daten[$ruffelder[$i]];
        $i++;
    }
    # CN erstellen
    $modEintrag['cn'] = $rz_person_daten['givenname']." ".$rz_person_daten['sn'];
    $modEintrag = inputArraySauber($modEintrag);
	 #echo "<br>"; print_r($modEintrag); echo "<br>";
    
    if(ldap_mod_replace($ds_dummy, $userDN, $modEintrag)) {
        $meldung = "Daten abgeglichen";
    }else{
    	  $meldung = "Fehler beim Datenabgleich!";
    }

}

/**
* userLogin($uid, $userPassword) - Führt den Login am LSM-LDAP durch.
*
* Nach erfolgreicher Identifikation und ggf. neuem Anlegen oder Datenabgleich wird
* mit userLogin() der Bind am LSM-LDAP durchgeführt.
* Die Rechte und der CN des Users werden ausgelesen und in der Session gespeichert.
* Anschließend leitet das Skript auf die Startseite (start.php) weiter.
*
* @param string UID
* @param string Password
*/
function userLogin($uid, $userPassword) {

    global $userDN, $suffix, $ldapError;

    # Verbindung mit der Datenbank herstellen
    if(($uid == "") || ($userPassword == "") || !($ds = uniLdapConnect($uid,$userPassword))) {
      redirect(3, "index.php", "Falscher Login<br>".$ldapError, FALSE);
      die;
    }
    
    # cn abfragen
    if(!($person_daten = uniLdapSearch($ds, "ou=people,".$suffix, "uid=$uid", array("cn"), "", "list", 0, 0))) {
      redirect(3, "index.php", $ldapError, FALSE);
      die;
    } else {
      $cn = str_replace('\"', '', $person_daten[0]['cn'][0]);
    }

    # Speichern der Sessionvariablen
    $_SESSION['uid'] = $uid;
    $_SESSION['userPassword'] = $userPassword;
    $_SESSION['dn'] = $userDN;
    $_SESSION['cn'] = $cn;
    $_SESSION['audn'] = "";
    $_SESSION['status'] = "in";
    $_SESSION['error'];

    # LDAP-Bind aufheben
    ldap_unbind($ds);
	 
	 $mesg = "<html>
				<head>
					<title>AdminUnit Management</title>
					<link rel='stylesheet' href='styles.css' type='text/css'>
				</head>
				<body>
				<table border='0' cellpadding='200' cellspacing='0' width='100%'> 
				<tr valign='middle'><td align='center'>
	 			<h3>Bitte einen Moment Geduld, die Seite wird geladen ... <br>
	 			Falls nicht, klicken Sie bitte <a href='start.php'>hier</a>.<h3>
	 			</td></tr>
	 			</table>
	 			</body>
				</html>";
				
   # Redirect auf die Startseite:
   redirect(2, "start.php", $mesg, TRUE);
}


?>
