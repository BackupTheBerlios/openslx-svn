<?php
include('../standard_header.inc.php');

# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "new_rbservice.dwt";

include('rbs_header.inc.php');

###################################################################################

$mnr = 0; 
$sbmnr = -1;

$mnr = $_GET['mnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createRBSMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

# nochmal zur Sicherheit: falls doch RBS angelegt

$rbscn = str_replace ( "_", " ", $_GET['rbscn']);
$template->assign(array("RBSCN" => $rbscn,
								"TFTPROOT" => "",
								"TFTPIP" => "",
								"INITBOOTFILE" => "",
								"OFFERSELF" => $auDN,
								"SELFOU" => $au_ou,
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr));


# RBS Anbieten (ausser eigene AU)
$expdn = ldap_explode_dn($auDN, 0); # Mit Merkmalen
$expdn = array_slice($expdn, 2); 
$expou = ldap_explode_dn($auDN, 1); # nur Werte 
$expou = array_slice($expou, 2, -3);
#print_r($expou); echo "<br>";
#print_r($expdn); echo "<br>"; 
for ($i=0; $i<count($expou); $i++){
	$rbsoffers[$i]['ou'] = $expou[$i];
	$rbsoffers[$i]['dn'] = implode(',',$expdn);
	$expdn = array_slice($expdn, 1);
}
#print_r($rbsoffers);

$template->define_dynamic("Rbsoffers", "Webseite");
foreach ($rbsoffers as $offer){
	$template->assign(array("RBSOFFER" => $offer['dn'],
									"RBSOFFEROU" => $offer['ou'],));
	$template->parse("RBSOFFERS_LIST", ".Rbsoffers");
}


###################################################################################

include("rbs_footer.inc.php");

?>