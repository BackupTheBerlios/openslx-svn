<?php

# -----------------------------------------------------
# LSM LDAP Directory Service Settings
# -----------------------------------------------------
define('LDAP_HOST', 'ldap://<your_ldap_server>');
define('LDAP_HOST', 'ldaps://<your_ldap_server>');

define('LDAP_PORT', 389);
#define('LDAP_PORT', 636);
$suffix = "dc=uni-freiburg,dc=de";
# -----------------------------------------------------
# External Authentification LDAP (optional)
define('LDAP_HOST_EXT','ldaps://<external_auth_ldap_server>');
define('LDAP_PORT_EXT', 636);
$suffix_rz = "dc=uni-freiburg,dc=de";

# -----------------------------------------------------
# LSM Web-Interface Settings
# -----------------------------------------------------
# URL and Root Path of LSM Webinterface
$START_PATH   = "http://your_host/path/";
$TITEL_PREFIX = "net&lowast;Client Management &nbsp; >> &nbsp; ";
$domsuffix    = "uni-freiburg.de";
$rootAU       = "ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de";
# -----------------------------------------------------
$dummyUid      = "lsmdummy";
# Bitte nachfolgende Passwoerter aendern entsprechend
# Eintraegen in LDAP User Objekten
$dummyPassword = "123_dummy";
$standpwd      = "123_user"
$dhcpman_pwd   = "123_dhcpman";

# -----------------------------------------------------
# DHCP Service Global Settings
$DHCP_SERVICE = "cn=DHCP_Uni,cn=dhcp,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de";
$LEASE_TIMES  = array(
	"600" => "10 min",
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
	"1209600" => "2 Wochen"
);

# -----------------------------------------------------
# Root Path to Addon DHCP Config Filestructure
#$DHCP_FS_ROOT = "<path_to_external_filestructure>";
$ADMIN_EMAIL  = "lsm-admin@mail-domain.xy";

?>
