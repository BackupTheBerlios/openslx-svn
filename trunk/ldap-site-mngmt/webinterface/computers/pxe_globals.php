<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "pxe_globals.dwt";

include('computers_header.inc.php');

$mnr = -1; 
$sbmnr = -1;
$mcnr = -1;

###################################################################################

$mnr = $_GET['mnr']; 
$sbmnr = $_GET['sbmnr'];
$mcnr = $_GET['mcnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################

$pxeDN = $_GET['dn'];
# DN, CN des übergeordneten Nodes (Host oder Group)
$pxednarray = ldap_explode_dn($pxeDN, 0);
$nodeDN = implode(',',array_slice($pxednarray,2));
#$nodeDN = $_GET['nodedn'];
$nodednarray = ldap_explode_dn($nodeDN, 1);

$attributes = array("dn","cn","rbservicedn","filename","timerange","allowoptions","console","default",
							"display","font","implicit","kbdmap","menumasterpasswd","menutitle",
							"noescape","onerror","ontimeout","prompt","say","serial","timeout","ldapuri","fileuri");
$pxe = get_node_data($pxeDN,$attributes);

# RBS Daten
$rbsDN = $pxe['rbservicedn'];
$rbsdata = get_node_data($rbsDN,array("cn","nfsserverip","exportpath","tftpserverip","tftppath","tftpclientconfpath"));

# Timerange Komponenten
$template->define_dynamic("TRanges", "Webseite");
if (count($pxe['timerange']) > 1){
	foreach($pxe['timerange'] as $tr){
		$exptime = explode('_',$tr);
		$template->assign(array("PXEDAY" => $exptime[0],
           			      		"PXEBEG" => $exptime[1],
           			     			"PXEEND" => $exptime[2]));
     	$template->parse("TRANGES_LIST", ".TRanges");	
	}
}else{
	$exptime = explode('_',$pxe['timerange']);
	$template->assign(array("PXEDAY" => $exptime[0],
           			      	"PXEBEG" => $exptime[1],
           			      	"PXEEND" => $exptime[2]));
	$template->parse("TRANGES_LIST", ".TRanges");	
}

# Filenames
$template->define_dynamic("Filenames", "Webseite");
if (count($pxe['filename']) > 1){
	foreach($pxe['filename'] as $fi){
		$template->assign(array("FILE" => $fi));
     	$template->parse("FILENAMES_LIST", ".Filenames");	
	}
}else{
	$exptime = explode('_',$pxe['filename']);
	$template->assign(array("FILE" => $pxe['filename']));
	$template->parse("FILENAMES_LIST", ".Filenames");	
}

$expcn = explode('_',$pxe['cn']);
$name = array_slice($expcn,1);
$pxecn = implode('_',$name);

# Bootmenü Einträge
$menuentries = get_menuentries($pxeDN,array("dn","menuposition","label","menulabel","menudefault","menupasswd","menuhide"));
# print_r($menuentries); echo "<br>";
$maxpos = count($menuentries)+1;

# Globale Parameter
$template->assign(array("PXEDN" => $pxeDN,
								"PXECN" => $pxecn,
								"TIMERANGE" => $pxe['timerange'],
           			      "TFTP" => $rbsdata['tftpserverip'],
           			      "TFTPFILE" => $rbsdata['tftpclientconfpath'],
           		       	#"LDAPURI" => $pxe['ldapuri'],
           			      "FILEURI" => $pxe['fileuri'],      			      
           		       	"ALLOW" => $pxe['allowoptions'],          			      
           		       	"CONSOLE" => $pxe['console'],
           		       	"DEFAULT" => $pxe['default'], 
           			      "DISPLAY" => $pxe['display'],          			      
           		       	"FONT" => $pxe['font'],
           		       	"IMPLICIT" => $pxe['implicit'],
           			      "KBDMAP" => $pxe['kbdmap'],          			      
           		       	"MENMPW" => $pxe['menumasterpasswd'],
           		       	"MENTIT" => $pxe['menutitle'],                   			      
           		       	"NOESC" => $pxe['noescape'],
           		       	"ONERR" => $pxe['onerror'],          			      
           		       	"ONTIME" => $pxe['ontimeout'],
           		       	"PROMPT" => $pxe['prompt'],          			      
           		       	"SAY" => $pxe['say'],
           		       	"SERIAL" => $pxe['serial'],
								"TIMEOUT" => $pxe['timeout'],
           		       	"NODEDN" => $nodeDN,
   	                  "NODE" => $nodednarray[0],
           		       	"DEFDN" => "cn=rbs,".$auDN,
           		       	"PXELINK" => "<a href='pxe.php?dn=".$pxeDN."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"BMLINK" => "<a href='pxe_bootmenue.php?dn=".$pxeDN."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr,
           		       	"MCNR" => $mcnr));
           		       	

# Für Submenü Einträge
$template->assign(array("SUBRBSDN" => "",
   	                  "SUBRBSCN" => "",
   	                  "SUBRBSAU" => ""));
if (count($subrbs) != 0){
$template->define_dynamic("Subrbs", "Webseite");
	foreach ($subrbs as $item){
		$rbsdnexp = ldap_explode_dn($item,1);
		$subrbscn = $rbsdnexp[0];
		$subrbsau = $rbsdnexp[2];
		#$subrbsexp = explode(',',$item['dn']);
		#$subrbsau = explode('=',$subrbsexp[2]);
		$template->assign(array("SUBRBSDN" => $item,
   	                        "SUBRBSCN" => $subrbscn,
   	                        "SUBRBSAU" => "[ ".$subrbsau." ]"));
   	$template->parse("SUBRBS_LIST", ".Subrbs");	
	} 
}

################################################
# Bootmenü Einträge 

$template->define_dynamic("Bootmenu", "Webseite");
$template->assign(array("MENDN" => "",
   	                  "MENULABEL" => "",
								"ANZEIGE" => "Noch kein Bootmen&uuml; Eintrag angelegt",
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
									"ANZEIGE" => "<a href='menuentry.php?dn=".$me['dn']."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr."' class='headerlink'>".$anzeige."</a>",
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

$dnexp = ldap_explode_dn($pxeDN, 1);
if ($dnexp[2] == "computers"){
	$nodetyp = "rbshost";
}
if ($dnexp[2] == "groups"){
	$nodetyp = "group";
}
# falls TR vorhanden dann soll sie gelöscht werden (flag deltr setzen)
if (count($pxe['timerange']) != 0){
	$template->assign(array("DELTR" => "1",
									"NODETYP" => $nodetyp));
}
else{
	$template->assign(array("DELTR" => "0",
									"NODETYP" => $nodetyp));
}

###################################################################################

include("computers_footer.inc.php");

?>
