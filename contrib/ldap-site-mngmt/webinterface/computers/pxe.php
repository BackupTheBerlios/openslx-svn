<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "pxe.dwt";

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

$template->assign(array("HDN" => "",
								"HN" => "",
								"GDN" => "",
								"GN" => ""));

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
$rbsdata = get_node_data($rbsDN,array("cn","tftpserverip","tftppath","tftpclientconfpath"));

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


$expcn = explode('_',$pxe['cn']);
$name = array_slice($expcn,1);
$pxecn = implode('_',$name);


$template->assign(array("PXEDN" => $pxeDN,
								"PXECN" => $pxecn,
								"TIMERANGE" => $pxe['timerange'],
								"NODEDN" => $nodeDN,
								"NODE" => $nodednarray[0],
								"DEFDN" => "cn=rbs,".$auDN,
								"OPTLINK" => "<a href='pxe_globals.php?dn=".$pxeDN."&mnr=".$mnr."' class='headerlink'>",
								"BMLINK" => "<a href='pxe_bootmenue.php?dn=".$pxeDN."&mnr=".$mnr."' class='headerlink'>",
								"MNR" => $mnr,
								"SBMNR" => $sbmnr,
								"MCNR" => $mcnr));




################################################ 
# PXE zuordnen

$hostorgroup = $exp[0];
$hgexp = explode('=',$exp[0]);


$hosts_array = get_hosts($auDN,array("dn","hostname"),"");
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
