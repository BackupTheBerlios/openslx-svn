<?php
include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dns_au_zones.dwt";

include('dns_header.inc.php');

###################################################################################

$mnr = 1; 

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDNSMenu($rollen, $mnr);

###################################################################################

$template->assign(array(
	"AUOU" => "Noch keine untergordnete AU angelegt",
	"AUCN" => "",
	"AUDN" => "",
	"AUZONE" => "",
	"AUIPS" => ""));

$attributes = array("dn","ou","associateddomain");
#$aunits = get_all_aus($attributes);

$backbone_nodes = get_childau($auDN,$attributes);

$template->define_dynamic("Aus", "Webseite");

foreach ($backbone_nodes as $bn) {
	
	$aulist = "";
	$aunits = get_childau_sub($bn['dn'],$attributes);
	#print_r($aunits);echo "<br><br>";
	$aunits = array_slice($aunits,1);
	$aunits = array_natsort($aunits,"ou","ou");
	if ($aunits){
		$aulist .= "<table cellpadding='2' cellspacing='0' border='1' align='left' width='100%' style='border-width: 0 0 0 0;'>";
		foreach ($aunits as $au) {					
						$aulist .= "
						<tr>
							<td class='tab_dgrey' width='50%'>$au[ou]&nbsp;</td>
							<td class='tab_dgrey'>
								<input type='Text' name='auzone[]' value='$au[associateddomain]' size='23' class='medium_form_field'>
								<input type='hidden' name='oldauzone[]' value='$au[associateddomain]'>
								<input type='hidden' name='audn[]' value='$au[dn]'></td>
						</tr>";
		}					
		$aulist .= "</table>";
	}else{
		$aulist = "Keine untergeordneten AUs";
	}
	
	$template->assign(array(
		"AUOU" => $bn['ou'],
		"AUCN" => $bn['cn'],
		"AUDN" => $bn['dn'],
		"AUZONE" => $bn['associateddomain'],
		"AUIPS" => "",
		"AULIST" => $aulist));
	$template->parse("AUS_LIST", ".Aus");

}

###################################################################################

include("dns_footer.inc.php");

?>