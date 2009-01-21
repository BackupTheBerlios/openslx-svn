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
           		       	"PXELINK" => "<a href='pxe.php?dn=".$pxeDN."&mnr=".$mnr."' class='headerlink'>",
           		       	"BMLINK" => "<a href='pxe_bootmenue.php?dn=".$pxeDN."&mnr=".$mnr."' class='headerlink'>",
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr));


###################################################################################

include("computers_footer.inc.php");

?>
