<?php
include('../standard_header.inc.php');
$syntax = new Syntaxcheck;

$rbscn = "RBS_".$_POST['rbscn'];
$oldrbscn = "RBS_".$_POST['oldrbscn'];
$tftpserverip = $_POST['tftpserverip'];
$oldtftpserverip = $_POST['oldtftpserverip'];
$rbsoffer = $_POST['rbsoffer'];
$oldrbsoffer = $_POST['oldrbsoffer'];

$tftpserver = $_POST['tftpserver'];
$oldtftpserverdn = $_POST['oldtftpserverdn'];

$host_array = get_hosts($auDN,array("dn","hostname","ipaddress"));

$rbsDN = $_POST['rbsdn'];
$nodeDN = "cn=rbs,".$auDN;

$mnr = $_POST['mnr'];
$sbmnr = $_POST['sbmnr'];
$mcnr = $_POST['mcnr'];

# sosntige Attribute
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

 
echo "
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>";

$mesg = "";
$seconds = 200;
$url = "rbservice.php?rbsdn=".$rbsDN."&mnr=".$mnr;
$dhcpchange = 0;


$entry_add = array();
$entry_replace = array();
$entry_del = array();

##############################################
# RBS CN => DN => Objekt Move

if ( $oldrbscn != "" && $rbscn != "" && $oldrbscn != $rbscn ){
	$mesg .= "RBS Name aendern<br>";
	# hier noch Syntaxcheck
	# Formulareingaben anpassen
	$exprbs = explode(" ",$rbscn);
	foreach ($exprbs as $word){$expuc[] = ucfirst($word);}
	$rbscn = implode(" ",$expuc);
	$rbscn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $rbscn);
	
	$newrbsDN = "cn=".$rbscn.",".$nodeDN;
// 	print_r($newrbsDN); echo "<br><br>";
	
	if(move_subtree($rbsDN, $newrbsDN)){
		adjust_rbs_dn($newrbsDN, $rbsDN);
		$rbsDN = $newrbsDN;
		$url = "rbservice.php?rbsdn=".$newrbsDN."&mnr=".$mnr;
		$mesg .= "RBS Name erfolgreich ge&auml;ndert<br><br>";
	}else{
		$mesg .= "Fehler beim &auml;ndern des RBS Namen!<br><br>";
	}
}

if ( $oldrbscn != "" && $rbscn == "" ){
	echo "Gruppenname loeschen!<br> 
			Dieses ist Teil des DN, Sie werden den RBS komplett l&ouml;schen<br><br>";
	echo "Wollen Sie den RBS Dienst <b>".$oldrbscn."</b> wirklich l&ouml;schen?<br><br>
			<form action='rbservice_delete.php' method='post'>
				Falls ja:<br><br>
				<input type='hidden' name='dn' value='".$pxeDN."'>
				<input type='hidden' name='name' value='".$oldrbscn."'>
				<input type='Submit' name='apply' value='l&ouml;schen' class='small_loginform_button'><br><br>
			</form>
			<form action='".$url."' method='post'>
				Falls, nein:<br><br>
				<input type='Submit' name='apply' value='zur&uuml;ck' class='small_loginform_button'>
			</form>";
			$seconds = 600;
}


#####################################################
# TFTP Server IP (nur aus eigenen Max-IP-Blocks)

if ( $tftpserverip != $oldtftpserverip ) {
	
	if ( $tftpserverip == "" ) {
// 		$entry_del ['tftpserverip'] = array();
	}
	elseif ( $syntax->check_ip_syntax($tftpserverip) ) {
		
		if ( check_tftpip_in_mipb($tftpserverip) ) {
			if ( $oldtftpserverip == "" ) {
				$entry_add ['tftpserverip'] = $tftpserverip;
			} else {
				$entry_replace ['tftpserverip'] = $tftpserverip;
			}
		}
		else {
			$mesg .= "Gew&auml;hlte TFTP Server IP <b>$tftpserverip</b> nicht aus dem eigenem IP Bereich!<br> Konnte nicht eingetragen werden.<br><br>";
		}
		
	}
}

#####################################
# Offer ändern 

