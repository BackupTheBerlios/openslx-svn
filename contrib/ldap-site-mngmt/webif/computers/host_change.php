<?php
include('../standard_header.inc.php');
$syntax = new Syntaxcheck;

$hostDN = $_POST['hostdn'];

$hostname = $_POST['hostname'];
$oldhostname = $_POST['oldhostname'];

$mac = $_POST['mac'];
$oldmac = $_POST['oldmac'];

$ip = $_POST['ip'];
$oldip = $_POST['oldip'];

$dhcp = $_POST['dhcpcont'];
$olddhcp = $_POST['olddhcp'];

$fixedaddress = $_POST['fixadd'];
$oldfixedaddress = $_POST['oldfixadd'];

$rbs = $_POST['rbs'];
$oldrbs = $_POST['oldrbs'];

$desc = $_POST['desc'];
$olddesc = $_POST['olddesc'];

$sbmnr = $_POST['sbmnr'];


$hostname = htmlentities($hostname);
$oldhostname = htmlentities($oldhostname);
$mac = htmlentities($mac);
$mac = strtolower($mac);
$oldmac = htmlentities($oldmac);
$ip = htmlentities($ip);
$oldip = htmlentities($oldip);
$desc = htmlentities($desc);
$olddesc = htmlentities($olddesc);
$dhcp = htmlentities($dhcp);
$olddhcp = htmlentities($olddhcp);

# sonstige Attribute
$attribs = $_POST['attribs'];
if (count($attribs) != 0){
	foreach (array_keys($attribs) as $key){
		$atts[$key] = htmlentities($attribs[$key]);
	}
}
#print_r($atts); echo "<br><br>";
$oldattribs = $_POST['oldattribs'];
if (count($oldattribs) != 0){
	foreach (array_keys($oldattribs) as $key){
		$oldatts[$key] = htmlentities($oldattribs[$key]);
	}
}
#print_r($oldatts); echo "<br><br>";



$mesg = "";
$dhcpchange = 0;
$seconds = 3;
$automatic_back = 1;
$url = 'host.php?host='.$hostname.'&sbmnr='.$sbmnr;


echo "  
<html>
<head>
	<title>AU Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>";

// $vc = $atts['dhcpoptvendor-encapsulated-options'];
// if ( $vc != "") {
// 	echo "SyntaxCheck VC $vc ->  ";
// 	if ( !$syntax->check_vendorcode_syntax($vc) ) {
// 		echo " Falsche Syntax<br><br>";
// 	}else{
// 		echo " OK<br><br>";
// 	}
// }

###########################################################
# Hostname aendern (MOVE LDAP Object)
# Sofort ausgefuehrth, da weitere parallele Aenderungen 
# am neuen DN erfolgen sollen

if ( $oldhostname != "" && $hostname != "" && $oldhostname != $hostname ){
	$mesg .= "<b>Hostname<br>";
	# Check ob Host schon existiert in AU/Domain
	if ( check_host_fqdn($hostname) ) {
		# Formulareingaben anpassen (Leerzeichen raus da Teil des DN)
		$hostname = preg_replace ( '/\s+([0-9a-zA-Z])/', '$1', $hostname);
		
		$newhostDN = "hostname=".$hostname.",cn=computers,".$auDN;
		# print_r($newhostDN); echo "<br><br>";
		if ( $result = modify_host_dn($hostDN, $newhostDN) ) {
			# HostDN anpassen -> alle weiteren Attribut-Aenderungen im neuen Objekt
			$hostDN = $newhostDN;
			$newhostname = get_rdn_value($newhostDN);
			$url = 'host.php?host='.$newhostname.'&sbmnr='.$sbmnr;
			$dhcpchange = 1;
			$mesg .= "erfolgreich in $hostname ge&auml;ndert</b><br><br>";
		}
		else {
			$mesg .= "konnte nicht in $hostname ge&auml;ndert werden!</b> (LDAP Move Object Fehler)<br><br>";
		}
	}
	else {
		$url = "hostoverview.php";
		$mesg .= "In der DNS Zone <b>$assocdom</b> existiert bereits ein Client mit Namen <b>$hostname</b>!<br><br>
					Bitte w&auml;hlen Sie einen anderen HOSTNAMEN,<br>oder l&ouml;schen
					Sie zun&auml;chst den gleichnamigen Client.<br><br>
					<a href=".$url." style='publink'><< &Uuml;bersicht Clients</a>";
		redirect(4, $url, $mesg, $addSessionId = TRUE);
		die;
	}
}

