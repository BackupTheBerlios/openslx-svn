<?php
/**
* login_sicher.php führt einen Bind mit den eingegebenen Benutzerdaten durch.
* Dabei erfolgt die Authetifizierung entsprechend der Ausführung bei der Präsentation des Projektes
* am RZ-LDAP. Das Passwort des Users wird aber nun nicht mehr auf dem Gruppe1 LDAP gespeichert. Dort
* legt das Skript ein Standardpasswort an.
* Im Fehlerfall wird eine Meldung ausgegeben und anschließend auf index.php weitergeleitet.
* Bei erfolgreichem nicht anonymem Bind werden die Benutzerrechte ausgelesen und davon abhängig
* die entsprechende Startseite aufgerufen. dn, uid, userPassword, cn und die Rechte werden in
* einer Session gespeichert.
*
* DIESE VERSION IST AKTUELL IM EINSATZ!!!!
*
* @version V3.2
* @author Timothy Burk
*/
session_cache_expire(30);
session_start();

# LDAP-Bibliothek einbinden
include("lib/ldap.inc.php");
# Standard-Bibliothek einbinden
include("lib/commonlib.inc.php");

$uid = $_POST['uid'];
$userPassword = $_POST['userPassword'];
# $userDn_rz = "uid=".$uid.",ou=people,".$suffix_rz;
$userDN = "uid=".$uid.",ou=people,".$suffix;

#echo "uid: "; print_r($uid); echo "<br>";
#echo "pw: "; print_r($userPassword); echo "<br>";

checkLogin($uid,$userPassword);

/**
* checkLogin($uid, $userPassword) - Authentifizierung am RZ-LDAP und Gruppe1-LDAP
*
* Wenn RZ-LDAP-Login UND Gruppe1-LDAP-Login erfolgreich sind, dann ist der User
* bereits im Gruppe1-LDAP eingetragen.
* -> Mache Datenabgleich und anschließenden Login am Gruppe1-LDAP
* Wenn RZ-LDAP-Login erfolgreich, Gruppe1-LDAP-Login jedoch nicht erfolgreich ist,
* dann unterscheide zwischen zwei Möglichkeiten:
* 1. Der User ist im Gruppe1-LDAP nicht angelegt,
* 2. Der User ist im Gruppe1-LDAP zwar angelegt, aber das Passwort wurde auf dem RZ-LDAP inzwischen geändert.
* -> Login als Dummy und Check, ob UID vorhanden
* Wenn RZ-LDAP-Login nicht erfolgreich, Gruppe1-LDAP-Login jedoch erfolgreich ist,
* dann ist der User auf dem RZ-LDAP nicht gespeichert.
* -> Login am Gruppe1-LDAP
* In anderen Fällen waren die Zugangsdaten nicht korrekt.
* -> Redirect auf index.php.
*
* Schema siehe auch /home/gruppe1/Praesentation/Login und Personen.pps
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
    global $userDn_rz, $userDN, $suffix, $suffix_rz, $ldapError, $standardPassword;
    # Abfrage, ob das Loginformular Daten enthält
    if(!(($uid == "") || ($userPassword == ""))) {
        # UID und Passwort wurden eingegeben
        # Fallunterscheidung welche Logins möglich sind
		  /* if(($ds_rz = rzLdapConnect($uid,$userPassword)) && ($ds = uniLdapConnect($uid, $standardPassword))) {
            # Wenn RZ-LDAP-Login UND Gruppe1-LDAP-Login erfolgreich sind, dann ist der User
            # bereits im Gruppe1-LDAP eingetragen.
            # -> Mache Datenabgleich und anschließenden Login am Gruppe1-LDAP
            datenabgleich($uid, $userPassword, $ds_rz, $ds);
            ldap_unbind($ds);
            ldap_unbind($ds_rz);
            $userPassword = $standardPassword;
            userLogin($uid, $userPassword);
        } else if(($ds_rz = rzLdapConnect($uid,$userPassword)) && !($ds = uniLdapConnect($uid, $standardPassword))) {
            # Wenn RZ-LDAP-Login erfolgreich, Gruppe1-LDAP-Login jedoch nicht erfolgreich ist,
            # dann unterscheide zwischen zwei Möglichkeiten:
            # 1. Der User ist im Gruppe1-LDAP nicht angelegt,
            # 2. Der User ist im Gruppe1-LDAP zwar angelegt, aber das Passwort wurde auf dem RZ-LDAP
            #    inzwischen geändert.
            # -> Login als Dummy und Check, ob UID vorhanden
            if(dummyUidCheck($uid)) {
                #changePassword($uid,$userPassword);
                $userPassword = $standardPassword;
            } else {
                userAnlegen($uid,$userPassword,$ds_rz);
            }
            ldap_unbind($ds_rz);
            $userPassword = $standardPassword;
            checkLogin($uid, $userPassword);
        } else if(!($ds_rz = rzLdapConnect($uid,$userPassword)) && */ if ($ds = uniLdapConnect($uid,$userPassword)) {
            # Wenn RZ-LDAP-Login nicht erfolgreich, Gruppe1-LDAP-Login jedoch erfolgreich ist,
            # dann ist der User auf dem RZ-LDAP nicht gespeichert.
            # -> Login am Gruppe1-LDAP
            ldap_unbind($ds);
            userLogin($uid, $userPassword);
        } else {
            # In anderen Fällen waren die Zugangsdaten nicht korrekt.
            # -> Redirect auf index.php.
            redirect(5, "index.php", "Bitte geben Sie korrekte Zugangsdaten ein.<br>".$ldapError, FALSE);
            die;
        }

    } else {
        # UID und/oder Passwort wurden NICHT eingegeben
        redirect(5, "index.php", "Bitte geben Sie User-Id und Passwort ein.<br>".$ldapError, FALSE);
        die;
    }
}

