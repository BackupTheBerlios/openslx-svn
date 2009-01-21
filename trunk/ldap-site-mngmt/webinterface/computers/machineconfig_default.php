<?php

include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Computers Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 3;
$mnr = 3; 
$sbmnr = -1;
$mcnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "machineconfig_default.dwt";

include("../class.FastTemplate.php");

include('computers_header.inc.php');

###################################################################################

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################

$template->assign(array("MCDN" => "",
								"MCCN" => "Noch keine Default MachineConfig angelegt",
								"TRANGES" => "",
           			      "MCDESC" => "Noch keine Default MachineConfig angelegt"));


$mc_array = get_machineconfigs("cn=computers,".$auDN,array("dn","cn","timerange","description"));
# print_r($mc_array);


$template->define_dynamic("Machineconf", "Webseite");

for ($i=0; $i<count($mc_array); $i++){
	# Timerange Komponenten
	$trange = "";
	if (count($mc_array[$i]['timerange']) > 1 ){
		foreach ($mc_array[$i]['timerange'] as $tr){
			$exptime = array_merge(explode('_',$tr),$mc_array[$i]['description']);
			$timeranges[$i][] = $exptime; # Für grafische Wo-Ansicht
			if ($exptime[0] == "X"){$exptime[0]="t&auml;glich";}
			# if ($exptime[1] == "X" && $exptime[2] == "X"){$exptime[1] = ""; $exptime[2]= "";}
			$trange .= $exptime[0].", von ".$exptime[1].":00 bis ".$exptime[2].":59 /  ";
		}
	}else{
		$exptime = array_merge(explode('_',$mc_array[$i]['timerange']), $mc_array[$i]['description']);
		$timeranges[$i] = $exptime; # Für grafische Wo-Ansicht
		if ($exptime[0] == "X"){$exptime[0]="t&auml;glich";}
		# if ($exptime[1] == "X" && $exptime[2] == "X"){$exptime[1] = ""; $exptime[2]= "";}
		$trange .= $exptime[0].", von ".$exptime[1].":00 bis ".$exptime[2].":59";
	}
	
	$template->assign(array("MCDN" => $mc_array[$i]['dn'],
									"MCCN" => $mc_array[$i]['cn'],
   	        			      "TRANGES" => $trange,
	           			      "MCDESC" => $mc_array[$i]['description'],
   	        		       	"AUDN" => $auDN));
	$template->parse("MACHINECONF_LIST", ".Machineconf");
}

#get_entry_number($mc_array[3]['dn'],"machineconfig");

include("mc_wochenplan.php");


###################################################################################

include("computers_footer.inc.php");

?>