if ( $oldhostname != "" && $hostname == "" ){
	echo "Hostname l&ouml;schen!<br>>br>
			Dies ist Teil des DN, Sie werden den Rechner komplett l&ouml;schen<br><br>";
	echo "Wollen Sie den Rechner <b>".$oldhostname."</b> mit seinen Hardware-Profilen (MachineConfigs) 
			und PXE Bootmen&uuml;s wirklich l&ouml;schen?<br><br>
			<form action='host_delete.php' method='post'>
				Falls ja:<br><br>
				<input type='hidden' name='dn' value='".$hostDN."'>
				<input type='hidden' name='name' value='".$oldhostname."'>
				<input type='Submit' name='apply' value='l&ouml;schen' class='small_loginform_button'><br><br>
			</form>
			<form action='".$url."' method='post'>
				Falls, nein:<br><br>
				<input type='Submit' name='apply' value='zur&uuml;ck' class='small_loginform_button'>
			</form>";
			$seconds = 600;
}

#################################################
# IP Adresse, sofort ausgefuehrt, da spezielle
# Funktionen nach IP Aenderungen folgen

if ( $oldip == "" && $ip != "" ){
	#echo "IP neu anlegen<br>";
	# Wenn DHCP Subnet zu IP nicht existiert dann kein Eintrag DHCP
	if ( $network = test_ip_dhcpsubnet($ip)){
		$mesg .= "<b>Client bereits als dynamisch im DHCP eingetragen.<br>
				IP Adresse $ip kann nicht gesetzt werden, da kein Subnetz $network/24 im DHCP eingetragen ist</b><br><br>";
	}else{
		# Syntaxcheck
		if( $syntax->check_ip_syntax($ip) ){
			$newip_array = array($ip,$ip);
			$newip = implode('_',$newip_array);
			if (new_ip_host($newip,$hostDN,$auDN)){
				$mesg .= "IP erfolgreich eingetragen<br><br>";
				# Falls Host in DHCP dann Fixed-Address setzen
				if ( $olddhcp || $dhcp ) {
					$dhcpchange = 1;
					if ( $fixedaddress != "ip" ) {
						$fixedaddress = "ip";
					}
				}
			}else{
				$mesg .= "Fehler beim eintragen der IP<br><br>";
			}
		}
		else{
			$mesg .=  "Falsche IP Syntax<br><br>";
		}
	}
}

if ( $oldip != "" && $ip != "" && $oldip != $ip ){
	# IP Aendern
	if( $syntax->check_ip_syntax($ip) ){
		$newip_array = array($ip,$ip);
		$newip = implode('_',$newip_array);
		# print_r($newip); echo "<br><br>";
		$oldip_array = array($oldip,$oldip); 
		$oldipp = implode('_',$oldip_array);
		if (modify_ip_host($newip,$hostDN,$auDN,"")){
			$mesg .= "IP erfolgreich geaendert<br><br>";
			if ( $olddhcp || $dhcp ) {
				$dhcpchange = 1;
			}
// 			# falls Host ein RBS_Server ist
// 		   adjust_hostip_tftpserverip($oldip,$ip);
		}else{
			$mesg .= "Fehler beim aendern der IP<br><br>";
			# oldip die schon gelöscht wurde wieder einfügen
			new_ip_host($oldipp,$hostDN,$auDN);
		}
	}
	else{ $mesg .= "Falsche IP Syntax<br><br>"; }
}

if ( $oldip != "" && $ip == "" ){
	# IP loeschen
	if(delete_ip_host($hostDN,$auDN)){
		$mesg .= "IP erfolgreich geloescht<br><br>";
		if ( $olddhcp || $dhcp ) {
			$dhcpchange = 1;
		}
		if ( $fixedaddress != "" ) {
			$fixedaddress = "";
		}
		# falls Host ein RBS_Server ist
		adjust_hostip_tftpserverip($oldip,"");
	}else{
		$mesg .= "Fehler beim loeschen der IP<br><br>";
	}
}

