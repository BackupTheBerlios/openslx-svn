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
$webseite = "new_host.dwt";

include("../class.FastTemplate.php");

include('computers_header.inc.php');

###################################################################################

$sbmnr = $_GET['sbmnr']; 

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################


$hostname = str_replace ( "_", " ", $_GET['hostname']);
$hostdesc = str_replace ( "_", " ", $_GET['hostdesc']);
$mac = str_replace ( "_", " ", $_GET['mac']);
$ip = str_replace ( "_", " ", $_GET['ip']);

# DHCP Einbindung
$objecttype = "nodhcp";
$dhcp_selectbox = "";
$altdhcp = alternative_dhcpobjects($objecttype,"","");
if (count($altdhcp) != 0){
	foreach ($altdhcp as $item){
		$dhcp_selectbox .= "
		   <option value='".$item['dn']."'>".$item['cn']." ".$item['au']."</option>";
	}
}

$template->assign(array("HOSTNAME" => $hostname,
           			      "HOSTDESC" => $hostdesc,
           			      "MAC" => $mac,
           			      "IP" => $ip,
           			      "DHCPSELECT" => $dhcp_selectbox,
           			      "MOUSE" => "",
           			      "GRAPHIC" => "",
           			      "MONITOR" => "",
           		       	"AUDN" => $auDN));


###################################################################################

include("computers_footer.inc.php");

?>