/**
* dummyUidCheck($uid) - Überprüft, ob UID im Gruppe1-LPAD vorhanden ist.
*
* Über den Dummyuser wird eine Verbindung zum Gruppe1-LDAP aufgebaut und die angegebene
* UID wird gesucht.
*
* @param string UID
*
* @return boolean TRUE = UID vorhanden, FALSE = UID nicht gefunden
*
* @author Timothy Burk
*/
function dummyUidCheck($uid) {
    global $userDn, $suffix, $suffix_rz, $ldapError, $dummyUid, $dummyPassword;
    # Bei Erfolg stellen wir eine Verbindung mit unserem LDAP her. Dazu nutzen wir den Dummy:
    if(!($ds_dummy = uniLdapConnect($dummyUid, $dummyPassword))) {
        redirect(5, "index.php", "Dummy-Login fehlgeschlagen!<br>".$ldapError, FALSE);
        die;
    }
    # Im nächsten Schritt wird überprüft, ob ein Eintrag mit der UID $uid schon vorliegt:
    if(!($person_daten = uniLdapSearch($ds_dummy, "ou=people,".$suffix, "uid=$uid", array("*"), "", "list", 0, 0))) {
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
* Legt mithilfe des Dummyusers einen noch nicht bei uns geführten User im Gruppe1-LDAP
* mit den Daten des Rechenzentrums an. Das Passwort ist dabei für alle User in der config.inc.php festgelegt.
*
* @param string UID
* @param string Password
* @param resource RZ-LDAP Directory Handle
*
* @author Timothy Burk
*/
function userAnlegen($uid,$userPassword,$ds_rz) {
    global $userDn_rz, $userDn, $suffix, $suffix_rz, $ldapError, $dummyUid, $dummyPassword, $standardPassword;
    # Bei Erfolg stellen wir eine Verbindung mit unserem LDAP her. Dazu nutzen wir den Dummy:
    if(!($ds_dummy = uniLdapConnect($dummyUid, $dummyPassword))) {
        redirect(5, "index.php", "Dummy-Login fehlgeschlagen!<br>".$ldapError, FALSE);
        die;
    }
    # Im nächsten Schritt wird überprüft, ob ein Eintrag mit der UID $uid schon vorliegt:
    $ruffelder = array("uid", "sn", "givenname", "uidnumber", "gidnumber", "homedirectory", "loginshell", "rufnutzernummer", "rufanrede", "rufeinrichtung", "rufmatnr", "rufaccounttype", "ruffakultaet", "mail", "rufdienst");

    if(!($person_daten = uniLdapSearch($ds_rz, "ou=people,".$suffix_rz, "uid=$uid", $ruffelder, "", "list", 0, 0))) {
        redirect(5, "index.php", $ldapError, FALSE);
        die;
    }
    $person_daten = ldapArraySauber($person_daten);
    $person_daten = $person_daten[0];
    foreach($ruffelder as $ruffeld) {
        $ruffeld = str_replace("ruf","",$ruffeld);
        if($ruffeld == "accounttype") {
            $gruppe1felder[] = "employeetype";
        } else if($ruffeld == "anrede") {
            $gruppe1felder[] = "title";
        } else {
            $gruppe1felder[] = $ruffeld;
        }
    }
    $i = 0;
    $neuerEintrag = array();
    foreach($gruppe1felder as $gruppe1feld) {
        if (isset($person_daten[$ruffelder[$i]])) {
            $neuerEintrag[$gruppe1feld] = $person_daten[$ruffelder[$i]];
        } else {
            $neuerEintrag[$gruppe1feld] = '';
        }
        $i++;
    }
    if($neuerEintrag['employeetype'] != "student") {
        unset($neuerEintrag['employeetype']);
    } else {
        $neuerEintrag['employeetype'] = ucfirst($neuerEintrag['employeetype']);
    }
    $neuerEintrag['userPassword'] = $userPassword;
    # Ermitteln der Initialen: Erster Buchstabe des Vornamens und erster Buchstabe des Nachnamens
    $neuerEintrag['initials'] = substr($neuerEintrag['givenname'],0,1).".".substr($neuerEintrag['sn'],0,1).".";

    # CN erstellen
    $neuerEintrag['cn'] = $neuerEintrag['givenname']." ".$neuerEintrag['sn'];

    # Aktiv setzen
    $neuerEintrag['aktiv'] = "yes";
    $neuerEintrag = inputArraySauber($neuerEintrag);

    # Festes Sicherungspasswort setzen
    $neuerEintrag['userPassword'] = $standardPassword;
    if(!($add = uniLdapAdd($ds_dummy, $userDn, $neuerEintrag, "personen"))) {
        redirect(5, "index.php", "<b>Eintrag nicht erfolgreich</b><br>".$ldapError, FALSE);
        die;
    }
}

/**
* datenabgleich($uid, $userPassword, $ds_rz, $ds) - Überschreibt bei jedem Login die Daten des
* Gruppe1-LDAP mit denen des RZ-LDAP mithilfe des Dummyusers.
*
* @param string UID
* @param string Password
* @param resource ds_rz RZ-LDAP Directory Handle
* @param resource ds Gruppe1-LDAP Directory Handle nach Bind mit Dummyuser
*
* @author Timothy Burk
*/
function datenabgleich($uid, $userPassword, $ds_rz, $ds) {
    global $userDn_rz, $userDn, $suffix, $suffix_rz, $ldapError, $dummyUid, $dummyPassword, $standardPassword;
    # Bei Erfolg stellen wir eine Verbindung mit unserem LDAP her. Dazu nutzen wir den Dummy:
    if(!($ds_dummy = uniLdapConnect($dummyUid, $dummyPassword))) {
        redirect(5, "index.php", "Dummy-Login fehlgeschlagen!<br>".$ldapError, FALSE);
        die;
    }
    # Im nächsten Schritt wird überprüft, ob ein Eintrag mit der UID $uid schon vorliegt:
    $ruffelder = array("uid", "sn", "givenname", "uidnumber", "gidnumber", "homedirectory", "loginshell", "rufnutzernummer", "rufanrede", "rufeinrichtung", "rufmatnr", "rufaccounttype", "ruffakultaet", "mail", "rufdienst");

    if(!($person_daten = uniLdapSearch($ds_rz, "ou=people,".$suffix_rz, "uid=$uid", $ruffelder, "", "list", 0, 0))) {
        redirect(5, "index.php", $ldapError, FALSE);
        die;
    }
    $person_daten = ldapArraySauber($person_daten);
    $person_daten = $person_daten[0];
    foreach($ruffelder as $ruffeld) {
        $ruffeld = str_replace("ruf","",$ruffeld);
        if($ruffeld == "accounttype") {
            $gruppe1felder[] = "employeetype";
        } else if($ruffeld == "anrede") {
            $gruppe1felder[] = "title";
        } else {
            $gruppe1felder[] = $ruffeld;
        }
    }
    $i = 0;
    $neuerEintrag = array();
    foreach($gruppe1felder as $gruppe1feld) {
        if (isset($person_daten[$ruffelder[$i]])) {
            $eintrag = $person_daten[$ruffelder[$i]];
        } else {
            $eintrag = '';
        }
        $neuerEintrag[$gruppe1feld] = $eintrag; //$person_daten[$ruffelder[$i]];
        $i++;
    }

    if($neuerEintrag['employeetype'] != "student") {
        unset($neuerEintrag['employeetype']);
    } else {
        $neuerEintrag['employeetype'] = ucfirst($neuerEintrag['employeetype']);
    }
    $neuerEintrag['userPassword'] = $userPassword;
    # Ermitteln der Initialen: Erster Buchstabe des Vornamens und erster Buchstabe des Nachnamens
    $neuerEintrag['initials'] = substr($neuerEintrag['givenname'],0,1).".".substr($neuerEintrag['sn'],0,1).".";

    # CN erstellen
    $neuerEintrag['cn'] = $neuerEintrag['givenname']." ".$neuerEintrag['sn'];

    # Aktiv setzen
    $neuerEintrag['aktiv'] = "yes";
    $neuerEintrag = inputArraySauber($neuerEintrag);

    # Festes Sicherungspasswort setzen
    $neuerEintrag['userPassword'] = $standardPassword;

    if(!($alteDaten = uniLdapSearch($ds_dummy, "ou=people,".$suffix, "uid=$uid", array("*"), "", "list", 0, 0))) {
        redirect(5, "index.php", $ldapError, FALSE);
        die;
    }

    if(uniLdapModify($ds_dummy, $userDn, $alteDaten, $neuerEintrag, 0)) {
        $meldung = "Daten abgeglichen";
    }

}

/**
* userLogin($uid, $userPassword) - Führt den Login am Gruppe1-LDAP durch.
*
* Nach erfolgreicher Identifikation und ggf. neuem Anlegen oder Datenabgleich wird
* mit userLogin() der Bind am Gruppe1-LDAP durchgeführt.
* Die Rechte und der CN des Users werden ausgelesen und in der Session gespeichert.
* Anschließend leitet das Skript auf die Startseite der Verwaltung (person_daten_show.php) weiter.
*
* @param string UID
* @param string Password
*
* @author Timothy Burk
*/
function userLogin($uid, $userPassword) {
    global $userDN, $suffix, $ldapError;
    # Verbindung mit der Datenbank herstellen
    if(($uid == "") || ($userPassword == "") || !($ds = uniLdapConnect($uid,$userPassword))) {
      redirect(5, "index.php", "Falscher Login<br>".$ldapError, FALSE);
      die;
    }
    
    # cn abfragen
    $cn = "Gast";
    if(!($person_daten = uniLdapSearch($ds, "ou=people,".$suffix, "uid=$uid", array("cn"), "", "list", 0, 0))) {
      redirect(5, "index.php", $ldapError, FALSE);
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

    # LDAP-Bind aufheben
    ldap_unbind($ds);
	 
	 $mesg = "<html>
				<head>
					<title>AU Management</title>
					<link rel='stylesheet' href='styles.css' type='text/css'>
				</head>
				<body>
				<table border='0' cellpadding='30' cellspacing='0'> 
				<tr><td>
	 			Bitte haben Sie einen Moment Geduld, die Seite wird geladen... <br>
	 			Falls nicht, klicken Sie bitte <a href='start.php'>hier</a>.
	 			</td></tr>
	 			</table>
	 			</body>
				</html>";
    # Aufruf der Startseite:
    redirect(0, "start.php", $mesg, TRUE);
	
	# nichtmehr benötigte CSV-Dateien im tmp-Verzeichnis löschen
	# listen_sauber();
}


?>
