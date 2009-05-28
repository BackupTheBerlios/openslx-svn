<?php
// Aenderungen der Host Attribute von hw_host -> Keine DHCP relevanten Attribute

include('../standard_header.inc.php');

$syntax = new Syntaxcheck;

$hostDN = $_POST['hostdn'];
$hostname = $_POST['hostname'];
$sbmnr = $_POST['sbmnr'];

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


$seconds = 200;
$url = 'hwhost.php?host='.$hostname.'&sbmnr='.$sbmnr;
 
echo "  
<html>
<head>
	<title>AU Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>";

#################################### 
# Attribute auf Aenderung prufen

$entryadd = array();
$entrymod = array();
$entrydel = array();

foreach (array_keys($atts) as $key){
	if ( $oldatts[$key] != $atts[$key] ) {
// 		# Falls ldap_mod_add, ldap_mod_replace -> Syntax checken
// 		if ( $atts[$key] != "" ) {
// 			# vendor-encapsulated-options
// 			if ( $key == "dhcpoptvendor-encapsulated-options" && !$syntax->check_vendorcode_syntax($atts[$key]) ) {
// 				$att_syntax_check = 0;
// 				echo "SyntaxCheck Attribut <b>$key = $atts[$key]</b> -> Falsche Syntax<br>&Auml;nderung des Attributs <b>$key</b> wird nicht &uuml;bernommen<br><br>";
// 				continue; # naechstes Attribut
// 			}
// 		}
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
		$mesg .= $ok_mesg;
	}else{
		$mesg .= $error_mesg;
	}
}


##################################
# Restlichen Output
if ( $mesg == "" ) {
	$mesg = "<b>Keine &Auml;nderungen</b><br><br>";
	$seconds = 2;
}

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "
</td></tr></table></body>
</html>";


?>