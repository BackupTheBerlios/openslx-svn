<?php
include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Remote Boot Service Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 4;
$mnr = -1; 
$sbmnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "new_gbm.dwt";

include("../class.FastTemplate.php");

include('rbs_header.inc.php');

###################################################################################

$mnr = $_GET['mnr'];
$sbmnr = $_GET['sbmnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createRBSMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$rbsDN = $_GET['rbsdn'];

$gbmcn = str_replace ( "_", " ", $_GET['gbmcn']);

# RBS Daten 				
$rbs_data = get_node_data($rbsDN, array("cn","nfsserverip","exportpath","tftpserverip","tftppath","nbdserverip"));
$template->assign(array("RBSCN" => $rbs_data['cn'],
								"TFTP" => $rbs_data['tftpserverip'],
								"TFTPPATH" => $rbs_data['tftppath'],
								"NFS" => $rbs_data['nfsserverip'],
								"NFSPATH" => $rbs_data['exportpath'],
								"NBD" => $rbs_data['nbdserverip']));
								

$options = "<option value='none' selected>----------------------------</option>
				<option value='nfs'><b>nfs://".$rbs_data['nfsserverip'].":/".$rbs_data['exportpath']."</b></option>
				<option value='nbd'>nbd://".$rbs_data['nbdserverip'].":</option>
				<option value='dnbd'>dnbd://".$rbs_data['nbdserverip'].":</option>";

$template->assign(array("GBMCN" => $gbmcn,
								"LABEL" => "",
								"KERNEL" => "",
								"INITRD" => "",
								"SELECTOPTIONS" => $options,
								"ROOTFS" => "",
								"IPAPPEND" => "",
								"RBSDN" => $rbsDN,
								"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr));



###################################################################################

include("rbs_footer.inc.php");

?>