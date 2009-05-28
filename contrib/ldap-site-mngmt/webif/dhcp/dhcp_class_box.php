<?php

// $subclass_details = 0;
$subclass_details = $_GET['scd'] || 0;

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



$template->assign(array("CLASSBOX" => ""
// 						 "CLASSDN" => "",
// 								"CLASSCN" => "",
//    							"DHCPCONT" => "",   								
//    							"DHCPSRV" => $DHCP_SERVICE,
// 								"CLASSDESC" => "",
// 								"CLASSSTATEMENTS" => "",
//    							"CLASSOPTIONS" => "",
//    							"SUBCLASSES" => "",
//    							"CHE" => "",
//    							"ACT" => "",
//    							"CFE" => "",
//    							"CLASSFORMSUBMIT" => ""
							));

// $template->define_dynamic("Dhcpclasses", "Webseite");

if ( count($classes) > 0 ) {

$class_box = "
<tr>
  		<td colspan='2'>
  		<table cellpadding='7' cellspacing='0' border='1' align='left' width='90%' style='border-width: 3 3 3 3;'>
				<form action='dhcpclasses_change.php' method='post'>
			<tr>
				<td width='80%' class='tab_dgrey' colspan='3'><b>Global g&uuml;ltige DHCP Classes</b>&nbsp;&nbsp; - &nbsp; Falls <b>aktiv</b> gelten Optionen f&uuml;r alle matchenden Clients</td>
				<td width='20%' class='tab_dgrey'>$classformsubmit</td>
			</tr>";

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
	
		if ( $subclass_details && $parent_file) {
		
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
			$subclass_data .= "<br><b><a href='$parent_file?mnr=$mnr&scd=0' class='headerlink'>< No Subclass Details</a></b>";
		}
		else{
			$subclass_data = "<br><b><a href='$parent_file?mnr=$mnr&scd=1' class='headerlink'>Subclass Details ></a></b>";
		}
	}else{
		$subclass_data = "<br>&nbsp;";
	}

	$class_box .= "
			<tr valign='top'>
				<td width='15%' class='tab_dgrey'><input type='checkbox' name='dhcp[".$class['dn']."]' value='$DHCP_SERVICE' $checked $class_form_element>$active</td>
				<td width='85%' class='tab_dgrey' colspan='2'><b>".$class['cn']."</b><br>$class_statements $class_options $subclass_data</td>
				<td class='tab_dgrey'>&nbsp;</td>
			</tr>
			
			
			<input type='hidden' name='olddhcp[".$class['dn']."]' value='".$class['dhcphlpcont']."'>
			";

//   /* $template->assign(array("CLASSDN" => $class['dn'],
//    								"CLASSCN" => $class['cn'],
//    								"DHCPCONT" => $class['dhcphlpcont'],   								
//    								"DHCPSRV" => $DHCP_SERVICE,
//    								"CLASSDESC" => $class['description'],
//    								"CLASSSTATEMENTS" => $class_statements,
//    								"CLASSOPTIONS" => $class_options,
//    								"SUBCLASSES" => $subclass_data,
//    								"CHE" => $checked,
//    								"ACT" => $active,
//    								"CFE" => $class_form_element,
//    								"CLASSFORMSUBMIT" => $classformsubmit));
//    $template->parse("DHCPCLASSES_LIST", ".Dhcpclasses");*/

}

$class_box .= "
			<input type='hidden' name='backurl' value='$parent_file?mnr=$mnr'>
			   </form>
		</table>
		</td>
  	</tr>
  	<tr>
		<td height='40' colspan='2'></td>
	</tr>";

	$template->assign(array("CLASSBOX" => $class_box));
}

?>