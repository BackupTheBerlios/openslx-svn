<?php

include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Remote Boot Service Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 4;
$mnr = 2; 
$sbmnr = -1;
$mcnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "gbm_overview.dwt";

include("../class.FastTemplate.php");

include('rbs_header.inc.php');

###################################################################################

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createRBSMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$template->assign(array("GBMDN" => "",
								"GBMCN" => "Noch keine Generischen Boot Men&uuml;s angelegt",
								"KERNEL" => "",
								"FS" => ""));

# rbservice und pxe daten (voerst nur ein rbs)
$rbs_array = get_rbservices($auDN,array("dn","cn"));
$rbsDN = $rbs_array[0]['dn'];

# Generic Bootmenüs
$generic_bms = get_menuentries($rbsDN,array("dn","cn","label","kernel","nfsroot","nbdroot"));

$template->define_dynamic("Genericbm", "Webseite");
$template->define_dynamic("Offers", "Webseite");
foreach ($generic_bms as $gbm){
	if ($gbm['nfsroot'] != ""){$fs = "NFS";}
	if ($gbm['nbdroot'] != ""){$fs = "NBD";}
	$template->assign(array("GBMDN" => $gbm['dn'],
									"GBMCN" => $gbm['cn'],
	   	        		      "KERNEL" => $gbm['kernel'],
	   	        			   "FS" => $fs));
	$template->parse("GENERICBM_LIST", ".Genericbm");
}


###################################################################################

include("rbs_footer.inc.php");

?>