#####################################
# MAC Adresse 
if ( $oldmac != $mac ) {
	if ( $oldmac == "" ){
		# MAC neu eintragen
		if( $syntax->check_mac_syntax($mac) ){
			$entry_add['hwaddress'] = $mac;
// 			if ( $olddhcp || $dhcp ) {
// 			  $dhcpchange = 1;
// 			}
		}else{
		  $mesg .= "SyntaxCheck MAC Adresse <b>$mac</b>:<br>-> ".$syntax->ERROR;
		  $automatic_back = 0;
		}
	}
	elseif ( $mac == "" ) {
		# MAC loeschen
		$entry_delete['hwaddress'] = $oldmac;
		# DHCP austragen
		$dhcp = "";
// 		if ( $olddhcp || $dhcp ) {
// 			$dhcpchange = 1;
// 		}
		$mesg .= "<b>MAC-Adresse f&uuml;r Eintrag im DHCP notwendig &nbsp;=>&nbsp; Client wird aus zentralem DHCP ausgetragen.</b><br><br>";
	}
	else {
		# MAC aendern 
		if( $syntax->check_mac_syntax($mac) ){
			$entry_replace['hwaddress'] = $mac;
// 			if ( $olddhcp || $dhcp ) {
// 				$dhcpchange = 1;
// 			}
		}else{
			$mesg .= "SyntaxCheck MAC Adresse <b>$mac</b>:<br>-> ".$syntax->ERROR;
			$automatic_back = 0;
		}
	}
}


###############################################################################
# DHCP Eintrag (erst nach den Anpassungen IP,MAC)
if ( $dhcp != $olddhcp){
	if ( $dhcp == "") {
		# DHCP austragen
		$entry_delete ['dhcphlpcont'] = array();
		
		$fixedaddress = "";
		# weitere DHCP Attribute loeschen
		foreach ( array("dhcpoptdefault-lease-time","dhcpoptmax-lease-time","dhcpoptvendor-encapsulated-options") as $dhcp_att) {
			$atts[$dhcp_att] = "";
		}
	}
	elseif ( $olddhcp == "") {
		# DHCP eintragen
		$entry_add ['dhcphlpcont'] = $dhcp;
		if ( $ip != "" ){
			$fixedaddress = "ip";
		}
	}
}

###############################################################################
# DHCP Option fixed-address (erst nach den Anpassungen IP,MAC,DHCP_Eintrag)
if ( $fixedaddress != $oldfixedaddress ){
	if ( $oldfixedaddress == "" ) {
		$entry_add ['dhcpoptfixed-address'] = $fixedaddress;
	}
	elseif ( $fixedaddress == "" ) {
		$entry_delete ['dhcpoptfixed-address'] = $oldfixedaddress;
	}
	else {
		$entry_replace ['dhcpoptfixed-address'] = $fixedaddress;
	}
}


#############################
# RBS
if ( $rbs != $oldrbs){
	if ( $rbs == "" ) {
		$entry_delete ['hlprbservice'] = array();
		$entry_delete ['dhcpoptnext-server'] = array();
		$entry_delete ['dhcpoptfilename'] = array();
	} else {
		$exprbs = ldap_explode_dn($rbs, 1);
		$dhcpdata = get_node_data($rbs,array("tftpserverip","initbootfile","tftproot"));
		$dhcpfilename = $dhcpdata['tftproot']."/".$dhcpdata['initbootfile'];
		if ( $oldrbs = "" ) {
			$entry_add ['hlprbservice'] = $rbs;
			$entry_add ['dhcpoptnext-server'] = $dhcpdata['tftpserverip'];
			$entry_add ['dhcpoptfilename'] = $dhcpfilename;
// 			rbs_adjust_host($hostDN, $rbs);
		}
		else {
			$entry_replace ['hlprbservice'] = $rbs;
			$entry_replace ['dhcpoptnext-server'] = $dhcpdata['tftpserverip'];
			$entry_replace ['dhcpoptfilename'] = $dhcpfilename;
// 			rbs_adjust_host($hostDN, $rbs);
		}
	}
}

#####################################
# Client Beschreibung
if ( $olddesc != $desc ) {
	if ( $olddesc == "" ) {
		$entry_add['description'] = $desc;
	}
	elseif ( $desc == "" ) {
		$entry_delete['description'] = $olddesc;
	}
	else {
		$entry_replace['description'] = $desc;
	}
}


