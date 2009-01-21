<?php
include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Remote Boot Service Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 4;
$mnr = 0; 
$sbmnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "rbservice.dwt";

include("../class.FastTemplate.php");

include('rbs_header.inc.php');

###################################################################################

$mnr = $_GET['mnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createRBSMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$template->assign(array("RBSDN" => "",
								"CN" => "",
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
								"RBSOFFERNOWDN" => "",
								"RBSOFFERNOW" => "",
								"HDN" => "",
								"HN" => "",
								"IP" => ""));

# RBS Daten						
$rbs_array = get_rbservices($auDN,array("dn","cn"));
$rbsDN = $rbs_array[0]['dn'];
$attributes = array("dn","cn","rbsofferdn","tftpserverip","tftpkernelpath","tftpclientconfpath","tftppxepath",
							"nfsserverip","exportpath","nbdserverip","initbootfile");
$rbs_data = get_node_data($rbsDN, $attributes);

# RBS Anbieten
# momentanes Offer
$offerexp = ldap_explode_dn($rbs_data['rbsofferdn'], 1);
$rbsoffernow = $offerexp[0];
# alternative Offers
$expdn = ldap_explode_dn($auDN, 0); # Mit Merkmalen
$expdn = array_slice($expdn, 1); 
$expou = ldap_explode_dn($auDN, 1); # nur Werte 
$expou = array_slice($expou, 1, -3);
#print_r($expou); echo "<br>";
#print_r($expdn); echo "<br>"; 
for ($i=0; $i<count($expou); $i++){
	$rbsoffers[$i]['ou'] = $expou[$i];
	$rbsoffers[$i]['dn'] = implode(',',$expdn);
	$expdn = array_slice($expdn, 1);
}
#print_r($rbsoffers);

$expcn = explode('_',$rbs_data['cn']);
$name = array_slice($expcn,1);
$rbscn = implode('_',$name);

# Server Hostnamen holen
$tftpserver = get_hostname_from_ip($rbs_data['tftpserverip'],$auDN);
$nfsserver = get_hostname_from_ip($rbs_data['nfsserverip'],$auDN);
$nbdserver = get_hostname_from_ip($rbs_data['nbdserverip'],$auDN);

$template->assign(array("RBSDN" => $rbs_data['dn'],
								"RBSCN" => $rbscn,
								"TFTP" => $tftpserver['hostname'],
								"TFTPDN" => $tftpserver['dn'],
								"TFTPIP" => $rbs_data['tftpserverip'],
								"INITBOOTFILE" => $rbs_data['initbootfile'],
								"TFTPKERNEL" => $rbs_data['tftpkernelpath'],
								"TFTPPXE" => $rbs_data['tftppxepath'],
								"TFTPCLIENTCONF" => $rbs_data['tftpclientconfpath'],
								"NFS" => $nfsserver['hostname'],
								"NFSDN" => $nfsserver['dn'],
								"NFSIP" => $rbs_data['nfsserverip'],
								"NFSPATH" => $rbs_data['exportpath'],
								"NBD" => $nbdserver['hostname'],
								"NBDDN" => $nbdserver['dn'],
								"NBDIP" => $rbs_data['nbdserverip'],
								"RBSOFFERNOWDN" => $rbs_data['rbsofferdn'],
								"RBSOFFERNOW" => $rbsoffernow,
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr));

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

################################################
# PXE Generator Skript Config
$pxegen_ldap = LDAP_HOST;
$pxegen_base = "ou=RIPM,".$suffix;
$pxegen_udn = $userDN;
$pxegen_pw = $userPassword;
$pxegen_rbsdn = $rbsDN;
$template->assign(array("PXEGENLDAP" => $pxegen_ldap,
   	                  "PXEGENBASE" => $pxegen_base,
   	                  "PXEGENUDN" => $pxegen_udn,
   	                  "PXEGENPW" => $pxegen_pw,
   	                  "PXEGENRBS" => $pxegen_rbsdn));


###################################################################################

include("rbs_footer.inc.php");

?>