// if ( $rbsoffer != "none" && $rbsoffer == $oldrbsoffer ){
// 	$mesg = "Sie haben die gleiche Abteilung ausgew&auml;hlt<br>
// 				Keine &Auml;nderung!";
// }
// 
// if ( $rbsoffer != "none" && $rbsoffer != $oldrbsoffer ){
// 	$entryoffer ['rbsofferdn'] = $rbsoffer;
// 	if(ldap_mod_replace($ds,$rbsDN,$entryoffer)){
// 		$mesg = "RBS Offer erfolgreich ge&auml;ndert<br><br>";
// 	}
// 	else{
// 		$mesg = "Fehler beim &auml;ndern des RBS Offers!<br><br>";
// 	}
// }

/*if ( $rbsoffer == "off" && $olddhcpoffer != "" ){
   $entryoffer ['dhcpofferdn'] = array();
	if(ldap_mod_del($ds,$dhcpDN,$entryoffer)){
		$mesg = "DHCP Service Offer erfolgreich ge&auml;ndert<br><br>";
	}
	else{
		$mesg = "Fehler beim &auml;ndern des DHCP Service Offers!<br><br>";
	}
}*/


 
#####################################
# Restliche Attribute
foreach (array_keys($atts) as $key){
	if ( $oldatts[$key] != $atts[$key] ) {
		if ( $oldatts[$key] == "" ){
			# hier noch Syntaxcheck
			$entry_add[$key] = $atts[$key];
		}
		elseif ( $atts[$key] == "" ){
			# hier noch Syntaxcheck
			$entry_del[$key] = $oldatts[$key];
		}
		else {
			# hier noch Syntaxcheck
			$entry_replace[$key] = $atts[$key];
		}
	}
}

#print_r($entry_add); echo "<br>";
#print_r($entry_replace); echo "<br>";
#print_r($entry_del); echo "<br>";

###############################################################################
# Aenderungen der Attribute in LDAP schreiben:
$ok_mesg = "<b>erfolgreich</b><br><br>";
$error_mesg = "<b>nicht erfolgreich!</b><br>(Fehler: ldap_mod, DN: $rbsDN)<br><br>";

# ADD:
if ( count($entry_add) != 0 ) {
// 	echo "LDAP MOD ADD:<br>"; print_r($entry_add); echo "<br><br>";
	$mesg .= "<b>Attribut(e) hinzuf&uuml;gen<br>";
	$mesg .= ldapmod_log_output($entry_add,"add");
	if ($add_result = ldap_mod_add($ds,$rbsDN,$entry_add)){
		if ( check_dhcpchange($entry_add) ) {
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
	if ($replace_result = ldap_mod_replace($ds,$rbsDN,$entry_replace)){
		if ( check_dhcpchange($entry_replace) ) {
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
	if ($del_result = ldap_mod_del($ds,$rbsDN,$entry_delete)){
		if ( check_dhcpchange($entry_delete) ) {
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
// 	$mesg .= update_dhcpmtime($auDN);
	$mesg .= "DHCP CHANGE<br><br>";
}

##################################
# Restlichen Output
if ( $mesg == "" ) {
	$mesg = "<b>Keine &Auml;nderungen</b><br><br>";
	$seconds = 1;
}

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";


# -----------------------------------------------------------------------------
# Funktionen
# -----------------------------------------------------------------------------
function check_dhcpchange ($entry_mod_array) {
	$dhcp_attributes = array("tftpserverip","initbootfile");
	
	foreach ($dhcp_attributes as $att) {
		if ( array_key_exists($att, $entry_mod_array) ) {
			return 1;
			break;
		}
	}
	return 0;
}

function ldapmod_log_output ($entry_mod_array,$mode) {
	$mesg = "";
	foreach (array_keys($entry_mod_array) as $mod_attr) {
		$wert = $entry_mod_array[$mod_attr];
		switch ($mod_attr) {
			case "tftpserverip": $attribut = "TFTP Server IP"; break;
			case "initbootfile": $attribut = "Initial Boot File"; break;
			case "tftproot":     $attribut = "RBS Root"; break;
			case "description":  $attribut = "Beschreibung RBS"; break;
			default: $attribut = $mod_attr; break;
		}
		$mesg .= "  &nbsp;&nbsp;- $attribut";
		if ( $mode == "delete" ) { $mesg .= "<br>"; }
		else { $mesg .= "  &nbsp;=>&nbsp; $wert<br>"; }
	}
	return $mesg;
}
?>