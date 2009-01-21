<?php
include('../standard_header.inc.php');

$mcDN = $_POST['dn'];
$mccn = $_POST['name'];

$seconds = 1;
$url = 'machineconfig_default.php';

echo " 
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $mcDN != ""){
	
	if ( dive_into_tree_del($mcDN,"") ){
		$mesg = "Machine Config <b>".$mccn."</b> erfolgreich gel&ouml;scht!<br><br>";
	}
	else{
		$mesg = "Fehler beim l&ouml;schen der Machine Config <b>".$mccn."</b> !<br><br>";
	}

}




$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>