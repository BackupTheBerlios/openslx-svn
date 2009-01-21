<?php

    #Pfad festlegen wo die Anwendungsskripte sich befinden
    #$START_PATH="http://localhost/lsm/";
    $START_PATH="https://dhcp.uni-freiburg.de/";

    # Anlegen einer Variablen f�r den Speicherort von den CSVs
    # $TMPPATH_CSV="/home/gruppe1/public_html/htdocs/";

    # einige LDAP-Angaben:
    # der Anwendungs-LDAP
    define('LDAP_HOST', 'ldap://foo.ruf.uni-freiburg.de');
    #define('LDAP_HOST', 'ldaps://foo.ruf.uni-freiburg.de');
    define('LDAP_PORT', 389);
    #define('LDAP_PORT', 636);
    $suffix = "dc=uni-freiburg,dc=de";
	 $domsuffix = "uni-freiburg.de";
	 $rootAU = "ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de";
    
    # der LDAP-Server f�r die Authentisierung der User
    #define('LDAP_HOST', 'localhost');
    #define('LDAP_PORT', 389);
    #$suffix_rz = "dc=uni-freiburg,dc=de";

    # einige Sachen, die aus Sicherheitsgr�nden in produktiven Umgebungen ge�ndert werden sollten!!!
    #$dummyUid      = "rz-ldap";  // Dummy-User f�r einige Aktionen - muss angelegt werden!!!
    #$dummyPassword = "dummy";

    #$standardPassword = "...";  // das Passwort mit dem alle User im Anwendungsldap angelegt werden!!!
?>
