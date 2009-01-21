<?php
include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "DHCP Service Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 5;
$mnr = 0; 
$sbmnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "new_dhcpsubnet.dwt";

include("../class.FastTemplate.php");

include('dhcp_header.inc.php');

###################################################################################

$mnr = $_GET['mnr'];
$sbmnr = $_GET['sbmnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$subnetcn = str_replace ( "_", " ", $_GET['subnetcn']);
$netmask = str_replace ( "_", " ", $_GET['netmask']);
$template->assign(array("CN" => $subnetcn,
								"NETMASK" => $netmask,
								"RANGE1" => "",
								"RANGE2" => "",
								"DESCRIPTION" => "",
								"STATEMENTS" => "",
								"ALLOW" => "",
								"DENY" => "",
								"IGNORE" => "",
								"DDNSUPDATE" => "",
								"DEFAULTLEASE" => "",
								"MAXLEASE" => "",
								"USEHOSTDCL" => "",
								"BROADCAST" => "",
								"ROUTERS" => "",
								"DOMAINNAME" => "",
								"DOMAINNAMESERVERS" => "",
								"NEXTSERVER" => "",
								"FILENAME" => "",
								"SRVIDENT" => "",
								"NTPSERVERS" => "",
								"OPTGENERIC" => "",
								"DHCPSVNOW" => "",
								"DHCPSVNOWAU" => "",
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr,
           		       	"MCNR" => $mcnr));



# DHCP Services
$dhcpservices = get_dhcpoffers($auDN);
#print_r($dhcpservices); echo "<br>";

$template->assign(array("DHCPSVDN" => "",
   	                  "DHCPSVCN" => "",
   	                  "DHCPSVAU" => ""));
if (count($dhcpservices) != 0){
$template->define_dynamic("Dhcpservices", "Webseite");
	foreach ($dhcpservices as $item){
	   $exp = ldap_explode_dn($item,1);

		$template->assign(array("DHCPSVDN" => $item,
   	                  "DHCPSVCN" => $exp[0],
   	                  "DHCPSVAU" => $exp[2]));
   	$template->parse("DHCPSERVICES_LIST", ".Dhcpservices");	
	} 
}


###################################################################################

include("dhcp_footer.inc.php");

?>