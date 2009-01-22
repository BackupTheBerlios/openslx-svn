<?php
include('../standard_header.inc.php');

# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "rbservice.dwt";

include('rbs_header.inc.php');

###################################################################################

$mnr = 0; 
$sbmnr = -1;

$mnr = $_GET['mnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createRBSMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$rbsDN = $_GET['rbsdn'];

$template->assign(array("RBSDN" => "",
								"CN" => "",
								"TFTP" => "",
								"TFTPIP" => "",
								"TFTPROOT" => "",
								"INITBOOTFILE" => "",
								"TFTPKERNEL" => "",
								"TFTPPXE" => "",
								"TFTPCLIENTCONF" => "",
								"FSURI" => "",
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
$attributes = array("dn","cn","rbsofferdn","tftpserverip","tftproot","tftpkernelpath","tftpclientconfpath",
                     "tftppxepath","nfsserverip","exportpath","nbdserverip","initbootfile","fileserveruri");
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
$tftpserver = get_hostname_from_ip($rbs_data['tftpserverip']);
#print_r($tftpserver);

$template->assign(array("RBSDN" => $rbs_data['dn'],
								"RBSCN" => $rbscn,
								"TFTP" => $tftpserver['hostname'],
								"TFTPDN" => $tftpserver['dn'],
								"TFTPIP" => $rbs_data['tftpserverip'],
								"TFTPROOT" => $rbs_data['tftproot'],
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

# RBS Offers
$template->define_dynamic("Rbsoffers", "Webseite");
foreach ($rbsoffers as $offer){
	$template->assign(array("RBSOFFER" => $offer['dn'],
									"RBSOFFEROU" => $offer['ou'],));
	$template->parse("RBSOFFERS_LIST", ".Rbsoffers");
}


# Fileserver URIs
$template->define_dynamic("Fsuris", "Webseite");
if ( count($rbs_data['fileserveruri']) > 1 ){
   foreach ($rbs_data['fileserveruri'] as $fsuri){
   	$template->assign(array("FSURI" => $fsuri));
   	$template->parse("FSURIS_LIST", ".Fsuris");
   }
}else{
   $template->assign(array("FSURI" => $rbs_data['fileserveruri']));
	$template->parse("FSURIS_LIST", ".Fsuris");
}

### Rechner
$hostorgroup = $exp[0];
$hosts_array = get_hosts($auDN,array("dn","hostname","ipaddress"));

$template->define_dynamic("TftpHosts", "Webseite");
foreach ($hosts_array as $item){
   if ($item['ipaddress'] != "" && $item['hostname'] != $tftpserver['hostname']){
      $hostip = explode("_",$item['ipaddress']);
	   $template->assign(array("HDN" => $item['dn'],
                              "HN" => $item['hostname'],
                              "IP" => $hostip[0]));
      $template->parse("TFTPHOSTS_LIST", ".TftpHosts");
   }
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