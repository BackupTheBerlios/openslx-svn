<?php
include('../standard_header.inc.php');

$gbmcn = $_POST['gbmcn'];  $gbmcn = htmlentities($gbmcn);
$oldgbmcn = $_POST['oldgbmcn'];

$gbmDN = $_POST['gbmdn'];
$rbsDN = $_POST['rbsdn'];
$mnr = $_POST['mnr'];
$sbmnr = $_POST['sbmnr'];

$rootfstype = $_POST['rootfstype'];
$oldrootfstype = $_POST['oldrootfstype'];

$attribs = $_POST['attribs'];
if (count($attribs) != 0){
	foreach (array_keys($attribs) as $key){
		$atts[$key] = htmlentities($attribs[$key]);
	}
}
# print_r($meatts); echo "<br><br>";
$oldattribs = $_POST['oldattribs'];
if (count($oldattribs) != 0){
	foreach (array_keys($oldattribs) as $key){
		$oldatts[$key] = htmlentities($oldattribs[$key]);
	}
}
#print_r($oldatts); echo "<br><br>";


$seconds = 2;
$get_mecn = str_replace ( " ", "_", $mecn );
$url = "gbm.php?dn=".$gbmDN."&mnr=".$mnr."&sbmnr=".$sbmnr;

echo " 
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

##############################################
# GBM CN (DN) 

if ( $oldgbmcn == $gbmcn ){
	# $mesg = "keine Aenderung<br>";
}

if ( $oldgbmcn != "" && $gbmcn != "" && $oldgbmcn != $gbmcn ){
	echo "Name Generisches Boot Men&uuml; aendern<br>";
	# hier noch Syntaxcheck
	# Formulareingaben anpassen
	$expgbm = explode(" ",$gbmcn);
	foreach ($expgbm as $word){$expuc[] = ucfirst($word);}
	$gbmcn = implode(" ",$expuc);
	$gbmcn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $gbmcn);
	
	
	$newgbmDN = "cn=".$gbmcn.",".$rbsDN;
	print_r($newgbmDN); echo "<br><br>";
	
	if(move_subtree($gbmDN, $newgbmDN)){
		adjust_gbm_dn($newgbmDN, $gbmDN);
		$mesg = "Name Generisches Bootmen&uuml; erfolgreich ge&auml;ndert<br><br>";
		$gbmDN = $newgbmDN;
	}else{
		$mesg = "Fehler beim &auml;ndern des Namen des Generischen Bootmen&uuml;s!<br><br>";
	}
	
	# newsubmenu holen...
	$url = "gbm.php?dn=".$newgbmDN."&mnr=".$mnr."&sbmnr=".$sbmnr;
}

if ( $oldgbmcn != "" && $gbmcn == "" ){
	echo "Name Generisches Bootmen&uuml; loeschen!<br> 
			Dieses ist Teil des DN, Sie werden des Generische Boot Men&uuml; komplett l&ouml;schen<br><br>";
	echo "Wollen Sie das Generische Boot Men&uuml; <b>".$oldgbmcn."</b> wirklich l&ouml;schen?<br><br>
			<form action='gbm_delete.php' method='post'>
				Falls ja:<br><br>
				<input type='hidden' name='dn' value='".$gbmDN."'>
				<input type='hidden' name='name' value='".$oldgbmcn."'>
				<input type='Submit' name='apply' value='l&ouml;schen' class='small_loginform_button'><br><br>
			</form>
			<form action='".$url."' method='post'>
				Falls, nein:<br><br>
				<input type='Submit' name='apply' value='zur&uuml;ck' class='small_loginform_button'>
			</form>";
			$seconds = 600;
}

###################################
# RootFS Type

if ( $oldrootfstype == $rootfstype ){
	# $mesg = "keine Aenderung<br>";
}

if ( $oldrootfstype == "" && $rootfstype != "" ){
	$entryadd ['rootfstype'] = $rootfstype;
	if(ldap_mod_add($ds,$gbmDN,$entryadd)){
		$mesg = "Attribute <b>RootfsType</b> erfolgreich eingetragen<br><br>";
	}else{
		$mesg = "Fehler beim eintragen der Attribute <b>RootfsType</b><br><br>";
	}
}


if ( $oldrootfstype != "" && $rootfstype != "" && $oldrootfstype != $rootfstype ){
	echo "Root FS Type &auml;ndern<br>";
	$entrymod ['rootfstype'] = $rootfstype;
	if(ldap_mod_replace($ds,$gbmDN,$entrymod)){
		$mesg = "Attribute <b>RootfsType</b> erfolgreich geaendert<br><br>";
	}else{
		$mesg = "Fehler beim aendern der Attribute <b>RootfsType</b><br><br>";
	}
}


if ( $oldrootfstype != "" && $rootfstype == "" ){
	echo "Root FS Type l&ouml;schen!<br>";
	$entrydel ['rootfstype'] = array();
	if(ldap_mod_del($ds,$gbmDN,$entrydel)){
		$mesg = "Attribute <b>RootfsType</b> erfolgreich geloescht<br><br>";
	}else{
		$mesg = "Fehler beim loeschen der Attribute <b>RootfsType</b><br><br>";
	}
}


###################################
# restliche Attribute

$entryadd = array();
$entrymod = array();
$entrydel = array();

foreach (array_keys($atts) as $key){
	
	if ( $oldatts[$key] == $atts[$key] ){
		# nix 
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
	if(ldap_mod_add($ds,$gbmDN,$entryadd)){
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
	if(ldap_mod_replace($ds,$gbmDN,$entrymod)){
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
	if(ldap_mod_del($ds,$gbmDN,$entrydel)){
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