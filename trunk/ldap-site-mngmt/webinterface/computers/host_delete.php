<?php
include('../standard_header.inc.php');

$hostDN = $_POST['dn'];
$hostname = $_POST['name'];
$hostDN = htmlentities($hostDN);
$hostname = htmlentities($hostname);

/* 
echo "AU dn:"; print_r($auDN); echo "<br>";
echo "hostdn:"; print_r($hostDN); echo "<br>";
echo "hostname:"; print_r($hostname); echo "<br>";
*/

$seconds = 1;
$url = 'hostoverview.php';
 
echo "
<html>
<head>
	<title>AU Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $hostDN != ""){
	
	if ( delete_host($hostDN) ){
		$mesg = "Rechner <b>".$hostname."</b> erfolgreich gel&ouml;scht!<br><br>";
	}
	else{
		$mesg = "Fehler beim l&ouml;schen von Rechner <b>".$hostname."</b> !<br><br>";
	}

}



$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>