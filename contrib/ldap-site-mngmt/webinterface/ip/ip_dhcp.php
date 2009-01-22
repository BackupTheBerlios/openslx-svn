<?php

include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "IP Address Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 1;
$mnr = 2; 
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "ip_dhcp.dwt";

include("../class.FastTemplate.php");

include("ip_header.inc.php");

#############################################################################

# Menuleiste erstellen
createMainMenu($rollen, $mainnr);
createIPMenu($rollen, $mnr);

include("ip_blocks.inc.php");


#############################################################################

$template->assign(array("SUBNET" => "Noch kein DHCP Objekt angelegt",
                        "RANGE1" => "",
                        "RANGE2" => "",
                        "DHCPDN" => ""));

$subnet_array = get_subnets($auDN,array("dn","cn","dhcprange"));
# print_r ($subnet_array);

$template->define_dynamic("Subnets", "Webseite");
		
foreach ($subnet_array as $subnet){
	$exp = explode('_',$subnet['dhcprange']);

	$template->assign(array("SUBNET" => $subnet['cn'],
                           "RANGE1" => $exp[0],
                           "RANGE2" => $exp[1],
                           "DHCPDN" => $subnet['dn'],
                           "AUDN" => $auDN ));
   $template->parse("SUBNETS_LIST", ".Subnets");	
}


#####################################################################################

include("ip_footer.inc.php");

?>