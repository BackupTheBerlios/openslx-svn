<?php

include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "DHCP Service Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 5;
$mnr = 2; 
$sbmnr = -1;
$mcnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcpsubnets.dwt";

include("../class.FastTemplate.php");

include('dhcp_header.inc.php');

###################################################################################

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$template->assign(array("SUBNETDN" => "",
								"SUBNETCN" => "Noch keine Subnets angelegt",
								"NETMASK" => "",
								"DHCP" => "",
								"RANGE" => "",
								"HOSTS" => ""));

# rbservice und pxe daten (voerst nur ein rbs)
$subnet_array = get_dhcpsubnets($auDN,array("dn","cn","dhcpoptnetmask","dhcprange","dhcphlpcont"));

$template->define_dynamic("Subnets", "Webseite");
foreach ($subnet_array as $subnet){
   $range = "";
   if ($subnet['dhcprange'] != ""){
      $exp = explode('_',$subnet['dhcprange']);
      $range = $exp[0]." - ".$exp[1];
   }
   if ($subnet['dhcphlpcont'] != ""){
      $exp = ldap_explode_dn($subnet['dhcphlpcont'],1);
      $dhcpservice = $exp[0]." &nbsp;[".$exp[2]."]";
   }else{
      $dhcpservice = "";
   }
   
	$template->assign(array("SUBNETDN" => $subnet['dn'],
									"SUBNETCN" => $subnet['cn'],
	   	        		      "NETMASK" => $subnet['dhcpoptnetmask'],
	   	        		      "DHCP" => $dhcpservice,
	   	        			   "RANGE" => $range,
	   	        			   "HOSTS" => ""));
	$template->parse("SUBNETS_LIST", ".Subnets");
}


###################################################################################

include("dhcp_footer.inc.php");

?>
