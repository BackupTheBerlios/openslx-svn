<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcp_cond.dwt";

include('dhcp_header.inc.php');

###################################################################################

$mnr = $_GET['mnr'];
#$sbmnr = $_GET['sbmnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################


$csdn = $_GET['csdn'];

# DHCP Classes Daten holen						
$attributes = array("dn","cn","dhcphlpcont","dhcpcondtype","dhcpboolexpression",
							"dhcpoptvendor-encapsulated-options","dhcpoptgeneric","dhcpstatements");
$cs = get_node_data($csdn,$attributes);
 
print_r($cs);				



$template->assign(array("CSDN" => "",
								"CSCN" => "",
   							"DHCPCONT" => "",  
								"CSTYPE" => "",
								"CSBOOLEXP" => "",
   							"CSVEO" => "",
								"CSSTATEMENTS" => "",
   							"OPTIONS" => "",
   							"SCOPE" => "",
           		       	"MNR" => $mnr));

	
	if ( $cs['dhcphlpcont'] == $DHCP_SERVICE ) {
		$scope = "<b>Global</b>";
	}
	elseif ( $cs['dhcphlpcont'] ) {
		$subnetexp = ldap_explode_dn($cs['dhcphlpcont'],1);
		$scope = "Subnet<br><b>".$subnetexp[0]."</b>";
	}else{
		$scope = "";
	}
	

	if ($cs['dhcpstatements']) {
		if (count($cs['dhcpstatements']) > 1){
			foreach ($cs['dhcpstatements'] as $statement){
				$cs_statements .= "<br>$statement;";
			}
		}else{
			$cs_statements .= "<br>".$cs['dhcpstatements'].";";
		}
	}
	if ($cs['dhcpoptvendor-encapsulated-options']) {
		$veo = $cs['dhcpoptvendor-encapsulated-options'];
	}
	if ($cs['dhcpoptgeneric']) {
		#$cs_options = "<br>option vendor-encapsulated-options ".$cs['dhcpoptvendor-encapsulated-options'].";";
	}


   $template->assign(array("CSDN" => $csdn,
   								"CSCN" => $cs['cn'],
   								"DHCPCONT" => $cs['dhcphlpcont'],   
									"CSTYPE" => $cs['dhcpcondtype'],
									"CSBOOLEXP" => $cs['dhcpboolexpression'],
   								"CSVEO" => $veo,
   								"CSSTATEMENTS" => $cs_statements,
   								"OPTIONS" => $cs_options,
   								"SCOPE" => $scope,
              		       	"MNR" => $mnr));



###################################################################################

include("dhcp_footer.inc.php");

?>