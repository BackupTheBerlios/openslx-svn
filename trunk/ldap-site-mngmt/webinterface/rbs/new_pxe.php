<?php

include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Remote Boot Service Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 4;
$mnr = -1; 
$sbmnr = -1;
$mcnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "new_pxe.dwt";

include("../class.FastTemplate.php");

include('rbs_header.inc.php');

###################################################################################

$mnr = $_GET['mnr'];
$sbmnr = $_GET['sbmnr'];
$mcnr = $_GET['mcnr']; 

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createRBSMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$pxecn = str_replace ( "_", " ", $_GET['pxecn']);
$pxeday = str_replace ( "_", " ", $_GET['pxeday']);
$pxebeg = str_replace ( "_", " ", $_GET['pxebeg']);
$pxeend = str_replace ( "_", " ", $_GET['pxeend']);

$template->assign(array("PXECN" => $pxecn,
								"PXEDAY" => $pxeday,
           			      "PXEBEG" => $pxebeg,
           			      "PXEEND" => $pxeend,
           		       	"LDAPURI" => "",
           			      "FILEURI" => "",   
           			      "RBS" => "",
           			      "RBSAU" => "",
           			      "NFS" => "",
           			      "NFSROOT" => "",
           			      "TFTP" => "",
           			      "TFTPROOT" => "",
           			      "FILE" => "",           			      
           		       	"ALLOW" => "",          			      
           		       	"CONSOLE" => "",
           		       	"DEFAULT" => "menu.c32", 
           			      "DISPLAY" => "",          			      
           		       	"FONT" => "",
           		       	"IMPLICIT" => "",
           			      "KBDMAP" => "",          			      
           		       	"MENMPW" => "",
           		       	"MENTIT" => "",                   			      
           		       	"NOESC" => "1",
           		       	"ONERR" => "",          			      
           		       	"ONTIME" => "",
           		       	"PROMPT" => "0",          			      
           		       	"SAY" => "",
           		       	"SERIAL" => "",
								"TIMEOUT" => "600",  		      
           		        	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr));

#############################################
# RB Dienste holen
$rbsoffers = get_rbsoffers($auDN);

$template->assign(array("ALTRBSDN" => "",
   	                  "ALTRBSCN" => "",
   	                  "ALTRBSAU" => ""));

if (count($rbsoffers) != 0){
$template->define_dynamic("Altrbs", "Webseite");
	foreach ($rbsoffers as $item){
		$rbsdnexp = ldap_explode_dn($item,1);
		$rbsoffcn = $rbsdnexp[0];
		$rbsoffau = $rbsdnexp[2];
		#$auexp = explode(',',$item['auDN']);
		#$altrbsau = explode('=',$auexp[0]);
		$template->assign(array("ALTRBSDN" => $item,
   	                        "ALTRBSCN" => $rbsoffcn,
   	                        "ALTRBSAU" => " &nbsp;&nbsp;[ Abt.:  ".$rbsoffau." ]"));
   	$template->parse("ALTRBS_LIST", ".Altrbs");	
	} 
}

###################################################################################

include("rbs_footer.inc.php");

?>