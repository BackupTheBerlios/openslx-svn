<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "new_dhcpservice.dwt";

include('dhcp_header.inc.php');

$mnr = 0; 
$sbmnr = -1;

###################################################################################

$mnr = $_GET['mnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$dhcpcn = str_replace ( "_", " ", $_GET['dhcpcn']);
$template->assign(array("CN" => $dhcpcn,
								"PRIMARY" => "",
								"SECONDARY" => "",
								"DESCRIPTION" => "",
								"STATEMENTS" => "",
								"ALLOW" => "",
								"DENY" => "",
								"IGNORE" => "",
								"DDNSUPDATE" => "",
								"DEFAULTLEASE" => "",
								"MAXLEASE" => "",
								"USEHOSTDCL" => "",
								"DOMAINNAME" => "",
								"DOMAINNAMESERVERS" => "",
								"MAXMESSIZE" => "",
								"SRVIDENT" => "",
								"NTPSERVERS" => "",
								"OPTGENERIC" => "",
								"OFFERSELF" => $auDN,
								"SELFOU" => $au_ou,
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr));


# DHCP Service Anbieten (ausser eigene AU)
$expdn = ldap_explode_dn($auDN, 0); # Mit Merkmalen
$expdn = array_slice($expdn, 2); 
$expou = ldap_explode_dn($auDN, 1); # nur Werte 
$expou = array_slice($expou, 2, -3);
#print_r($expou); echo "<br>";
#print_r($expdn); echo "<br>"; 
for ($i=0; $i<count($expou); $i++){
	$dhcpoffers[$i]['ou'] = $expou[$i];
	$dhcpoffers[$i]['dn'] = implode(',',$expdn);
	$expdn = array_slice($expdn, 1);
}
#print_r($dhcpoffers);

$template->define_dynamic("Dhcpoffers", "Webseite");
if ( count($dhcpoffers) != 0 ){
   foreach ($dhcpoffers as $offer){
	   $template->assign(array("DHCPOFFER" => $offer['dn'],
	   								"DHCPOFFEROU" => $offer['ou'],));
	   $template->parse("DHCPOFFERS_LIST", ".Dhcpoffers");
   }
}

###################################################################################

include("dhcp_footer.inc.php");

?>