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
$webseite = "groupoverview.dwt";

include("../class.FastTemplate.php");

include('computers_header.inc.php');

###################################################################################

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################

$template->assign(array("DN" => "",
								"GROUPCN" => "Noch keine Rechnergruppen angelegt",
           			      "GROUPDESC" => "",
           			      "MEMBERS" => "",           			      
           		       	"DHCPCONT" => ""));

$attributes = array("dn","cn","member","description","dhcphlpcont");
$group_array = get_groups($auDN,$attributes);

$template->define_dynamic("Gruppen", "Webseite");

foreach ($group_array as $group){
	
	$groupname = "<a href='group.php?dn=".$group['dn']."&sbmnr=".$i."' class='headerlink'>".$group['cn']."</a>";
	$anzahlmember = count($group['member']);
	
	if ( count($group['dhcphlpcont']) != 0 ){
		$subnetCN = explode('cn=',$group['dhcphlpcont']);
		$subnet = explode(',', $subnetCN[1]);
		$dhcpcont = "Subnet $subnet[0]";	 
	}else{$dhcpcont = "";}
	
	$template->assign(array("DN" => $group['dn'],
								"GROUPCN" => $groupname,
           			      "GROUPDESC" => $group['description'],
           			      "MEMBERS" => $anzahlmember,
           			      # "MEMBER" => $group['member'],            			      
           		       	"DHCPCONT" => $dhcpcont,
           		       	"AUDN" => $auDN ));
	$template->parse("GRUPPEN_LIST", ".Gruppen");
}



###################################################################################

include("computers_footer.inc.php");

?>