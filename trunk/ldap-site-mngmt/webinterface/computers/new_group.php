<?php

include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Computers Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 3;
$mnr = 2; 
$sbmnr = -1;
$mcnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "new_group.dwt";

include("../class.FastTemplate.php");

include('computers_header.inc.php');

###################################################################################

$sbmnr = $_GET['sbmnr']; 

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################


$groupcn = str_replace ( "_", " ", $_GET['groupcn']);
$groupdesc = str_replace ( "_", " ", $_GET['groupdesc']);



$template->assign(array("GROUPCN" => $groupcn,
           			      "GROUPDESC" => $groupdesc,
           		       	"AUDN" => $auDN));
           	
# DHCP Stuff ... 

           		       	
##############################################
# neues Member anlegen ...
$hosts_array = get_hosts($auDN,array("dn","hostname"));
# print_r($users_array); echo "<br><br>";
$groups = get_groups($auDN, array("member"));
# print_r($groups);
$template->assign(array("HOSTNAME" => ""));

if (count($groups) != 0){
	foreach ($groups as $group){
		for ($i=0; $i < count($hosts_array); $i++){
			foreach ($group['member'] as $item){ # ist hier sicher dass member ein array ist auch bei 1 member?
				if ($hosts_array[$i]['dn'] == $item){
					array_splice($hosts_array, $i, 1);
					$i--;
				}
			}
		}
	}
}
# if (count($users_array) != 0){
	$template->define_dynamic("Hosts", "Webseite");
	foreach ($hosts_array as $item){
		$template->assign(array("HDN" => $item['dn'],
                              "HOSTNAME" => $item['hostname'],
                              "HOSTNUMBER" => 5));
      $template->parse("HOSTS_LIST", ".Hosts");	
	}


###################################################################################

include("computers_footer.inc.php");

?>