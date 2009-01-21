<?php

include('../standard_header.inc.php');

$childcn = $_POST['childcn'];
$oldchildcn = $_POST['oldchildcn'];
$childou = $_POST['childou'];
$oldchildou = $_POST['oldchildou'];
$childdomain = $_POST['childdomain'];
$oldchilddomain = $_POST['oldchilddomain'];
$childDN = $_POST['childdn'];
$submenu = $_POST['submenu'];

$childcn = htmlentities($childcn);
$oldchildcn = htmlentities($oldchildcn);
$childou = htmlentities($childou);
$oldchildou = htmlentities($oldchildou);
$childdomainfull = htmlentities($childdomain).".".$domsuffix ;
$oldchilddomainfull = htmlentities($oldchilddomain).".".$domsuffix;

/* 
echo "new ou:"; print_r($childou); echo "<br>";
echo "old ou:"; print_r($oldchildou); echo "<br>";
echo "new cn:"; print_r($childcn); echo "<br>";
echo "old cn:"; print_r($oldchildcn); echo "<br>";
echo "new domain:"; print_r($childdomain); echo "<br>";
echo "old domain:"; print_r($oldchilddomain); echo "<br><br>";
echo "child DN:"; print_r($childDN); echo "<br>";
echo "new child DN:"; print_r($newchildDN); echo "<br>";
echo "submenuNR:"; print_r($submenu); echo "<br><br>";
*/

$seconds = 2;
$url = 'child_au.php?dn='.$childDN.'&sbmnr='.$submenu;

echo "
	<html>
	<head>
		<title>AU Management</title>
		<link rel='stylesheet' href='../styles.css' type='text/css'>
	</head>
	<body>
	<table border='0' cellpadding='30' cellspacing='0'>
	<tr><td>";

#######################################
# CN
 
if ($oldchildcn == $childcn) {
	#$mesg = "keine Aenderung<br>";
}

if ($oldchildcn == "" && $childcn != "") {
	echo "CN neu anlegen<br>";
	# hier noch Syntaxcheck
	$entry['cn'] = $childcn;
	$result = ldap_mod_add($ds,$childDN,$entry);
	if ($result) {
		$mesg = "AU Name erfolgreich eingetragen<br><br>";
	}
	else {
		$mesg = "Fehler beim eintragen des AU Namen<br><br>";
	}
}

if ($oldchildcn != "" && $childcn != "" && $oldchildcn != $childcn) {
	echo "CN aendern<br>";
	# hier noch Syntaxcheck
	$entry['cn'] = $childcn;
	$result = ldap_mod_replace($ds,$childDN,$entry);
	if ($result) {
		$mesg = "AU Name erfolgreich geaendert<br><br>";
	}
	else {
		$mesg = "Fehler beim aendern des AU Namen<br><br>";
	}
}

if ($oldchildcn != "" && $childcn == "") {
	echo "CN loeschen<br>";
	# hier noch Syntaxcheck
	$entry['cn'] = $oldchildcn;
	$result = ldap_mod_del($ds,$childDN,$entry);
	if ($result) {
		$mesg = "AU Name erfolgreich geloescht<br><br>";
	}
	else {
		$mesg = "Fehler beim loeschen des AU Namen<br><br>";
	}
}

#######################################
# OU

if ($oldchildou == $childou) {
	#$mesg = "keine Aenderung<br>";
}

if ($oldchildou != "" && $childou != "" && $oldchildou != $childou) {
	echo "OU aendern<br>";
	# hier noch Syntaxcheck
	# Formulareingaben anpassen
	$expou = explode(" ",$childou);
	foreach ($expou as $word) {$expuc[] = ucfirst($word);}
	$childou = implode(" ",$expuc);
	$childou = preg_replace ( '/\s+([0-9A-Z])/', '$1', $childou);
	
	$newchildDN = "ou=".$childou.",".$auDN;
	modify_au_dn($childDN, $newchildDN);
	
	$url = 'au_childs.php';
}

if ($oldchildou != "" && $childou == "") {
	echo "OU loeschen<br>";
	echo "Sie sind dabei einen Teil des DN zu loeschen.<br>
		Dies geht nur, wenn Sie den gesamten Eintrag loeschen. <br>
		Verwenden Sie dazu das Formular unten";
}

########################################
# DOMAIN
if ($oldchilddomain == $domprefix && ($childdomain == "" || $childdomain == $domprefix))	{
	#$mesg = "keine Aenderung<br>";
}
if ($oldchilddomain == $childdomain) {
	#$mesg = "keine Aenderung<br>";
}


if ($oldchilddomain != "" && $childdomain != "" && $oldchilddomain != $childdomain && $childdomain != $domprefix) {
	echo "Domain aendern<br>";
	# hier noch Syntaxcheck
	if (change_child_domain($childdomain, $oldchilddomain, $childDN, $assocdom, $domDN, $domprefix)) {
		$mesg = "Domain erfolgreich geandert<br><br>";
	}
	else {
		$mesg = "Fehler beim aendern der Domain<br><br>";
	}
}


if ($oldchilddomain != "" && $oldchilddomain != $domprefix && ($childdomain == "" || $childdomain == $domprefix)) {
	echo "Domain loeschen bzw. integrieren<br><br>";
	$delmodus = "integrate";
	delete_child_domain($oldchilddomain,$assocdom,$childDN, $domDN, $delmodus);
	$seconds = 5;
}


$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
	Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body></html>";

?>