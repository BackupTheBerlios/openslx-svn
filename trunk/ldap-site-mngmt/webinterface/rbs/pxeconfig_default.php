<?php

include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Remote Boot Service Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 4;
$mnr = 3; 
$sbmnr = -1;
$mcnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "pxeconfig_default.dwt";

include("../class.FastTemplate.php");

include('rbs_header.inc.php');

###################################################################################

$mnr = $_GET['mnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createRBSMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$template->assign(array("PXEDN" => "",
								"PXECN" => "Noch kein Default PXE Boot Men&uuml; angelegt",
								"TRANGES" => "",
								"RBS" => "",
								"CN" => ""));

# rbservice und pxe daten (voerst nur ein rbs)
$rbs_array = get_rbservices($auDN,array("dn","cn"));
$rbsDN = $rbs_array[0]['dn'];
$pxe_array = get_pxeconfigs($rbsDN,array("dn","cn","timerange","rbservicedn"));
# print_r($pxe_array);

$template->define_dynamic("Pxeconf", "Webseite");

for ($i=0; $i<count($pxe_array); $i++){
	# Timerange Komponenten
	$trange = "";
	if (count($pxe_array[$i]['timerange']) > 1 ){
		foreach ($pxe_array[$i]['timerange'] as $tr){
			$exptime = array_merge(explode('_',$tr),$pxe_array[$i]['cn']);
			$timeranges[$i][] = $exptime; # Für grafische Wo-Ansicht
			if ($exptime[0] == "X"){$exptime[0]="t&auml;glich";}
			# if ($exptime[1] == "X" && $exptime[2] == "X"){$exptime[1] = ""; $exptime[2]= "";}
			$trange .= $exptime[0].", von ".$exptime[1].":00 bis ".$exptime[2].":59 /  ";
		}
	}else{
		$exptime = array_merge(explode('_',$pxe_array[$i]['timerange']), $pxe_array[$i]['cn']);
		$timeranges[$i] = $exptime; # Für grafische Wo-Ansicht
		if ($exptime[0] == "X"){$exptime[0]="t&auml;glich";}
		# if ($exptime[1] == "X" && $exptime[2] == "X"){$exptime[1] = ""; $exptime[2]= "";}
		$trange .= $exptime[0].", von ".$exptime[1].":00 bis ".$exptime[2].":59";
	}
	
	$template->assign(array("PXEDN" => $pxe_array[$i]['dn'],
									"PXECN" => $pxe_array[$i]['cn'],
   	        			      "TRANGES" => $trange,
   	        			      "RBS" => $pxe_array[$i]['rbservicedn'],
   	        		       	"AUDN" => $auDN));
	$template->parse("PXECONF_LIST", ".Pxeconf");
}

include("pxe_wochenplan.php");


###################################################################################

include("rbs_footer.inc.php");

?>
