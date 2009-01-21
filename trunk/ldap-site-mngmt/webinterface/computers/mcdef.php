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
$webseite = "mcdef.dwt";

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

$mcDN = $_GET['dn'];

$attributes = array("dn","cn","description","timerange","language","start-x","start-snmp","start-sshd",
							"start-xdmcp","start-rwhod","start-cron","start-printdaemon","crontab-entries",
							"tex-enable","netbios-workgroup","vmware");
$mc = get_node_data($mcDN,$attributes);
#print_r($mc);

$exp = explode(',',$mcDN);
$node = array_slice($exp,1);
$nodeDN = implode(',',$node);

# Timerange Komponenten
$template->define_dynamic("TRanges", "Webseite");
if (count($mc['timerange']) > 1){
	foreach($mc['timerange'] as $tr){
		$exptime = explode('_',$tr);
		$template->assign(array("MCDAY" => $exptime[0],
     									"MCBEG" => $exptime[1],
      								"MCEND" => $exptime[2]));
     	$template->parse("TRANGES_LIST", ".TRanges");	
	}
}else{
	$exptime = explode('_',$mc['timerange']);
	$template->assign(array("MCDAY" => $exptime[0],
     								"MCBEG" => $exptime[1],
      							"MCEND" => $exptime[2]));
	$template->parse("TRANGES_LIST", ".TRanges");	
}

$expcn = explode('_',$mc['cn']);
$name = array_slice($expcn,1);
$mccn = implode('_',$name);

$template->assign(array("MCDN" => $mcDN,
								"MCCN" => $mccn,
           			      "MCDESC" => $mc['description'], 
           			      "LANG" => $mc['language'],
           			      "X" => $mc['start-x'],          			      
           		       	"SNMP" => $mc['start-snmp'],
           		       	"SSHD" => $mc['start-sshd'],
           			      "XDMCP" => $mc['start-xdmcp'],          			      
           		       	"RWHOD" => $mc['start-rwhod'],
           		       	"CRON" => $mc['start-cron'],
           		       	"CRONTAB" => "",                  			      
           		       	"PRINTD" => $mc['start-printdaemon'],
           		       	"TEX" => $mc['tex-enable'],          			      
           		       	"NETBIOS" => $mc['netbios-workgroup'],
           		       	"VMWARE" => $mc['vmware'],         			      
           		       	"NODEDN" => $nodeDN,
           		       	"DEFDN" => "cn=computers,".$auDN,
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr,
           		       	"MCNR" => $mcnr));

$template->define_dynamic("Crontab", "Webseite");
if ( count($mc['crontab-entries']) != 0 ){
	if ( count($mc['crontab-entries']) > 1 ){
		foreach ($mc['crontab-entries'] as $crontab){
			$template->assign(array("CRONTAB" => $crontab));
     		$template->parse("CRONTAB_LIST", ".Crontab");	
		}
	}
	if ( count($mc['crontab-entries']) == 1 ){
		$template->assign(array("CRONTAB" => $mc['crontab-entries']));
     	$template->parse("CRONTAB_LIST", ".Crontab");
	}
}
$template->assign(array("CRONTAB" => ""));
$template->parse("CRONTAB_LIST", ".Crontab");

################################################ 
# MC kopieren

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


# falls TR vorhanden dann soll sie gelöscht werden (flag deltr setzen)
if (count($mc['timerange']) != 0){
	$template->assign(array("DELTR" => "1"));
}
else{
	$template->assign(array("DELTR" => "0"));
}

###################################################################################

include("computers_footer.inc.php");

?>