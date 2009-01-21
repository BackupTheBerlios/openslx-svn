<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "pxeconfigs.dwt";

include('computers_header.inc.php');

###################################################################################

$mnr = 2;
$sbmnr = -1;
$mcnr = -1;

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################

$rbsDN = $_GET['rbsdn'];

$template->assign(array("PXEDN" => "",
								"PXECN" => "Noch keine PXE Boot Konfiguration angelegt",
								"TRANGES" => "",
								"PXECLIENTS" => "",
								"RBS" => "",
								"CN" => ""));

$pxe_array = get_pxeconfigs2("",array("dn","cn","timerange","rbservicedn","pxeclientdn"));

$template->define_dynamic("Pxeconf", "Webseite");

for ($i=0; $i<count($pxe_array); $i++){

	# PXE Config Name
	$pxename = "<a href='pxe.php?dn=".$pxe_array[$i]['dn']."&mnr=".$mnr."&sbmnr=".$i."' class='headerlink'>".$pxe_array[$i]['cn']."</a><br>";
	
	# Timerange Komponenten
	$trange = "";
	if (count($pxe_array[$i]['timerange']) > 1 ){
		foreach ($pxe_array[$i]['timerange'] as $tr){
			$exptime = array_merge(explode('_',$tr),$pxe_array[$i]['cn']);
			$wopltranges[$i][] = $exptime; # Für grafische Wo-Ansicht
			if ($exptime[0] == "X"){$exptime[0]="t&auml;glich";}
			# if ($exptime[1] == "X" && $exptime[2] == "X"){$exptime[1] = ""; $exptime[2]= "";}
			$trange .= $exptime[0].", von ".$exptime[1].":00 bis ".$exptime[2].":59 /  ";
		}
	}elseif (count($pxe_array[$i]['timerange']) == 1 ){
		$exptime = array_merge(explode('_',$pxe_array[$i]['timerange']), array($pxe_array[$i]['cn']));
		$wopltranges[$i] = $exptime; # Für grafische Wo-Ansicht
		if ($exptime[0] == "X"){$exptime[0]="t&auml;glich";}
		# if ($exptime[1] == "X" && $exptime[2] == "X"){$exptime[1] = ""; $exptime[2]= "";}
		$trange .= $exptime[0].", von ".$exptime[1].":00 bis ".$exptime[2].":59";
	}
	
	# PXE Config Clients
	$pxeclients = "";
	if (count($pxe_array[$i]['pxeclientdn']) > 1 ){
		#echo "ClientsARRAY: "; print_r($pxe_array[$i]['pxeclientdn']); echo "<br>";
		foreach ($pxe_array[$i]['pxeclientdn'] as $item) {
			$pxecldn = ldap_explode_dn($item, 1);
			$pxeclients .= $pxecldn[0]."<br>";
		}
		
	}elseif (count($pxe_array[$i]['pxeclientdn']) == 1 ){
		$pxecldn = ldap_explode_dn($pxe_array[$i]['pxeclientdn'], 1);
		$pxeclients = $pxecldn[0];
	}
	
	$template->assign(array("PXEDN" => $pxe_array[$i]['dn'],
									"PXECN" => $pxename,
									"TRANGES" => $trange,
									"PXECLIENTS" => $pxeclients,
   	        			      "RBS" => $rbsDN,
	   	        			   "MNR" => $mnr,
	   	        			   "SBMNR" => $sbmnr,
   	        		       	"AUDN" => $auDN));
	$template->parse("PXECONF_LIST", ".Pxeconf");
	
}


include("pxe_wochenplan.php");


###################################################################################

include("computers_footer.inc.php");

?>
