<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcppool.dwt";

include('dhcp_header.inc.php');

$mnr = 3; 
$sbmnr = -1;

###################################################################################

$mnr = $_GET['mnr'];
$sbmnr = $_GET['sbmnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$template->define_dynamic("Poolform", "Webseite");
$template->assign(array("POOLFORMULAR" => "",
								#"POOLDN" => "",
								"CN" => "",
								"SUBNETDN" => "",
								#"SUBNET" => "",
								#"RANGE1" => "",
								#"RANGE2" => "",
								"DESCRIPTION" => "",
								"STATEMENTS" => "",
								"DEFAULTLEASE" => "",
								"MAXLEASE" => "",
           		       	"MNR" => $mnr));

# DHCP Pools Daten holen						
$attributes = array("dn","cn","dhcphlpcont","dhcprange","description","dhcpstatements","dhcpoptallow",
							"dhcpoptdefault-lease-time","dhcpoptdeny","dhcpoptignore","dhcpoptmax-lease-time",
							"dhcpoptgeneric");
$pools = get_dhcppools($auDN, $attributes);
#print_r($pools);

if (count($pools) != 0){



$poolform = "
		<tr><td>
  		<table cellpadding='7' cellspacing='0' border='1' align='left' width='90%' style='border-width: 0 0 0 0;'>
			
				<form action='dhcppools_change.php' method='post'>
			
			<tr>
				<td width='30%' class='tab_h'><b>Subnetz</b></td>
				<td width='50%' class='tab_h'><b>IP Ranges (innerhalb Subnetz)</b></td>
				<td width='20%' class='tab_h'><b>Unknown Clients</b></td>
			</tr>
			
			   <!-- BEGIN DYNAMIC BLOCK: Dhcppools -->
			   
			<tr height='50' valign='top'>
				<td class='tab_d'><b>{SUBNET}/24</b><br><br>
				   <input type='checkbox' name='delpool[]' value='{POOLDN}' size='10' class='medium_form_field'>
					Pool l&ouml;schen (H&auml;kchen setzen)</td>
				
				<td class='tab_d'>
				      
				      <!-- BEGIN DYNAMIC BLOCK: Dhcpranges -->
				      
					<input type='Text' name='range1[]' value='{RANGE1}' size='15' maxlength='15' class='medium_form_field'>
					 &nbsp;&nbsp; - &nbsp;&nbsp;
					<input type='Text' name='range2[]' value='{RANGE2}' size='15' maxlength='15' class='medium_form_field'>
					<input type='hidden' name='oldrange1[]' value='{RANGE1}'>
					<input type='hidden' name='oldrange2[]' value='{RANGE2}'><br>
					<input type='hidden' name='rangepooldn[]' value='{RPOOLDN}'>
					   
					   <!-- END DYNAMIC BLOCK: Dhcpranges -->
					
					<input type='Text' name='addrange1[]' value='' size='15' maxlength='15' class='medium_form_field'>
					 &nbsp;&nbsp; - &nbsp;&nbsp;
					<input type='Text' name='addrange2[]' value='' size='15' maxlength='15' class='medium_form_field'>
				</td>
			
				<td class='tab_d'>
				   <select name='unknownclients[]' size='3' class='small_form_selectbox'>
				      {UCSELECT}
				   </select>
					<input type='hidden' name='olduc[]' value='{UCNOW}'> &nbsp;
				</td>
			</tr>
			<!--<tr>
			   <td colspan='3' class='tab_d'><input type='checkbox' name='delpool[]' value='{POOLDN}' size='10' class='medium_form_field'>
					Pool l&ouml;schen (H&auml;kchen setzen)</td>
			</tr>-->
			
			<input type='hidden' name='pooldn[]' value='{POOLDN}'>
			<input type='hidden' name='subnet[]' value='{SUBNET}'>
			<input type='hidden' name='subnetau[]' value='{SUBNETAU}'>
			   
			   <!-- END DYNAMIC BLOCK: Dhcppools -->
			
			<input type='hidden' name='mnr' value='{MNR}'>		

		</table></td>
  	</tr>
  	<tr>
		<td><input type='Submit' name='apply' value='anwenden' class='small_loginform_button'>
		</form></td>
	</tr>
	
	<tr>
  		<td height='50'></td>
  	</tr>";
  	
$template->assign(array("POOLFORMULAR" => $poolform));
$template->parse("POOLFORM_LIST", "Poolform");
#$template->clear_dynamic("Poolform");
#$template->clear_parse("POOLFORM_LIST");

$template->define_dynamic("Dhcppools", "Webseite");
$template->define_dynamic("Dhcpranges", "Webseite");
# Für jeden Pool ...
foreach ($pools as $pool){
	
   # DHCP Subnet des Pools 
   $subnet = ldap_explode_dn($pool['dhcphlpcont'],1);
	$subnetdnexp = ldap_explode_dn( $pool['dhcphlpcont'], 0);
	$subnetauexp = array_slice($subnetdnexp, 3);
	$subnetau = implode(',',$subnetauexp);	
	
	
   $template->clear_parse("DHCPRANGES_LIST");
   
   # DHCP Ranges
   if (count($pool['dhcprange']) != 0){
      #$template->define_dynamic("Dhcpranges", "Webseite");
      if (count($pool['dhcprange']) > 1){
   	foreach ($pool['dhcprange'] as $dhcprange){
   	   $iprange = explode('_',$dhcprange);
   		$template->assign(array(
   								"RANGE1" => $iprange[0],
   								"RANGE2" => $iprange[1],
                           "RPOOLDN" => $pool['dn']));
      	$template->parse("DHCPRANGES_LIST", ".Dhcpranges");
         $template->clear_dynamic("Dhcpranges");
   	}
   	}else{
   	   $iprange = explode('_',$pool['dhcprange']);
   	   $template->assign(array(
   								"RANGE1" => $iprange[0],
   								"RANGE2" => $iprange[1],
   								"RPOOLDN" => $pool['dn']));
      	$template->parse("DHCPRANGES_LIST", ".Dhcpranges");
         $template->clear_dynamic("Dhcpranges");	
   	}
   }
   
   # Unknown-Clients
   if ($pool['dhcpoptallow'] == "unknown-clients"){
      $unknownclients = "allow";
      $ucselectbox = "<option selected value='allow'> ALLOW </option>
                        <option value='deny'> DENY </option>
                        <option value='ignore'> IGNORE </option>";
   }
   elseif ($pool['dhcpoptignore'] == "unknown-clients") {
      $unknownclients = "ignore";
      $ucselectbox = "<option selected value='ignore'> IGNORE </option>
                        <option value='allow'> ALLOW </option>
                        <option value='deny'> DENY </option>";
   }
   else{
      $unknownclients = "deny";
      $ucselectbox = "<option selected value='deny'> DENY </option>
                        <option value='allow'> ALLOW </option>
                        <option value='ignore'> IGNORE </option>";
   }  
   
   $template->assign(array("POOLDN" => $pool['dn'],
   								"CN" => $pool['cn'],
   								"SUBNETDN" => $pool['dhcphlpcont'],
   								"SUBNET" => $subnet[0],
   								"SUBNETAU" => $subnetau,
   								"DESCRIPTION" => $pool['description'],
   								"STATEMENTS" => $pool['dhcpstatements'],
   								"UCSELECT" => $ucselectbox,
   								"UCNOW" => $unknownclients,
   								"DEFAULTLEASE" => $pool['dhcpoptdefault-lease-time'],
   								"MAXLEASE" => $pool['dhcpoptmax-lease-time'],
              		       	"MNR" => $mnr));
   $template->parse("DHCPPOOLS_LIST", ".Dhcppools");

}
}

###################################################################################

include("dhcp_footer.inc.php");

?>