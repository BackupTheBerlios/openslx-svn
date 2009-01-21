<?php

	# URL and Root Path of LSM Webinterface
	$START_PATH="https://dhcp.uni-freiburg.de/";
	#$START_PATH="http://localhost/lsm/";

	###################################
	# LSM LDAP Directory Information

	# LDAP Server
	# Master
	define('LDAP_HOST', 'ldap://foo.ruf.uni-freiburg.de');
	#define('LDAP_HOST', 'ldaps://foo.ruf.uni-freiburg.de');
	# Slave
	#define('LDAP_HOST', 'ldap://bar.ruf.uni-freiburg.de');
	#define('LDAP_HOST', 'ldaps://bar.ruf.uni-freiburg.de');

	# Local for Testing
	#define('LDAP_HOST', 'localhost');
	
	define('LDAP_PORT', 389);
	#define('LDAP_PORT', 636);
	
	$suffix = "dc=uni-freiburg,dc=de";
	$domsuffix = "uni-freiburg.de";
	$rootAU = "ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de";
	###################################


	# einige Sachen, die aus Sicherheitsgr�nden in produktiven Umgebungen ge�ndert werden sollten!!!
	#$dummyUid      = "rz-ldap";  // Dummy-User f�r einige Aktionen - muss angelegt werden!!!
	#$dummyPassword = "dummy";

	#$standardPassword = "...";  // das Passwort mit dem alle User im Anwendungsldap angelegt werden!!!

?>
