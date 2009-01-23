<?php

#print_r($all_roles[$rootAU]['roles']);
$classadmin = 0;
if ($all_roles[$rootAU]['roles']) {
	foreach ($all_roles[$rootAU]['roles'] as $role) {
		switch ($role){ 
		case 'MainAdmin':
			$classadmin = 1;
			break;
		case 'DhcpAdmin':
			$classadmin = 1;
			break;
		}
	}
}
if ($classadmin){
	$class_form_element = "";
	$classformsubmit = "<input type='Submit' name='apply' value='anwenden' class='tiny_loginform_button'>";
}else{
	# readonly
	$class_form_element = " disabled";
}

# DHCP Classes Daten holen						
$attributes = array("dn","cn","dhcphlpcont","dhcpstatements","description","submatchexp",
							"dhcpoptvendor-encapsulated-options","dhcpoptallow",
							"dhcpoptdefault-lease-time","dhcpoptdeny","dhcpoptignore","dhcpoptmax-lease-time",
							"dhcpoptgeneric","hlprbservice","dhcpoptfilename","dhcpoptnext-server");
$classes = get_dhcpclasses($rootAU, $attributes);
#print_r($classes);				



$template->assign(array("CLASSDN" => "",
								"CLASSCN" => "",
   							"DHCPCONT" => "",   								
   							"DHCPSRV" => $DHCP_SERVICE,
								"CLASSDESC" => "",
								"CLASSSTATEMENTS" => "",
   							"CLASSOPTIONS" => "",
   							"SUBCLASSES" => "",
   							"CHE" => "",
   							"ACT" => "",
   							"CFE" => "",
   							"CLASSFORMSUBMIT" => ""));

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
			$i=0;
			foreach ($class['dhcpstatements'] as $statement){
				if ($i == 0) {
					$class_statements .= "$statement;";
				}else{
					$class_statements .= "<br>$statement;";
				}
				$i++;
			}
		}else{
			$class_statements .= $class['dhcpstatements'].";";
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
   								"CLASSOPTIONS" => $class_options,
   								"SUBCLASSES" => $subclass_data,
   								"CHE" => $checked,
   								"ACT" => $active,
   								"CFE" => $class_form_element,
   								"CLASSFORMSUBMIT" => $classformsubmit));
   $template->parse("DHCPCLASSES_LIST", ".Dhcpclasses");

}

?>