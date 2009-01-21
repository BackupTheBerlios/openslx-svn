<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "new_dhcpsubnet.dwt";

include('dhcp_header.inc.php');

$mnr = 0; 
$sbmnr = -1;

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



$freenets = get_networks();
#print_r($freenets);
$subnets = array();
if (count($freenets) != 0){
   $template->define_dynamic("Dhcpsubnets", "Webseite");

   foreach ($freenets as $subnet){
      $netexp = explode(".",$subnet);
      $mask = array(255,255,255,255);
      for ($i=0; $i<count($netexp); $i++){
         if ($netexp[$i] == "0"){
            $mask[$i] = "0";
         }
      }
      $netmask = implode(".", $mask);
      $subnets[] = $subnet."|".$netmask;
      
      $template->assign(array("SUBNET" => $subnet."|".$netmask,
   	                  "CN" => $subnet,
   	                  "NETMASK" => $netmask));
   	$template->parse("DHCPSUBNETS_LIST", ".Dhcpsubnets");	  
   }
   #print_r($subnets);
   
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

$template->assign(array("SUBLIST" => count($freenets)+1,
								"SRVLIST" => count($dhcpservices)+1));

}else{
   # keine freie Netze mehr zur Verfügung
   # wird schon über das DHCP Menu abgefangen ...
}

###################################################################################

include("dhcp_footer.inc.php");

?>