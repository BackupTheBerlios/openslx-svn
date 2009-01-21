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
$webseite = "host.dwt";

include("../class.FastTemplate.php");

include('computers_header.inc.php');

###################################################################################

$sbmnr = $_GET['sbmnr']; 

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################

$hostDN = $_GET['dn'];

$attributes = array("hostname","domainname","ipaddress","hwaddress","description","dhcphlpcont",
							"hw-mouse","hw-graphic","hw-monitor");
$host = get_node_data($hostDN,$attributes);
$hostip = explode('_',$host['ipaddress']);

# dhcp Typ
if ($host['dhcphlpcont'] == ""){
	$dhcptype = "nodhcp";
}else{
   $ocarray = get_node_data($host['dhcphlpcont'],array("objectclass"));
   $subnet = array_search('dhcpSubnet', $ocarray['objectclass']);
   if ($subnet !== false ){
      $dhcptype = "subnet";
   }
   $service = array_search('dhcpService', $ocarray['objectclass']);
   if ($service !== false ){
      $dhcptype = "service";
   }
}
#print_r($dhcptype);

$template->assign(array("HOSTDN" => $hostDN,
								"HOSTNAME" => $host['hostname'],
           			      "DOMAINNAME" => $host['domainname'],
           			      "HWADDRESS" => $host['hwaddress'],
           			      "IPADDRESS" => $hostip[0],
           			      "DESCRIPTION" => $host['description'],           			      
           		       	"DHCPCONT" => $host['dhcphlpcont'],        			      
           		       	"DHCPTYPE" => $dhcptype,			      
           		       	"MOUSE" => $host['hw-mouse'],          			      
           		       	"GRAPHIC" => $host['hw-graphic'],
           		       	"MONITOR" => $host['hw-monitor'],
           		       	"DHCPLINK" => "<a href='dhcphost.php?dn=".$hostDN."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"HWLINK" => "<a href='hwhost.php?dn=".$hostDN."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"AUDN" => $auDN,
           		       	"SBMNR" => $sbmnr));


##########################################################
# MC Wochenübersicht
$mc_array = get_machineconfigs($hostDN,array("dn","cn","timerange","description"));
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

###########################################################
# PXE Wochenübersicht


###################################################################################

include("computers_footer.inc.php");

?>