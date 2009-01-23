<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "hwhost.dwt";

include('computers_header.inc.php');

$mnr = 0; 
$sbmnr = -1;
$mcnr = -1;

###################################################################################

$sbmnr = $_GET['sbmnr']; 

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################

$hostDN = $_GET['dn'];

$attributes = array("hostname","domainname","ipaddress","hwaddress","description","dhcphlpcont",
							"hw-mouse","hw-graphic","hw-monitor","geolocation","geoattribut");
$host = get_node_data($hostDN,$attributes);
$hostip = explode('_',$host['ipaddress']);

$template->assign(array("HOSTDN" => $hostDN,
								"HOSTNAME" => $host['hostname'],
           			      "DOMAINNAME" => $host['domainname'],
           			      "HWADDRESS" => $host['hwaddress'],
           			      "IPADDRESS" => $hostip[0],
           			      "DESCRIPTION" => $host['description'],
           		       	"DHCPCONT" => $host['dhcphlpcont'],
           		       	"GEOLOC" => $host['geolocation'],
           		       	"GEOATT" => $host['geoattribut'],
           		       	"MOUSE" => $host['hw-mouse'],
           		       	"GRAPHIC" => $host['hw-graphic'],
           		       	"MONITOR" => $host['hw-monitor'],
           		       	"DHCPLINK" => "<a href='dhcphost.php?dn=".$hostDN."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"HOSTLINK" => "<a href='host.php?dn=".$hostDN."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"RBSLINK" => "<a href='rbshost.php?dn=".$hostDN."&sbmnr=".$sbmnr."' class='headerlink'>",
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