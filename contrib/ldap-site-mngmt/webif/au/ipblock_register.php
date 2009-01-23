<?php

include('../standard_header.inc.php');
$syntax = new Syntaxcheck;


$ipnet = $_POST['ip'];
#print_r($ipnet);
$childauDN = $_POST['childdn'];
$childzone = $_POST['childzone'];
$only_subnet = $_POST['only_subnet'];

$childaudnexp = ldap_explode_dn($childauDN, 1);
$childau = $childaudnexp[0];
#print_r($childau);


$url = "child_au.php?cau=".$childau;
$seconds = 2;

echo "
<html>
<head>
	<title>IP Address Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='20' cellspacing='0' width='100%'>
<tr><td>";

$net = implode(".",$ipnet).".0";

if ( $syntax->check_ip_syntax($net) && $ipnet[0] != "0" ){
	#echo "<b>$net</b><br>";
	if ($only_subnet) {
		$mipb = $net."_".$net;
	}else{
		$mipb = $net."_".implode(".",$ipnet).".255";
	}
	#echo "<b>$mipb</b><br>";
	if (!$ou = check_for_existing_mipbs($mipb) ) {
		#echo "Netz <b>$net</b> anlegen ...<br><br>";
		
		# MIPB und FIPB in ChildAU eintragen
		$childau_entry['MaxIPBlock'] = $mipb;
		$childau_entry['FreeIPBlock'] = $mipb;

		if ( ldap_mod_add($ds,$childauDN,$childau_entry) ){
		
			$seconds = 500;
			if ($only_subnet){
				echo "IP Netz <b>$net</b> erfolgreich in AU <b>$childau</b> eingetragen!<br><br>";	
			}else{
				echo "IP Netz/Adressbereich <b>$mipb</b> erfolgreich in AU <b>$childau</b> eingetragen (delegiert)!<br><br>";
			}
			echo "Soll das passende DHCP Subnet Objekt mit den folgenden Daten angelegt werden?";
			
			# DHCP Subnet Objekt eintragen
			$netmask_array = $ipnet;
			for ($i=0; $i<count($ipnet); $i++) {
				if ($ipnet[$i] != "0"){
					$netmask_array[$i] = "255";
				}
			}
			$netmask = implode(".",$netmask_array).".0";
			$routers_array = $ipnet;
			for ($i=0; $i<count($ipnet); $i++) {
				if ($ipnet[$i] == "0"){
					$routers_array[$i] = "254";
				}
			}
			$dhcpoptrouters = implode(".",$routers_array).".254";
			$dhcpoptbroadcastaddress = implode(".",$ipnet).".255";
			$dhcpoptdomainname = $childzone;
			
			# DHCP Data one scope up (Global)
			$global_options = array("dhcpoptdefault-lease-time","dhcpoptmax-lease-time");
			$global_data = get_node_data($DHCP_SERVICE,$global_options);
			# Default Lease Time
			if ( $global_data['dhcpoptdefault-lease-time'] ) {
				$defaultlease_select = "<option value='' selected>".$LEASE_TIMES[$global_data['dhcpoptdefault-lease-time']]." &nbsp;
					[".$global_data['dhcpoptdefault-lease-time']." s]</option>";
			}else{
				$defaultlease_select = "<option value='' selected> ------- </option>";
			}
			foreach (array_keys($LEASE_TIMES) as $sec) {
				if ( $sec != $global_data['dhcpoptdefault-lease-time'] ) {
					$defaultlease_select .= "<option value='$sec'>$LEASE_TIMES[$sec] &nbsp;[$sec s]</option>";
				}
			}
			$defaultlease_select .= "</select>";
			# Max Lease Time
			if ( $global_data['dhcpoptmax-lease-time'] ) {
				$maxlease_select = "<option value='' selected>".$LEASE_TIMES[$global_data['dhcpoptmax-lease-time']]." &nbsp;
					[".$global_data['dhcpoptmax-lease-time']." s]</option>";
			}else{
				$maxlease_select = "<option value='' selected> ------- </option>";
			}
			foreach (array_keys($LEASE_TIMES) as $sec) {
				if ( $sec != $global_data['dhcpoptmax-lease-time'] ) {
					$maxlease_select .= "<option value='$sec'>$LEASE_TIMES[$sec] &nbsp;[$sec s]</option>";
				}
			}
			$maxlease_select .= "</select>";
			
			echo "</td><tr><td><table cellpadding='7' cellspacing='0' border='1' align='left' width='40%' 
										style='border-color: #B0B0B0; border-style: solid; border-width: 3 3 2 3;'>
						<form action='add_subnet_object.php' method='post'>
						
						<input type='hidden' name='subnet' value='$net'>
						<input type='hidden' name='attribs[dhcpoptbroadcast-address]' value='$dhcpoptbroadcastaddress'>
						<input type='hidden' name='childaudn' value='$childauDN'>
						<input type='hidden' name='url' value='$url'>
				<tr>
					<td class='tab_hgrey' colspan='2'><b>DHCP Subnet Objekt</b></td>
				</tr>
				<tr> 
					<td width='40%' class='tab_dgrey'>Subnet</td>
					<td width='60%' class='tab_dgrey'>&nbsp;<b>$net</b></td>
				</tr> 
				<tr>
					<td width='40%' class='tab_dgrey'>Netmask</td>
					<td width='60%' class='tab_dgrey'>
					<input type='Text' name='netmask' value='$netmask' size='30' class='medium_form_field'></td>
				</tr>
				<tr> 
					<td width='40%' class='tab_dgrey'>Routers</td>
					<td width='60%' class='tab_dgrey'>
					<input type='Text' name='attribs[dhcpoptrouters]' value='$dhcpoptrouters' size='30' class='medium_form_field'></td>
				</tr>
				<tr>
					<td width='40%' class='tab_dgrey'>Broadcast Address</td>
					<td width='60%' class='tab_dgrey'>
					<input type='Text' name='attribs[dhcpoptbroadcast-address]' value='$dhcpoptbroadcastaddress' size='30' class='medium_form_field'></td>
				</tr>
				<tr>
					<td width='40%' class='tab_dgrey'>Domain Name</td>
					<td width='60%' class='tab_dgrey'>
						<input type='Text' name='attribs[dhcpoptdomain-name]' value='$dhcpoptdomainname' size='30' class='medium_form_field'>
						</td>
				</tr>
				<tr>
					<td width='40%' class='tab_dgrey'>Default Lease Time</td>
					<td width='60%' class='tab_dgrey'><select name='attribs[dhcpoptdefault-lease-time]' size='4' class='form_200_selectbox'>
						$defaultlease_select</td>
				</tr>
				<tr>
					<td width='40%' class='tab_dgrey'>Max Lease Time</td>
					<td width='60%' class='tab_dgrey'><select name='attribs[dhcpoptmax-lease-time]' size='4' class='form_200_selectbox'>
						$maxlease_select</td>
				</tr>
				<tr>
					<td width='40%' class='tab_dgrey'>Beschreibung</td>
					<td width='60%' class='tab_dgrey'>
						<input type='Text' name='attribs[description]' value='' size='30' class='medium_form_field'>
						</td>
				</tr>
				";
			
			echo "</table></td></tr><tr><td style='border-width: 0 0 0 0;'>
					<input type='Submit' name='apply' value='anlegen' class='small_loginform_button'>
						</form></td></tr><tr><td>";
			$mesg .= "<br>
						Falls <b>nicht</b>,<br> 
						klicken Sie hier <a href=$url style='publink'>zur&uuml;ck ohne Subnet Objekt anzulegen</a>";
			#if (add_dhcpsubnet ($net,$DHCP_SERVICE,$netmask,$atts,$childauDN)){			
   		#	echo "<br>DHCP Subnet Objekt erfolgreich angelegt<br>";
   		#}else{
   		#	echo "<br>Fehler beim anlegen des DHCP Subnet Objekts!<br>";
   		#}
			
		}else{
			echo "<br>Fehler beim Eintragen des IP Adressbereichs!<br>";
		}
		
	}else{
		echo "Netz <b>$net</b> existiert bereits in AU <b>$ou</b><br>
				Wird nicht angelegt<br><br>";
		$mesg .= "<br>keine &Auml;nderung<br>";
		$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
	}	
}else{
	echo "Netz <b>$net</b> ist keine korrekte IP Adresse<br>";
	$mesg .= "<br>keine &Auml;nderung<br>";
	$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
}


redirect($seconds, $url, $mesg, $addSessionId = TRUE);



echo "
</td></tr></table>
</head>
</html>";


function check_for_existing_mipbs($mipb){

	global $ds, $suffix, $auDN, $ldapError;
		
	#$mipb_match = 0;
	$existing_mipbs = get_maxipblocks_au_childs($auDN);

	foreach (array_keys($existing_mipbs) as $key){
		if ( count($existing_mipbs[$key]) >  1 ) {
			foreach ($existing_mipbs[$key] as $test ) {
				if ( check_ip_in_iprange($mipb,$test) ){
			 		#echo $test." existiert bereits in AU $key<br><br>";
					#$mipb_match = 1;
					return $key;
				}
			}
		}
		elseif( count($existing_mipbs[$key]) ==  1 ){
			if ( check_ip_in_iprange($mipb,$existing_mipbs[$key]) ){
				#echo $existing_mipbs[$key]." existiert bereits in AU $key<br><br>";
				#$mipb_match = 1;
				return $key;
			}
		}
	}
	
	return 0;
}
?>