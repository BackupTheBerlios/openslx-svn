<?php
include('../standard_header.inc.php');

$pxeDN = $_POST['dn'];
$oldpxecn = $_POST['name'];

$mnr = $_POST['mnr'];
$sbmnr = $_POST['sbmnr'];
$mcnr = $_POST['mcnr'];

$seconds = 1;
$url = $_POST['successurl'];

echo " 
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $pxeDN != ""){
	
	if ( dive_into_tree_del($pxeDN,"") ){
		$mesg = "PXE Boot Men&uuml; <b>".$pxecn."</b> erfolgreich gel&ouml;scht!<br><br>";
	}
	else{
		$mesg = "Fehler beim l&ouml;schen des PXE Boot Men&uuml;s <b>".$pxecn."</b> !<br><br>";
	}

}


$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>