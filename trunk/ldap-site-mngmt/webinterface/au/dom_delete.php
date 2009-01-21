<?php

include('../standard_header.inc.php');

# $_POST form variables
$delmodus = $_POST['delmodus'];
$oldchilddomain = $_POST['oldchilddomain'];
$childDN = $_POST['childdn'];
$submenu = $_POST['submenu'];

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

$mesg = delete_childau_domain($oldchilddomain,$childDN,$delmodus);

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
	Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect(2, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body></html>";

?>