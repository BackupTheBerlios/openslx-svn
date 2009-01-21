<?php

include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Remote Boot Service Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 4;
$mnr = 3; 
$sbmnr = -1;
$mcnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "menuentry.dwt";

include("../class.FastTemplate.php");

include('rbs_header.inc.php');

###################################################################################

$sbmnr = $_GET['sbmnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createRBSMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$meDN = $_GET['dn'];

$attributes = array("cn","genericmenuentrydn","label","menulabel","menudefault","menupasswd","vga","splash",
							"noldsc","elevator","clientconfvia","apic",
							"cowloop","unionfs","debug","vci","menuhide","menuposition","localboot","kernel","submenulink");
$me = get_node_data($meDN,$attributes);
#print_r($me);

# PXE DN 
$exp = explode(',',$meDN);
$node = array_slice($exp,1);
$exppxecn = explode('=',$node[0]);
$pxecn = $exppxecn[1];
$pxeDN = implode(',',$node);

# Generic Menu Entry
$expgbm = ldap_explode_dn ($me['genericmenuentrydn'],1);
$gmecn = $expgbm[0];
$gmerbs = $expgbm[1];
$gmeou = $expgbm[3];

# RBS Daten
$pxe = get_node_data($pxeDN,array("rbservicedn"));
$rbsDN = $pxe['rbservicedn'];
$exp = explode(',',$rbsDN);
$exprbsau = explode('=',$exp[2]); $rbsau = $exprbsau[1];
$rbsdata = get_node_data($rbsDN,array("cn","nfsserverip","exportpath","tftpserverip","tftppath"));

# Bootmenu Daten
$template->assign(array("MEDN" => $meDN,
								"MECN" => $me['cn'],
           			      "GMECN" => $gmecn,
           			      "GMEOU" => $gmeou,
           			      "GMERBS" => $gmerbs,
           			      "LABEL" => $me['label'],
           			      "MELABEL" => $me['menulabel'],
           			      "MEDEF" => $me['menudefault'],
           			      "MEPASSWD" => $me['menupasswd'],
           			      "MEHIDE" => $me['menuhide'],
           			      "VGA" => $me['vga'],           			      
           		       	"SPLASH" => $me['splash'],          			      
           		       	"NOLDSC" => $me['noldsc'],
           		       	"ELEVATOR" => $me['elevator'], 
           			      "VCI" => $me['vci'],          			      
           		       	"CCV" => $me['clientconfvia'],       			      
           		       	"APIC" => $me['apic'],
           		       	"COWLOOP" => $me['cowloop'],                   			      
           		       	"UNIONFS" => $me['unionfs'],
           		       	"DEBUG" => $me['debug'],
           		       	"MENPOS" => $me['menuposition'],          			      
           		       	"LOCALBOOT" => $me['localboot'],
           		       	"KERNEL" => $me['kernel'],
           		       	"SUBMENULINK" => $me['submenulink'],
           		       	"PXEDN" => $pxeDN,
           		       	"PXECN" => $pxecn,
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr,
           		       	"MCNR" => $mcnr));
           		       	
# Alternative RB Dienste holen
$altrbs = get_rbservices($auDN,array("dn","cn"));
if (count($altrbs) != 0){
	for ($i=0; $i < count($altrbs); $i++){
		if ($rbsDN == $altrbs[$i]['dn']){
			array_splice($altrbs, $i, 1);
		}
	}
}


if (count($altrbs) != 0){
$template->define_dynamic("Altrbs", "Webseite");
	foreach ($altrbs as $item){
		$altrbsexp = explode(',',$item['dn']);
		$altrbsau = explode('=',$altrebsexp[2]);
		$template->assign(array("ALTRBSDN" => $item['dn'],
   	                        "ALTRBSCN" => $item['cn'],
   	                        "ALTRBSAU" => "[ ".$altrbsau[1]." ]"));
   	$template->parse("ALTRBS_LIST", ".Altrbs");	
	} 
}else{
	$template->assign(array("ALTRBSDN" => "",
   	                        "ALTRBSCN" => "",
   	                        "ALTRBSAU" => ""));
}

################################################
# Bootmenü Einträge 

$menuentries = get_menuentries($pxeDN,array("dn","menuposition","label","menulabel"));
#print_r($menuentries); echo "<br>";

$template->define_dynamic("Bootmenu", "Webseite");

foreach ($menuentries as $me){
	$template->assign(array("MENDN" => $me['dn'],
									"MENULABEL" => $me['menulabel'],
   	        			      "POSITION" => $me['menuposition'],
   	        		       	"AUDN" => $auDN));
	$template->parse("BOOTMENU_LIST", ".Bootmenu");
}


################################################ 
# PXE kopieren

$hostorgroup = $exp[0];
$hgexp = explode('=',$exp[0]);

$hosts_array = get_hosts($auDN,array("dn","hostname"));
$groups_array = get_groups($auDN,array("dn","cn"));

$template->define_dynamic("Hosts", "Webseite");
foreach ($hosts_array as $item){
	$template->assign(array("HDN" => $item['dn'],
                           "HN" => $item['hostname']));
   $template->parse("HOSTS_LIST", ".Hosts");	
}
$template->define_dynamic("Groups", "Webseite");
foreach ($groups_array as $item){
	$template->assign(array("GDN" => $item['dn'],
                           "GN" => $item['cn']));
   $template->parse("GROUPS_LIST", ".Groups");	
}

###################################################################################

include("rbs_footer.inc.php");

?>
