<?php
include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Remote Boot Service Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 4;
$mnr = 0; 
$sbmnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "new_rbservice.dwt";

include("../class.FastTemplate.php");

include('rbs_header.inc.php');

###################################################################################

$mnr = $_GET['mnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createRBSMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

# nochmal zur Sicherheit: falls doch RBS angelegt

$rbscn = str_replace ( "_", " ", $_GET['rbscn']);
$template->assign(array("RBSCN" => $rbscn,
								"TFTP" => "",
								"TFTPIP" => "",
								"INITBOOTFILE" => "",
								"TFTPKERNEL" => "",
								"TFTPPXE" => "",
								"TFTPCLIENTCONF" => "",
								"NFS" => "",
								"NFSIP" => "",
								"NFSPATH" => "",
								"NBD" => "",
								"NBDIP" => "",
								"HDN" => "",
								"HN" => "",
								"IP" => "",
								"OFFERSELF" => $auDN,
								"SELFOU" => $au_ou,
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr));


# RBS Anbieten (ausser eigene AU)
$expdn = ldap_explode_dn($auDN, 0); # Mit Merkmalen
$expdn = array_slice($expdn, 2); 
$expou = ldap_explode_dn($auDN, 1); # nur Werte 
$expou = array_slice($expou, 2, -3);
#print_r($expou); echo "<br>";
#print_r($expdn); echo "<br>"; 
for ($i=0; $i<count($expou); $i++){
	$rbsoffers[$i]['ou'] = $expou[$i];
	$rbsoffers[$i]['dn'] = implode(',',$expdn);
	$expdn = array_slice($expdn, 1);
}
#print_r($rbsoffers);

$template->define_dynamic("Rbsoffers", "Webseite");
foreach ($rbsoffers as $offer){
	$template->assign(array("RBSOFFER" => $offer['dn'],
									"RBSOFFEROU" => $offer['ou'],));
	$template->parse("RBSOFFERS_LIST", ".Rbsoffers");
}

### Rechner
$hostorgroup = $exp[0];
$hosts_array = get_hosts($auDN,array("dn","hostname","ipaddress"));

$template->define_dynamic("TftpHosts", "Webseite");
$template->define_dynamic("NfsHosts", "Webseite");
$template->define_dynamic("NbdHosts", "Webseite");
foreach ($hosts_array as $item){
	$template->assign(array("HDN" => $item['dn'],
                           "HN" => $item['hostname'],
                           "IP" => $item['ipaddress']));
   $template->parse("TFTPHOSTS_LIST", ".TftpHosts");
   $template->assign(array("HDN" => $item['dn'],
                           "HN" => $item['hostname'],
                           "IP" => $item['ipaddress']));
   $template->parse("NFSHOSTS_LIST", ".NfsHosts");	
   $template->assign(array("HDN" => $item['dn'],
                           "HN" => $item['hostname'],
                           "IP" => $item['ipaddress']));
   $template->parse("NBDHOSTS_LIST", ".NbdHosts");	
}


###################################################################################

include("rbs_footer.inc.php");

?>