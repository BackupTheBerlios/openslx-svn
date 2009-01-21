<?php

include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Computers Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 3;
$mnr = 3; 
$sbmnr = -1;
$mcnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "new_pxe.dwt";

include("../class.FastTemplate.php");

include('computers_header.inc.php');

###################################################################################

$sbmnr = $_GET['sbmnr'];
$mcnr = $_GET['mcnr']; 

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################

$pxecn = str_replace ( "_", " ", $_GET['pxecn']);
$pxeday = str_replace ( "_", " ", $_GET['pxeday']);
$pxebeg = str_replace ( "_", " ", $_GET['pxebeg']);
$pxeend = str_replace ( "_", " ", $_GET['pxeend']);

$template->assign(array("PXECN" => $pxecn,
								"PXEDAY" => $pxeday,
           			      "PXEBEG" => $pxebeg,
           			      "PXEEND" => $pxeend,
           		       	# "LDAPURI" => "",
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
           		       	"NODEDN" => "cn=rbs,".$auDN,
           		       	"HDN" => "none",
								"HN" => "",
								"GDN" => "none",
								"GN" => "", 
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

#################################################
# Ziel Objekt (nur Rechner und Gruppen, nicht Default)

$hostorgroup = $exp[0];
$hgexp = explode('=',$exp[0]);

$hosts_array = get_hosts($auDN,array("dn","hostname","hlprbservice","hwaddress"));
if ( count($hosts_array) != 0 ){
   $template->define_dynamic("Hosts", "Webseite");
   foreach ($hosts_array as $item){
      # Nur Hosts die in DHCP/TFTP angemeldet und deren MAC eingetragen ist (für PXE-Filename)
      if ( $item['hlprbservice'] != "" && $item['hwaddress'] != "" ){
   	   $template->assign(array("HDN" => $item['dn'],
                                 "HN" => $item['hostname']));
         $template->parse("HOSTS_LIST", ".Hosts");	
      }
   }
}

$groups_array = get_groups($auDN,array("dn","cn","hlprbservice"));
if ( count($groups_array) != 0 ){
   $template->define_dynamic("Groups", "Webseite");
   foreach ($groups_array as $item){
      if ( $item['hlprbservice'] != "" ){
      	$template->assign(array("GDN" => $item['dn'],
                                 "GN" => $item['cn']));
         $template->parse("GROUPS_LIST", ".Groups");
      }	
   }
}

###################################################################################

include("computers_footer.inc.php");

?>