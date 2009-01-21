<?php

include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Computers Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 3;
$mnr = 1; 
$sbmnr = -1;
$mcnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "hostoverview.dwt";

include("../class.FastTemplate.php");

include('computers_header.inc.php');

###################################################################################

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################

$template->assign(array("DN" => "",
								"HOSTNAME" => "Noch keine Rechner angelegt",
           			      "DOMAINNAME" => "",
           			      "HWADDRESS" => "",
           			      "IPADDRESS" => "",            			      
           		       	"DHCPCONT" => "",
           		       	"RBSCONT" => ""));

$attributes = array("dn","hostname","domainname","hwaddress","ipaddress","dhcphlpcont","hlprbservice");
$host_array = get_hosts($auDN,$attributes);

$template->define_dynamic("Rechner", "Webseite");

$i = 0;
foreach ($host_array as $host){
	
	$hostname = "<a href='host.php?dn=".$host['dn']."&sbmnr=".$i."' class='headerlink'>".$host['hostname']."</a>";
	$hostip = explode('_',$host['ipaddress']);
	
	$dhcpcont = "";
	if ( count($host['dhcphlpcont']) != 0 ){
	   $dhcpexpdn = ldap_explode_dn($host['dhcphlpcont'],1);
	   $dhcpcn = $dhcpexpdn[0];
	   $ocarray = get_node_data($host['dhcphlpcont'],array("objectclass","dhcphlpcont"));
	   $sub = array_search('dhcpSubnet', $ocarray['objectclass']);
	   if ($sub !== false ){
	      $dhcpcont = "Subnet ".$dhcpexpdn[0]." <br>[".$dhcpexpdn[2]."]";
	   }else{
	      $dhcpcont = "Service ".$dhcpexpdn[0]." <br>[".$dhcpexpdn[2]."]";
	   }
	}
	
	$rbscont = "";
	if ( count($host['hlprbservice']) != 0 ){
	   $rbsexpdn = ldap_explode_dn($host['hlprbservice'],1);
	   $rbscont = $rbsexpdn[0]." <br>[".$rbsexpdn[2]."]";
	}
	
	$template->assign(array("DN" => $host['dn'],
								"HOSTNAME" => $hostname,
           			      "DOMAINNAME" => $host['domainname'],
           			      "HWADDRESS" => $host['hwaddress'],
           			      "IPADDRESS" => $hostip[0],            			      
           		       	"DHCPCONT" => $dhcpcont,
           		       	"RBSCONT" => $rbscont,
           		       	"AUDN" => $auDN ));
	$template->parse("RECHNER_LIST", ".Rechner");
	
	$i++;
}

###################################################################################

include("computers_footer.inc.php");

?>