<?php

include('../standard_header.inc.php');

# $_POST form variables
$delmodus = $_POST['delmodus'];
$childDN = $_POST['childdn'];
$childou = $_POST['childou'];
$oldchilddomain = $_POST['oldchilddomain'];
#print_r($childDN); echo "<br>";
#print_r($oldchilddomain); echo "<br>";
#print_r($entrydel); echo "<br>";

$url = 'au_childs.php';

echo "
	<html>
	<head>
		<title>AU Management</title>
		<link rel='stylesheet' href='../styles.css' type='text/css'>
	</head>
	<body>
	<table border='0' cellpadding='30' cellspacing='0'> 
	<tr><td>";

$mesg = delete_childau($childDN,$childou,$delmodus);

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
	Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect(2, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body></html>";

?>