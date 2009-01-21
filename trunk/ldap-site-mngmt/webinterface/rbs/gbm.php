<?php
include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Remote Boot Service Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 4;
$mnr = -1; 
$sbmnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "gbm.dwt";

include("../class.FastTemplate.php");

include('rbs_header.inc.php');

###################################################################################

$mnr = $_GET['mnr'];
$sbmnr = $_GET['sbmnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createRBSMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$gbmDN = $_GET['dn'];

$template->assign(array("TFTPROOT" => "",
								"TFTPKERNEL" => "",
								"TFTPPXE" => "",
                        "TFTPCLIENTCONF" => "",
								"NFS" => "",
								"NFSPATH" => "",
								"NBD" => ""));

# rbservice und pxe daten (voerst nur ein rbs)
$rbs_array = get_rbservices($auDN,array("dn","cn"));
$rbsDN = $rbs_array[0]['dn'];
# RBS Daten 					
$rbs_data = get_node_data($rbsDN, array("cn","tftpserverip","tftproot","tftpkernelpath","tftpclientconfpath",
                                          "tftppxepath","nfsserverip","exportpath","nbdserverip","fileserveruri"));
$template->assign(array("RBSCN" => $rbs_data['cn'],
								"TFTPIP" => $rbs_data['tftpserverip'],
								"TFTPROOT" => $rbs_data['tftproot'],
								"TFTPKERNEL" => $rbs_data['tftpkernelpath'],
								"TFTPPXE" => $rbs_data['tftppxepath'],
                        "TFTPCLIENTCONF" => $rbs_data['tftpclientconfpath'],
								"NFS" => $rbs_data['nfsserverip'],
								"NFSPATH" => $rbs_data['exportpath'],
								"NBD" => $rbs_data['nbdserverip']));
								

$template->assign(array("GBMDN" => $gbmDN,
								"GBMCN" => "",
								"LABEL" => "",
								"KERNEL" => "",
								"INITRD" => "",
								"FSTYPE" => "",
								"ROOTFS" => "",
								"DEBUG" => "",
								"MISC" => "",
								"IPAPPEND" => ""));

# GBM Daten		
$attributes = array("dn","cn","label","kernel","initrd","rootfs","rootfstype","rootfspath","debug","appendmisc","ipappend");				
$gbm = get_node_data($gbmDN, $attributes);

$selectboxmax = count($rbs_data['fileserveruri']) + 1;
$fsuriselectbox = "<select name='rootfs' size='".$selectboxmax."' class='rootfs_form_selectbox'>
                  <option value='none'>---------------------------------</option>";
if ( $rbs_data['fileserveruri'] != "" ){
   foreach ($rbs_data['fileserveruri'] as $fsuri){
      $fsuriselectbox .= "<option value='".$fsuri."'>".$fsuri."</option>";
   }
}
$fsuriselectbox .= "</select>
					   <input type='hidden' name='oldrootfs' value='".$gbm['rootfs']."'>";

if ($gbm['rootfstype'] == 'nfs'){
	$options = "<select name='rootfstype' size='4' class='rootfs_form_selectbox'>
					<option value='nfs' selected><b>nfs://".$rbs_data['nfsserverip'].":/".$rbs_data['exportpath']."</b></option>
					<option value=''>---------------------------------</option>
					<option value='nbd'>nbd://".$rbs_data['nbdserverip'].":</option>
					<option value='dnbd'>dnbd://".$rbs_data['nbdserverip'].":</option>
					</select>
					<input type='hidden' name='oldrootfstype' value='".$gbm['rootfstype']."'>";
}
if ($gbm['rootfstype'] == 'nbd'){
	$options = "<select name='rootfstype' size='4' class='rootfs_form_selectbox'>
					<option value='nbd' selected><b>nbd://".$rbs_data['nbdserverip'].":</b></option>
					<option value=''>---------------------------------</option>
					<option value='nfs'>nfs://".$rbs_data['nfsserverip'].":/".$rbs_data['exportpath']."</option>
					<option value='dnbd'>dnbd://".$rbs_data['nbdserverip'].":</option>
					</select>
					<input type='hidden' name='oldrootfstype' value='".$gbm['rootfstype']."'>";
}
if ($gbm['rootfstype'] == 'dnbd'){
	$options = "<select name='rootfstype' size='4' class='rootfs_form_selectbox'>
					<option value='dnbd' selected><b>dnbd://".$rbs_data['nbdserverip'].":</b></option>
					<option value=''>---------------------------------</option>
					<option value='nfs'>nfs://".$rbs_data['nfsserverip'].":/".$rbs_data['exportpath']."</option>
					<option value='nbd'>nbd://".$rbs_data['nbdserverip'].":</option>
					</select>
					<input type='hidden' name='oldrootfstype' value='".$gbm['rootfstype']."'>";
}
#if ($gbm['rootfstype'] != 'nfs' && $gbm['rootfstype'] != 'nbd' && $gbm['rootfstype'] != 'dnbd'){
if ($gbm['rootfstype'] == 'none' ){
	$options = "<select name='rootfstype' size='4' class='rootfs_form_selectbox'>
					<option value='' selected>---------------------------------</option>
					<option value='nfs'><b>nfs://".$rbs_data['nfsserverip'].":/".$rbs_data['exportpath']."</b></option>
					<option value='nbd'>nbd://".$rbs_data['nbdserverip'].":</option>
					<option value='dnbd'>dnbd://".$rbs_data['nbdserverip'].":</option>
					</select>
					<input type='hidden' name='oldrootfstype' value='".$gbm['rootfstype']."'>";
}


$template->assign(array("GBMCN" => $gbm['cn'],
								"LABEL" => $gbm['label'],
								"KERNEL" => $gbm['kernel'],
								"INITRD" => $gbm['initrd'],
								"FSURISELECT" => $fsuriselectbox,
								"SELECTOPTIONS" => $options,
								"ROOTFS" => $gbm['rootfs'],
								"DEBUG" => $gbm['debug'],
								"MISC" => $gbm['appendmisc'],
								"IPAPPEND" => $gbm['ipappend'],
								"RBSDN" => $rbsDN,
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr));


###################################################################################

include("rbs_footer.inc.php");

?>