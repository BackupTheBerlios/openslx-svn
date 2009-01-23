<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcp_condstmts.dwt";

include('dhcp_header.inc.php');

###################################################################################

$mnr = $_GET['mnr'];
#$sbmnr = $_GET['sbmnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

# DHCP Classes Daten holen						
$attributes = array("dn","cn","dhcphlpcont","dhcpcondtype","dhcpboolexpression",
							"dhcpoptvendor-encapsulated-options","dhcpoptgeneric","dhcpstatements");
$condstatements = get_dhcpcondstatements($attributes);
 
#print_r($condstatements);				



$template->assign(array("CSDN" => "",
								"CSCN" => "",
   							"DHCPCONT" => "",  
								"CSTYPE" => "",
								"CSBOOLEXP" => "",
   							"CSVEO" => "",
								"CSSTATEMENTS" => "",
   							"CSGENOPTS" => "",
   							"SCOPE" => "",
           		       	"MNR" => $mnr));

$template->define_dynamic("Dhcpcondstatements", "Webseite");

foreach ($condstatements as $cs) {
	$scope = "<code class='red_font_object'>nicht aktiv</code>";
	$cs_statements = "";
	$veo = "";
	$cs_genopts= "";
	
	if ( $cs['dhcphlpcont'] == $DHCP_SERVICE ) {
		$scope = "<b>Global</b>";
	}
	elseif ( $cs['dhcphlpcont'] ) {
		$subnetexp = ldap_explode_dn($cs['dhcphlpcont'],1);
		$scope = "Subnet &nbsp;<b>".$subnetexp[0]."</b>";
	}else{
		
	}
	if ($cs['dhcpstatements']) {
		if (count($cs['dhcpstatements']) > 1){
			foreach ($cs['dhcpstatements'] as $statement){
				$cs_statements .= "$statement<br>";
			}
		}else{
			$cs_statements .= $cs['dhcpstatements']."<br>";
		}
	}
	if ($cs['dhcpoptvendor-encapsulated-options']) {
		$veo = "option vedor-encapsulated-options<br>".$cs['dhcpoptvendor-encapsulated-options']."<br>";
	}
	if ($cs['dhcpoptgeneric']) {
		if (count($cs['dhcpoptgeneric']) > 1) {
			foreach ($cs['dhcpoptgeneric'] as $opt) {
				$cs_genopts .= "$opt<br>";
			} 
		}else{
			$cs_genopts .= $cs['dhcpoptgeneric']."<br>";
		}
	}


   $template->assign(array("CSDN" => $cs['dn'],
   								"CSCN" => $cs['cn'],
   								"DHCPCONT" => $cs['dhcphlpcont'],   
									"CSTYPE" => $cs['dhcpcondtype'],
									"CSBOOLEXP" => $cs['dhcpboolexpression'],
   								"CSVEO" => $veo,
   								"CSSTATEMENTS" => $cs_statements,
   								"CSGENOPTS" => $cs_genopts,
   								"SCOPE" => $scope,
              		       	"MNR" => $mnr));
   $template->parse("DHCPCONDSTATEMENTS_LIST", ".Dhcpcondstatements");

}

###################################################################################

include("dhcp_footer.inc.php");

?>