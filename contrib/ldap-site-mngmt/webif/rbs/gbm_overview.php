<?php

include('../standard_header.inc.php');

# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "gbm_overview.dwt";

include('rbs_header.inc.php');

###################################################################################

$mnr = -1; 
$sbmnr = -1;
$mcnr = -1;

$mnr = $_GET['mnr'];
$sbmnr = $_GET['sbmnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createRBSMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$rbsDN = $_GET['rbsdn'];

$template->assign(array("GBMDN" => "",
								"GBMCN" => "Noch keine Generischen Boot Men&uuml;s angelegt",
								"KERNEL" => "",
								"FS" => ""));

# Generic Bootmenüs
$generic_bms = get_menuentries($rbsDN,array("dn","cn","label","kernel","nfsroot","nbdroot"));

$template->define_dynamic("Genericbm", "Webseite");
$template->define_dynamic("Offers", "Webseite");

foreach ($generic_bms as $gbm){
	if ($gbm['nfsroot'] != ""){$fs = "NFS";}
	if ($gbm['nbdroot'] != ""){$fs = "NBD";}
	
	$gbmname = "<a href='gbm.php?dn=".$gbm['dn']."&mnr=".$mnr."&sbmnr=".$sbmnr."' class='headerlink'>".$gbm['cn']."</a>";
	
	$template->assign(array("GBMDN" => $gbm['dn'],
									"GBMCN" => $gbmname,
	   	        		      "KERNEL" => $gbm['kernel'],
	   	        			   "FS" => $fs,
	   	        			   "MNR" => $mnr,
	   	        			   "SBMNR" => $sbmnr,
	   	        			   "RBSDN" => $rbsDN));
	$template->parse("GENERICBM_LIST", ".Genericbm");
}


###################################################################################

include("rbs_footer.inc.php");

?>
