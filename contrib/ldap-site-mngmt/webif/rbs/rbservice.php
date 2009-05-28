<?php
include('../standard_header.inc.php');

# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "rbservice.dwt";

include('rbs_header.inc.php');

###################################################################################

$mnr = 0; 
$sbmnr = -1;

$mnr = $_GET['mnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createRBSMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$rbsDN = $_GET['rbsdn'];

// print $auDN;

$template->assign(array("RBSDN" => "",
						"CN" => "",
						"RBSDESC" => "",
						"RBSMODE" => "",
						"TFTP" => "",
						"TFTPIP" => "",
						"TFTPROOT" => "",
						"INITBOOTFILE" => "",
						"RBSOFFERNOWDN" => "",
						"RBSOFFERNOW" => ""
					));

# RBS Daten
$attributes = array("dn","cn","rbsofferdn","initbootfile","tftpserverip","tftproot","tftpkernelpath","tftpclientconfpath","tftppxepath","description","rbsmode");
$rbs_data = get_node_data($rbsDN, $attributes);

$expcn = explode('_',$rbs_data['cn']);
$name = array_slice($expcn,1);
$rbscn = implode('_',$name);


# RBS Nutzer
# momentanes Offer
$offerexp = ldap_explode_dn($rbs_data['rbsofferdn'], 1);
$rbsoffernow = $offerexp[0];
# alternative Offers
$expdn = ldap_explode_dn($auDN, 0); # Mit Merkmalen
$expdn = array_slice($expdn, 1); 
$expou = ldap_explode_dn($auDN, 1); # nur Werte 
$expou = array_slice($expou, 1, -3);
#print_r($expou); echo "<br>";
#print_r($expdn); echo "<br>"; 
for ($i=0; $i<count($expou); $i++){
	$rbsoffers[$i]['ou'] = $expou[$i];
	$rbsoffers[$i]['dn'] = implode(',',$expdn);
	$expdn = array_slice($expdn, 1);
}
#print_r($rbsoffers);

$template->assign(array("RBSDN"    => $rbs_data['dn'],
						"RBSCN"    => $rbscn,
						"RBSDESC"  => $rbs_data['description'],
						"RBSMODE" => $rbs_data['rbsmode'],
						"TFTPIP"   => $rbs_data['tftpserverip'],
						"TFTPROOT" => $rbs_data['tftproot'],
						"INITBOOTFILE" => $rbs_data['initbootfile'],
						"RBSOFFERNOWDN" => $rbs_data['rbsofferdn'],
						"RBSOFFERNOW" => $rbsoffernow,
						"MNR" => $mnr,
						"SBMNR" => $sbmnr
						));

# RBS Offers
$template->define_dynamic("Rbsoffers", "Webseite");
foreach ($rbsoffers as $offer){
	$template->assign(array("RBSOFFER" => $offer['dn'],
									"RBSOFFEROU" => $offer['ou'],));
	$template->parse("RBSOFFERS_LIST", ".Rbsoffers");
}


###################################################################################

include("rbs_footer.inc.php");

?>