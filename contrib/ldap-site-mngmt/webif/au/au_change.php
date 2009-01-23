<?php

include('../standard_header.inc.php');

# $_POST form variables
$cn = $_POST['commonname'];
$oldcn = $_POST['oldcn'];
$description = $_POST['description'];
$olddesc = $_POST['olddesc'];

$cn = htmlentities($cn);
$oldcn = htmlentities($oldcn);
$description = htmlentities($description);
$olddesc = htmlentities($olddesc);

#echo "new cn:"; print_r($cn); echo "<br>";
#echo "old cn:"; print_r($oldcn); echo "<br>";
#echo "new desc:"; print_r($description); echo "<br>";
#echo "old desc:"; print_r($olddesc); echo "<br><br>";

$url = 'au_show.php';

echo "
<html>
<head>
	<title>AU Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>";

if ( $oldcn == "" && $cn != "" ){
	echo "CN neu anlegen<br>";
	# hier noch Syntaxcheck
	$entry['cn'] = $cn;
	$result = ldap_mod_add($ds,$auDN,$entry);
	if($result){
		$mesg = "AU Name erfolgreich eingetragen<br><br>";
	}
	else{
		$mesg = "Fehler beim eintragen des AU Namen<br><br>";
	}
}

if ( $oldcn != "" && $cn != "" && $oldcn != $cn ){
	echo "CN aendern<br>";
	# hier noch Syntaxcheck
	$entry['cn'] = $cn;
	$result = ldap_mod_replace($ds,$auDN,$entry);
	if($result){
		$mesg = "AU Name erfolgreich geaendert<br><br>";
	}
	else{
		$mesg = "Fehler beim aendern des AU Namen<br><br>";
	}
}

if ( $oldcn != "" && $cn == "" ){
	echo "CN loeschen<br>";
	# hier noch Syntaxcheck
	$entry['cn'] = $oldcn;
	$result = ldap_mod_del($ds,$auDN,$entry);
	if($result){
		$mesg = "AU Name erfolgreich geloescht<br><br>";
	}
	else{
		$mesg = "Fehler beim loeschen des AU Namen<br><br>";
	}
}

if ( $olddesc == "" && $description != "" ){
	echo "DESCR neu anlegen<br>";
	# hier noch Syntaxcheck
	$entry2['description'] = $description;
	$result = ldap_mod_add($ds,$auDN,$entry2);
	if($result){
		$mesg = "AU Beschreibung erfolgreich eingetragen<br><br>";
	}
	else{
		$mesg = "Fehler beim eintragen der AU Beschreibung<br><br>";
	}
}

if ( $olddesc != "" && $description != "" && $olddesc != $description ){
	echo "DESCR aendern<br>";
	# hier noch Syntaxcheck
	$entry2['description'] = $description;
	$result = ldap_mod_replace($ds,$auDN,$entry2);
	if($result){
		$mesg = "AU Beschreibung erfolgreich geandert<br><br>";
	}
	else{
		$mesg = "Fehler beim aendern der AU Beschreibung<br><br>";
	}
}

if ( $olddesc != "" && $description == "" ){
	echo "DESCR loeschen<br>";
	# hier noch Syntaxcheck
	$entry2['description'] = $olddesc;
	$result = ldap_mod_del($ds,$auDN,$entry2);
	if($result){
		$mesg = "AU Beschreibung erfolgreich geloescht<br><br>";
	}
	else{
		$mesg = "Fehler beim loeschen der AU Beschreibung<br><br>";
	}
}

else{
	$mesg = "keine Aenderung<br>";
}

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
	Falls nicht, klicken Sie hier <a href='au_show.php' style='publink'>back</a>";
redirect(2, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body></html>";

?>