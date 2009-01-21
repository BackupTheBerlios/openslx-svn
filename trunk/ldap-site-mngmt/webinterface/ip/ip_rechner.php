<?php

include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "IP Address Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 2;
$mnr = 1; 
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "ip_rechner.dwt";

include("../class.FastTemplate.php");

include("ip_header.inc.php");

#############################################################################

# Menuleiste erstellen
createMainMenu($rollen, $mainnr);
createIPMenu($rollen, $mnr);

include("ip_blocks.inc.php");

#############################################################################

$template->assign(array("IP" => "",
                        "OLDIP" => "",
                        "DHCPCONT" => "",
                        "HOSTNAME" => "Noch keine Rechner angelegt",
                        "HOSTDN" => ""));

$host_array = get_hosts($auDN,array("dn","hostname","ipaddress","dhcphlpcont"));
# print_r ($host_array);

$template->define_dynamic("Hosts", "Webseite");

foreach ($host_array as $host){
	$hostip = explode('_',$host['ipaddress']);

	if ( count($host['dhcphlpcont']) != 0 && $host['ipaddress'] == "" ){
		$subnetCN = explode('cn=',$host['dhcphlpcont']);
		$dynsubnet = explode(',', $subnetCN[1]);
		$dhcpcont = " DYNAMISCH &nbsp;&nbsp;(DHCP, Subnet $dynsubnet[0])";	 
	}elseif( count($host['dhcphlpcont']) != 0 && $host['ipaddress'] != "" ){
		$subnetCN = explode('cn=',$host['dhcphlpcont']);
		$dynsubnet = explode(',', $subnetCN[1]);
		$dhcpcont = " STATISCH &nbsp;&nbsp;(DHCP, Subnet $dynsubnet[0])";
	}else{$dhcpcont = "";}
	
	$template->assign(array("IP" => $hostip[0],
                           "OLDIP" => $hostip[0],
                           "DHCPCONT" => $dhcpcont,
                           "HOSTNAME" => $host['hostname'],
                           "HOSTDN" => $host['dn'],
                           "AUDN" => $auDN ));
   $template->parse("HOSTS_LIST", ".Hosts");			
}


#####################################################################################

include("ip_footer.inc.php");

?>
