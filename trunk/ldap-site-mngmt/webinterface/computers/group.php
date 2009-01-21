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
$webseite = "group.dwt";

include("../class.FastTemplate.php");

include('computers_header.inc.php');

###################################################################################

$sbmnr = $_GET['sbmnr']; 

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################

$groupDN = $_GET['dn'];

$group = get_node_data($groupDN,array("cn","description","member","dhcphlpcont"));

$template->assign(array("GROUPDN" => $groupDN,
								"GROUPCN" => $group['cn'],
           			      "GROUPDESC" => $group['description'],
           			      # "MEMBERS" => $anzahlmember,
           			      "MEMBER" => $group['member'],            			      
           		       	"DHCPCONT" => $group['dhcphlpcont'],
           		       	"AUDN" => $auDN,
           		       	"SBMNR" => $sbmnr));

$template->define_dynamic("Members", "Webseite");

if ( count($group['member']) == 1 ){
	$member = $group['member'];
	$group = array();
	$group['member'][] = $member;
}

if ( count($group['member']) != 0 ){
	sort($group['member']);
	foreach ($group['member'] as $member){
		$exp = explode(',',$member);
		$memberexp = explode('=',$exp[0]);
		$membername = $memberexp[1];
		$template->assign(array("MEMBERDN" => $member,
										"MEMBER" => $membername));
		$template->parse("MEMBERS_LIST", ".Members");
	}
}

##############################################
# neues Member anlegen ...
$hosts_array = get_hosts($auDN,array("dn","hostname"));
# print_r($hosts_array); echo "<br><br>";
$groups = get_groups($auDN, array("member"));
$template->assign(array("HN" => ""));

foreach ($groups as $group){
	for ($i=0; $i < count($hosts_array); $i++){
		if (count($group['member']) > 1){
			foreach ($group['member'] as $item){
				if ($hosts_array[$i]['dn'] == $item){
					array_splice($hosts_array, $i, 1);
					$i--;   	# da ja ein Member gelöscht wurde 
				}
			}
		}
		if (count($group['member']) == 1){
			if ($hosts_array[$i]['dn'] == $group['member']){
				array_splice($hosts_array, $i, 1);
			}
		}
	}
}
#print_r($hosts_array);echo"<br>";

$template->define_dynamic("Hosts", "Webseite");
foreach ($hosts_array as $item){
	$template->assign(array("HDN" => $item['dn'],
                           "HN" => $item['hostname'],
                           "HOSTNUMBER" => 5));
   $template->parse("HOSTS_LIST", ".Hosts");	
}


##########################################################
# MC Wochenübersicht
$mc_array = get_machineconfigs($groupDN,array("dn","cn","timerange","description"));
# print_r($mc_array);
for ($i=0; $i<count($mc_array); $i++){
	# Timerange Komponenten
	if (count($mc_array[$i]['timerange']) > 1 ){
		foreach ($mc_array[$i]['timerange'] as $tr){
			$exptime = array_merge(explode('_',$tr),$mc_array[$i]['description']);
			$timeranges[$i][] = $exptime; # Für grafische Wo-Ansicht
		}
	}else{
		$exptime = array_merge(explode('_',$mc_array[$i]['timerange']), $mc_array[$i]['description']);
		$timeranges[$i] = $exptime; # Für grafische Wo-Ansicht
	}
}	
include("mc_wochenplan.php");


###################################################################################

include("computers_footer.inc.php");

?>