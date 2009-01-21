<?php

include('../standard_header.inc.php');

# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "new_menuentry.dwt";

include('rbs_header.inc.php');

###################################################################################

$mnr = 3; 
$sbmnr = -1;
$mcnr = -1;

$sbmnr = $_GET['sbmnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createRBSMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$mecn = str_replace ( "_", " ", $_GET['mecn']);

$pxeDN = $_GET['dn'];
$dnexp = ldap_explode_dn($pxeDN, 1);
$pxecn = $dnexp[0];

# RBS Daten
$pxe = get_node_data($pxeDN,array("rbservicedn"));
$rbsDN = $pxe['rbservicedn'];
$exp = explode(',',$rbsDN);
$exprbsau = explode('=',$exp[2]); $rbsau = $exprbsau[1];
$rbsdata = get_node_data($rbsDN,array("cn","nfsserverip","exportpath","tftpserverip","tftppath"));

# Anzahl Menüeinträge
$menens = get_menuentries($pxeDN,array("dn"));
$maxpos = count($menens)+1;

# Bootmenu Daten
$template->assign(array("MECN" => $mecn,
           			      "LABEL" => "",
           			      "MELABEL" => "",
           			      "MEDEF" => "",
           			      "MEPASSWD" => "",
           			      "MEHIDE" => "",
           			      "VGA" => "",           			      
           		       	"SPLASH" => "",          			      
           		       	"NOLDSC" => "",
           		       	"ELEVATOR" => "", 
           			      "VCI" => "",          			      
           		       	"CCV" => "",        			      
           		       	"APIC" => "",
           		       	"COWLOOP" => "",                   			      
           		       	"UNIONFS" => "",
           		       	"DEBUG" => "",          			      
           		       	"LOCALBOOT" => "",
           		       	"SUBMENULINK" => "",
           		       	"MENPOS" => "",
           		       	"MAXPOS" => $maxpos,
           		       	"PXEDN" => $pxeDN,
           		       	"PXECN" => $pxecn,
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr,
           		       	"MCNR" => $mcnr));
           		       	

# verwendbare GBMs holen
# eigene AU (andere noch über "offer" Attribut in RBS suchen) 
$attributes = array("dn","cn","label","kernel","initrd","nfsroot","nbdroot","ipappend");	
$gbm_array = get_menuentries($rbsDN,$attributes);
if (count($gbm_array) != 0){
$template->define_dynamic("Gbms", "Webseite");
	foreach ($gbm_array as $item){
		$template->assign(array("GBMDN" => $item['dn'],
   	                        "GBMCN" => $item['cn'],
   	                        "GBMLABEL" => $item['label'],
   	                        "RBSAU" => $rbsau));
   	$template->parse("GBMS_LIST", ".Gbms");	
	} 
}else{
	$template->assign(array("GBMDN" => "",
   	                        "GBMCN" => "Keine generischen Boot Images verf&uuml;gbar",
   	                        "GBMLABEL" => "Keine generischen Boot Images verf&uuml;gbar",
   	                        "RBSAU" => ""));
}


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
