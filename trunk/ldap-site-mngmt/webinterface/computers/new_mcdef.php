<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "new_mcdef.dwt";

include('computers_header.inc.php');

$mnr = 4; 
$sbmnr = -1;
$mcnr = -1;

###################################################################################

$sbmnr = $_GET['sbmnr'];
$mcnr = $_GET['mcnr']; 

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################

$mccn = str_replace ( "_", " ", $_GET['mccn']);
$mcdesc = str_replace ( "_", " ", $_GET['mcdesc']);
$mcday = str_replace ( "_", " ", $_GET['mcday']);
$mcbeg = str_replace ( "_", " ", $_GET['mcbeg']);
$mcend = str_replace ( "_", " ", $_GET['mcend']);


$template->assign(array("MCCN" => $mccn,
								"MCDAY" => $mcday,
           			      "MCBEG" => $mcbeg,
           			      "MCEND" => $mcend,
           			      "MCDESC" => $mcdesc,   			      
           		       	"NODEDN" => "cn=computers,".$auDN,
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr,
           		       	"MCNR" => $mcnr));

#################################################
# Ziel Objekt (nur Rechner und Gruppen, Default)

$hostorgroup = $exp[0];
$hgexp = explode('=',$exp[0]);

$hosts_array = get_hosts($auDN,array("dn","hostname"));
$groups_array = get_groups($auDN,array("dn","cn"));

$template->define_dynamic("Hosts", "Webseite");
foreach ($hosts_array as $item){
	$template->assign(array("HDN" => $item['dn'],
                           "HN" => $item['hostname']));
   $template->parse("HOSTS_LIST", ".Hosts");	
}
$template->define_dynamic("Groups", "Webseite");
foreach ($groups_array as $item){
	$template->assign(array("GDN" => $item['dn'],
                           "GN" => $item['cn']));
   $template->parse("GROUPS_LIST", ".Groups");	
}


###################################################################################

include("computers_footer.inc.php");

?>