<?php

include('../standard_header.inc.php');

# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "new_pxe.dwt";

include('rbs_header.inc.php');

###################################################################################

$mnr = -1; 
$sbmnr = -1;
$mcnr = -1;

$mnr = $_GET['mnr'];
$sbmnr = $_GET['sbmnr'];
$mcnr = $_GET['mcnr']; 

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createRBSMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$rbsDN = $_GET['rbsdn'];
$rbsdnexp = ldap_explode_dn($rbsDN, 1);

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
           			      "RBSDN" => $rbsDN,
           			      "RBSCN" => $rbsdnexp[0],   
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


###################################################################################

include("rbs_footer.inc.php");

?>