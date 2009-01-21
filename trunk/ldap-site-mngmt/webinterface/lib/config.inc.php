<?php

    #Pfad festlegen wo die Anwendungsskripte sich befinden
    #$START_PATH="http://132.230.4.150/test/";
    #$START_PATH="https://132.230.9.56/lsm/";
    $START_PATH="https://dhcp.uni-freiburg.de/lsm/";

    # Anlegen einer Variablen für den Speicherort von den CSVs
    # $TMPPATH_CSV="/home/gruppe1/public_html/htdocs/";

    # einige LDAP-Angaben:
    # der Anwendungs-LDAP
    define('LDAP_HOST', 'ldap://oranje.ruf.uni-freiburg.de');
    #define('LDAP_HOST', 'ldaps://oranje.ruf.uni-freiburg.de');
    define('LDAP_PORT', 389);
    #define('LDAP_PORT', 636);
    $suffix = "dc=uni-freiburg,dc=de";
	 $domsuffix = "uni-freiburg.de";
    
    # der LDAP-Server für die Authentisierung der User
    #define('LDAP_HOST_RZ', '132.230.1.61');
    #define('LDAP_PORT_RZ', 636);
    #$suffix_rz = "dc=uni-freiburg,dc=de";

    # einige Sachen, die aus Sicherheitsgründen in produktiven Umgebungen geändert werden sollten!!!
    #$dummyUid      = "rz-ldap";  // Dummy-User für einige Aktionen - muss angelegt werden!!!
    #$dummyPassword = "dummy";

    #$standardPassword = "dipman02";  // das Passwort mit dem alle User im Anwendungsldap angelegt werden!!!
?>
