<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcp_classes.dwt";

include('dhcp_header.inc.php');

###################################################################################

$mnr = $_GET['mnr'];
#$sbmnr = $_GET['sbmnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

# DHCP Classes Daten holen						
$attributes = array("dn","cn","dhcphlpcont","dhcpstatements","description","submatchexp",
							"dhcpoptvendor-encapsulated-options","dhcpoptallow",
							"dhcpoptdefault-lease-time","dhcpoptdeny","dhcpoptignore","dhcpoptmax-lease-time",
							"dhcpoptgeneric","hlprbservice","dhcpoptfilename","dhcpoptnext-server");
$classes = get_dhcpclasses($auDN, $attributes);
#print_r($classes);				



$template->assign(array("CLASSDN" => "",
								"CLASSCN" => "",
   							"DHCPCONT" => "",   								
   							"DHCPSRV" => $DHCP_SERVICE,
								"CLASSDESC" => "",
								"CLASSSTATEMENTS" => "",
   							"OPTIONS" => "",
   							"SUBCLASSES" => "",
   							"CHE" => "",
   							"ACT" => "",
           		       	"MNR" => $mnr));

$template->define_dynamic("Dhcpclasses", "Webseite");

foreach ($classes as $class) {

	$class_statements = "";
	$class_options = "&nbsp;";
	$checked = "";
	$active = "";
	
	if ( $class['dhcphlpcont'] ) {
		$checked = " checked";
		$active = "<br><b><code class='red_font_object'>aktiv</code></b>";
	}
	

	if ($class['dhcpstatements']) {
		if (count($class['dhcpstatements']) > 1){
			foreach ($class['dhcpstatements'] as $statement){
				$class_statements .= "<br>$statement;";
			}
		}else{
			$class_statements .= "<br>".$class['dhcpstatements'].";";
		}
	}
	if ($class['dhcpoptvendor-encapsulated-options']) {
		$class_options = "<br>option vendor-encapsulated-options ".$class['dhcpoptvendor-encapsulated-options'].";";
	}
	
	#echo "<br>Subclasses $class[cn]:<br>";
	$subclasses = get_dhcpsubclasses($class['dn'],$attributes);
	#print_r($subclasses);
	#echo "<br>";
	
	
	if ($subclasses) {
		foreach ($subclasses as $subclass){	
			$subclass_data .= "<br>subclass \"$class[cn]\" $subclass[submatchexp]";
			if ($subclass['dhcpstatements']) {
				$subclass_data .= "<br>&nbsp;&nbsp;&nbsp; $subclass[dhcpstatements];";
			}
			if ($subclass['dhcpoptgeneric']) {
				if (count($subclass['dhcpoptgeneric']) > 1) {
					foreach ($subclass['dhcpoptgeneric'] as $opt) {
						$subclass_data .= "<br>&nbsp;&nbsp;&nbsp; $opt";
					} 
				}else{
					$subclass_data .= "<br>&nbsp;&nbsp;&nbsp; ".$subclass['dhcpoptgeneric'];
				}
			}
			$subclass_data .= "<br>&nbsp;";
		}	
	}else{
		$subclass_data = "<br>&nbsp;";
	}


   $template->assign(array("CLASSDN" => $class['dn'],
   								"CLASSCN" => $class['cn'],
   								"DHCPCONT" => $class['dhcphlpcont'],   								
   								"DHCPSRV" => $DHCP_SERVICE,
   								"CLASSDESC" => $class['description'],
   								"CLASSSTATEMENTS" => $class_statements,
   								"OPTIONS" => $class_options,
   								"SUBCLASSES" => $subclass_data,
   								"CHE" => $checked,
   								"ACT" => $active,
              		       	"MNR" => $mnr));
   $template->parse("DHCPCLASSES_LIST", ".Dhcpclasses");

}

###################################################################################

include("dhcp_footer.inc.php");

?>