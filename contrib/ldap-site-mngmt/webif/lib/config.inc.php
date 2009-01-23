<?php

	# URL and Root Path of LSM Webinterface
	$START_PATH   = "http://your_host/path/";
	$TITEL_PREFIX = "net&lowast;Client Management &nbsp; >> &nbsp; ";

	##################################
	# LSM LDAP

	#define('LDAP_HOST', 'ldap://your_ldap_server');
	#define('LDAP_HOST', 'ldaps://your_ldap_server');	
	define('LDAP_HOST', 'localhost');

	define('LDAP_PORT', 389);
	#define('LDAP_PORT', 636);

	$suffix = "dc=uni-freiburg,dc=de";
	
	##################################
	# External Authentification LDAP
	define('LDAP_HOST_RZ','ldaps://bv1.ruf.uni-freiburg.de');
        define('LDAP_PORT_RZ', 636);
	$suffix_rz = "dc=uni-freiburg,dc=de";
	
	##################################
	$domsuffix    = "uni-freiburg.de";
	$rootAU       = "ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de";
	$DHCP_SERVICE = "cn=DHCP_Uni,cn=dhcp,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de";
	$DNS_SERVICE  = "";

	# Root Path to Addon DHCP Config File Structure
	$DHCP_FS_ROOT = "";	

	$ADMIN_EMAIL  = "dhcp-admin@your_host";
	###################################
	
	$LEASE_TIMES  = array("600" => "10 min",
						  "900" => "15 min",
						  "1800"=> "30 min",
						  "3600" => "1 h",
						  "7200" => "2 h",
						  "18000" => "5 h",
						  "36000" => "10 h",
						  "86400" => "1 Tag",
						  "172800" => "2 Tage",
						  "345600" => "4 Tage",
                                                  "604800" => "1 Woche",
                                                  "1209600" => "2 Wochen");


	$dummyUid      = "lsmdummy";
	# Bitte nachfolgende Passwoerter aendern
	$dummyPassword = "123_dummy";
	$standpwd      = "123_user"
?>
