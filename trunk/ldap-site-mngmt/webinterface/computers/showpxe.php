<?php

include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Computers Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 3;
$mnr = -1; 
$sbmnr = -1;
$mcnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "showpxe.dwt";

include("../class.FastTemplate.php");

include('computers_header.inc.php');

###################################################################################

$mnr = $_GET['mnr']; 
$sbmnr = $_GET['sbmnr'];
$mcnr = $_GET['mcnr'];


# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################

$pxeDN = $_GET['dn'];

$hostdn = $_GET['hostdn'];
$hostdnarray = ldap_explode_dn($hostdn, 1);

$attributes = array("dn","cn","rbservicedn","filename","timerange","kbdmap","menumasterpasswd","menutitle");
$pxe = get_node_data($pxeDN,$attributes);
#print_r($pxe);
$expcn = explode('_',$pxe['cn']);
$name = array_slice($expcn,1);
$pxecn = implode('_',$name);




# Bootmenü Einträge
$menuentries = get_menuentries($pxeDN,array("dn","menuposition","label","menulabel","menudefault","menupasswd","menuhide"));
# print_r($menuentries); echo "<br>";
$maxpos = count($menuentries)+1;


################################################
# Bootmenü Einträge 

$template->define_dynamic("Bootmenu", "Webseite");
$template->assign(array("PXECN" => $pxecn,
   	                  "HOSTDN" => $hostdn,
   	                  "HOST" => $hostdnarray[0],
   	                  "SBMNR" => $sbmnr,
                        "MENDN" => "",
   	                  "MENULABEL" => "",
								"ANZEIGE" => "Kein Bootmen&uuml; Eintrag angelegt",
   	                  "MEDEF" => "",
   	                  "MEPWD" => "",
   	                  "MEHIDE" => "",
   	                  "BGCDEF" => "",
   	                  "POSITION" => ""));
foreach ($menuentries as $me){
	$anzeige = "";
	if ($me['label'] != "" && $me['menulabel'] == ""){$anzeige .= $me['label'];}
	if ($me['menulabel'] != ""){$anzeige .= $me['menulabel'];}
	if ($me['menudefault'] == 1){$medef = "<b>D</b>"; $bgcdef = "background-color:#EEDD82;";}
	if ($me['menupasswd'] != ""){$mepwd = "<b>P</b>";}
	if ($me['menuhide'] == 1){$mehide = "<b>H</b>"; $bgcdef = "background-color:#A0A0A0;";}
	$template->assign(array("MENDN" => $me['dn'],
									"ANZEIGE" => $anzeige,
   	        			      "ANZEIGENAME" => $anzeige,
   	        			      "POSITION" => $me['menuposition'],
   	        			      "MEDEF" => $medef,
   	        			      "MEPWD" => $mepwd,
   	        			      "MEHIDE" => $mehide,
   	        			      "BGCDEF" => $bgcdef,
   	        		       	"AUDN" => $auDN));
	$template->parse("BOOTMENU_LIST", ".Bootmenu");
	$medef = "";
	$bgcdef = "";
}


###################################################################################

include("computers_footer.inc.php");

?>
