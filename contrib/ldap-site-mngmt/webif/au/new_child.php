<?php

include('../standard_header.inc.php');

# Filename of Template
$webseite = "new_child.dwt";

include('au_header.inc.php');

###############################################################################
# Menus

$mnr = 2; 
$sbmnr = -1;

$sbmnr = $_GET['sbmnr'];

createMainMenu($rollen, $mainnr);
createAUMenu($rollen, $mnr, $auDN, $sbmnr);

################################################################################
# Mainpage Data

$childou = str_replace ( "_", " ", $_GET['ou']);
$childcn = str_replace ( "_", " ", $_GET['cn']);
$childdesc = str_replace ( "_", " ", $_GET['desc']);
#$childdomain = $_GET['childdomain'];

$domprefix = str_replace('.uni-freiburg.de','',$childau[0]['associateddomain']);

$childdomain = "Sie sind nicht berechtigt die DNS Zone der neuen AU festzulegen<br>
					Bitte wenden Sie sich an den DNS Administrator (...)";
if ( in_array("ZoneAdmin", $all_roles[$rootAU]['roles']) ) {
	$childdomain = "<input type='Text' name='childdomain' value='' size='25' class='medium_form_field'>";
}


$template->assign(array("CHILDOU" => $childou,
	"CHILDCN" => $childcn,
	"CHILDDOMAIN" => $childdomain,
	"CHILDDESC" => $childdesc,
	"AUDN" => $auDN));


#######################################
# Admin anlegen

$template->assign(array("SELFUDN" => $userDN,"SELFUSER" => $uid));

$users_array = get_users();
#print_r($users_array); echo "<br><br>";

if (count($users_array) != 0) {
	$template->define_dynamic("Users", "Webseite");
	foreach ($users_array as $item) {
		if ($item['uid'] != $uid) {
		$template->assign(array("UDN" => $item['dn'],
			"USER" => $item['uid']));
		$template->parse("USERS_LIST", ".Users");
		}
	}
}
else {
	$template->assign(array("UDN" => "","USER" => ""));
}

#######################################
# Objekte zum verschieben

#$host_array = get_hosts($auDN,array("dn","hostname"));
#print_r($host_array);
#$template->define_dynamic("Hosts", "Webseite");
#foreach ($host_array as $item){
#	$template->assign(array("HDN" => $item['dn'],
#		"HOSTNAME" => $item['hostname'],
#		"HOSTNUMBER" => 5));
#	$template->parse("HOSTS_LIST", ".Hosts");
#}

###############################################################################
# Footer

include("au_footer.inc.php");

?>