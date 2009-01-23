<?php

include('../standard_header.inc.php');

# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "pxeconfig_default.dwt";

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

$template->assign(array("PXEDN" => "",
								"PXECN" => "Noch kein Default PXE Boot Men&uuml; angelegt",
								"TRANGES" => "",
								"RBS" => "",
								"CN" => ""));

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
		$exptime = array_merge(explode('_',$pxe_array[$i]['timerange']), array($pxe_array[$i]['cn']));
		$timeranges[$i] = $exptime; # Für grafische Wo-Ansicht
		if ($exptime[0] == "X"){$exptime[0]="t&auml;glich";}
		# if ($exptime[1] == "X" && $exptime[2] == "X"){$exptime[1] = ""; $exptime[2]= "";}
		$trange .= $exptime[0].", von ".$exptime[1].":00 bis ".$exptime[2].":59";
	}
	
	$pxename = "<a href='pxe.php?dn=".$pxe_array[$i]['dn']."&mnr=".$mnr."&sbmnr=".$sbmnr."' class='headerlink'>".$pxe_array[$i]['cn']."</a>";
	
	
	$template->assign(array("PXEDN" => $pxe_array[$i]['dn'],
									"PXECN" => $pxename,
   	        			      "TRANGES" => $trange,
   	        			      "RBS" => $rbsDN,
	   	        			   "MNR" => $mnr,
	   	        			   "SBMNR" => $sbmnr,
   	        		       	"AUDN" => $auDN));
	$template->parse("PXECONF_LIST", ".Pxeconf");
}

include("pxe_wochenplan.php");


###################################################################################

include("rbs_footer.inc.php");

?>
