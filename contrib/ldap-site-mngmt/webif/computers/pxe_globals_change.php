<?php
include('../standard_header.inc.php');

$pxeDN = $_POST['pxedn'];
$oldpxecn = "PXE_".$_POST['oldpxecn'];
$pxecn = "PXE_".$_POST['pxecn'];

$nodeDN = $_POST['nodedn'];
$mnr = $_POST['mnr'];
$sbmnr = $_POST['sbmnr'];
$mcnr = $_POST['mcnr'];

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


$seconds = 2;
$url = "pxe_globals.php?dn=".$pxeDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;
 
echo "
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 




 
################################################################## 
# Restliche Attribute

$entryadd = array();
$entrymod = array();
$entrydel = array();

foreach (array_keys($atts) as $key){
	
	if ( $oldatts[$key] == $atts[$key] ){
	
	}
	if ( $oldatts[$key] == "" && $atts[$key] != "" ){
		# hier noch Syntaxcheck
		$entryadd[$key] = $atts[$key];
	}
	if ( $oldatts[$key] != "" && $atts[$key] != "" && $oldatts[$key] != $atts[$key] ){
		# hier noch Syntaxcheck
		$entrymod[$key] = $atts[$key];
	}
	if ( $oldatts[$key] != "" && $atts[$key] == "" ){
		# hier noch Syntaxcheck
		$entrydel[$key] = $oldatts[$key];
	}
}

#print_r($entryadd); echo "<br>";
#print_r($entrymod); echo "<br>";
#print_r($entrydel); echo "<br>";


if (count($entryadd) != 0 ){
	#print_r($entryadd); echo "<br>";
	#echo "neu anlegen<br>"; 
	foreach (array_keys($entryadd) as $key){
		$addatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_add($ds,$pxeDN,$entryadd)){
		$mesg = "Attribute ".$addatts." erfolgreich eingetragen<br><br>";
	}else{
		$mesg = "Fehler beim eintragen der Attribute ".$addatts."<br><br>";
	}
}

if (count($entrymod) != 0 ){
	#print_r($entrymod); echo "<br>";
	#echo "&auml;ndern<br>";
	foreach (array_keys($entrymod) as $key){
		$modatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_replace($ds,$pxeDN,$entrymod)){
		$mesg = "Attribute ".$modatts." erfolgreich geaendert<br><br>";
	}else{
		$mesg = "Fehler beim aendern der Attribute ".$modatts."<br><br>";
	}
}

if (count($entrydel) != 0 ){
	#print_r($entrydel); echo "<br>";
	#echo "l&ouml;schen<br>";
	foreach (array_keys($entrydel) as $key){
		$delatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_del($ds,$pxeDN,$entrydel)){
		$mesg = "Attribute ".$delatts." erfolgreich geloescht<br><br>";
	}else{
		$mesg = "Fehler beim loeschen der Attribute ".$delatts."<br><br>";
	}
}




$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>