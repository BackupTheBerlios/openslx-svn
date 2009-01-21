<?php

include('../standard_header.inc.php');
include("../class.FastTemplate.php");

# Filename of Template
$webseite = "new_child.dwt";

include('au_header.inc.php');


###############################################################################
# Menus

$mnr = 3; 
$sbmnr = -1;

createMainMenu($rollen, $mainnr);
createAUMenu($rollen, $mnr, $auDN, $sbmnr);


################################################################################
# Mainpage Data

$childou = str_replace ( "_", " ", $_GET['ou']);
$childcn = str_replace ( "_", " ", $_GET['cn']);
$childdesc = str_replace ( "_", " ", $_GET['desc']);
$childdomain = $_GET['childdomain'];

$domprefix = str_replace('.uni-freiburg.de','',$childau[0]['associateddomain']);

$template->assign(array("CHILDOU" => $childou,
	"CHILDCN" => $childcn,
	"CHILDDOMAIN" => $childdomain,
	"CHILDDESC" => $childdesc,
	"AUDN" => $auDN));


#######################################
# Admin anlegen

$users_array = get_users();
#print_r($users_array); echo "<br><br>";

if (count($users_array) != 0) {
	$template->define_dynamic("Users", "Webseite");
	foreach ($users_array as $item) {
		$template->assign(array("UDN" => $item['dn'],
			"USER" => $item['uid']));
		$template->parse("USERS_LIST", ".Users");
	}
}
else {
	$template->assign(array("UDN" => "","USER" => ""));
}

#######################################
# Objekte zum verschieben

$host_array = get_hosts($auDN,array("dn","hostname"));
#print_r($host_array);
$template->define_dynamic("Hosts", "Webseite");
foreach ($host_array as $item){
	$template->assign(array("HDN" => $item['dn'],
		"HOSTNAME" => $item['hostname'],
		"HOSTNUMBER" => 5));
	$template->parse("HOSTS_LIST", ".Hosts");
}

###############################################################################
# Footer

include("au_footer.inc.php");

?>