foreach (array_keys($atts) as $key){
	if ( $oldatts[$key] != $atts[$key] ) {
		# Falls ldap_mod_add, ldap_mod_replace -> eventl. Syntax checken
		if ( $atts[$key] != "" ) {
			$att_syntax_check = 1;
			# vendor-encapsulated-options
			if ( $key == "dhcpoptvendor-encapsulated-options" && !$syntax->check_vendorcode_syntax($atts[$key]) ) {
				$att_syntax_check = 0;
			}
			if ( ($key == "dhcpoptmax-lease-time" || $key == "dhcpoptdefault-lease-time") && !$syntax->check_leasetime_syntax($atts[$key]) ) {
				$att_syntax_check = 0;
			}
			if ( !$att_syntax_check ){
				$mesg .= "SyntaxCheck Attribut <b>$key = $atts[$key]:</b><br>
				-> ".$syntax->ERROR."
				<br>&Auml;nderung des Attributs <b>$key</b> wird nicht &uuml;bernommen<br><br><br>";
				$automatic_back = 0;
				continue; # naechstes Attribut
			}
		}
		if ( $oldatts[$key] == "" ) {
			$entry_add[$key] = $atts[$key];
		}
		elseif ( $atts[$key] == "" ) {
			$entry_delete[$key] = $oldatts[$key];
		}
		else {
			$entry_replace[$key] = $atts[$key];
		}
	}
}

###############################################################################
# Aenderungen der Attribute in LDAP schreiben:
$ok_mesg = "<b>erfolgreich</b><br><br>";
$error_mesg = "<b>nicht erfolgreich!</b><br>(Fehler: ldap_mod, DN: $hostDN)<br><br>";

# ADD:
if ( count($entry_add) != 0 ) {
// 	echo "LDAP MOD ADD:<br>"; print_r($entry_add); echo "<br><br>";
	$mesg .= "<b>Attribut(e) hinzuf&uuml;gen<br>";
	$mesg .= ldapmod_log_output($entry_add,"add");
	if ($add_result = ldap_mod_add($ds,$hostDN,$entry_add)){
		if ( check_dhcpchange($entry_add,$dhcp) ) {
			$dhcpchange = 1;
		}
		$mesg .= $ok_mesg;
	}else{
		$mesg .= $error_mesg;
	}
}
# REPLACE:
if ( count($entry_replace) != 0 ) {
// 	echo "LDAP MOD REPLACE:<br>"; print_r($entry_replace); echo "<br><br>";
	$mesg .= "<b>Attribut(e) &auml;ndern<br>";
	$mesg .= ldapmod_log_output($entry_replace,"replace");
	if ($replace_result = ldap_mod_replace($ds,$hostDN,$entry_replace)){
		if ( check_dhcpchange($entry_replace,$dhcp) ) {
			$dhcpchange = 1;
		}
		$mesg .= $ok_mesg;
	}else{
		$mesg .= $error_mesg;
	}
}
# DELETE:
if ( count($entry_delete) != 0 ) {
// 	echo "LDAP MOD DELETE:<br>"; print_r($entry_delete); echo "<br><br>";
	$mesg .= "<b>Attribut(e) l&ouml;schen<br>";
	$mesg .= ldapmod_log_output($entry_delete,"delete");
	if ($del_result = ldap_mod_del($ds,$hostDN,$entry_delete)){
		if ( check_dhcpchange($entry_delete,$dhcp) ) {
			$dhcpchange = 1;
		}
		$mesg .= $ok_mesg;
	}else{
		$mesg .= $error_mesg;
	}
}

##################################
# DHCP Modify Timestamp 
if ( $dhcpchange ){
// if ( $dhcphlpcont != "" && $dhcpchange ){
	$mesg .= update_dhcpmtime($auDN);
// 	$mesg .= "DHCP CHANGE<br><br>";
}

##################################
# Restlichen Output
if ( $mesg == "" ) {
	$mesg = "<b>Keine &Auml;nderungen</b><br><br>";
// 	$seconds = 200;
}

if ( $automatic_back ) {
$mesg .= "<br>Sie werden in $seconds Sekunden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>Falls nicht, klicken Sie hier <a href=".$url." style='publink'>zur&uuml;ck</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);
}
else {
	$mesg .= "<br><br><a href=$url style='publink'><b>gelesen</b> &nbsp;&nbsp;(<< zur&uuml;ck)</a>";
	echo $mesg;
}


echo "
</td></tr></table></body>
</html>";


################
# Funktionen
function check_dhcpchange ($entry_mod_array,$dhcp) {
	$dhcp_attributes = array("ipaddress","hwaddress","dhcpoptfixed-address","hlprbservice","dhcpoptnext-server","dhcpoptfilename","dhcpoptdefault-lease-time","dhcpoptmax-lease-time","dhcpoptvendor-encapsulated-options");
	
	if ( array_key_exists("dhcphlpcont", $entry_mod_array) && dhcp) {
		return 1;
	}
	foreach ($dhcp_attributes as $att) {
		if ( array_key_exists($att, $entry_mod_array) && $dhcp ) {
			return 1;
			break;
		}
	}
	return 0;
}


?>