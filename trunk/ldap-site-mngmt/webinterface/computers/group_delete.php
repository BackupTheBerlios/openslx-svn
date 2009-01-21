<?php
include('../standard_header.inc.php');

$groupDN = $_POST['dn'];
$groupcn = $_POST['name'];
$groupDN = htmlentities($groupDN);
$groupcn = htmlentities($groupcn);

/*
echo "AU dn:"; print_r($auDN); echo "<br>";
echo "groupdn:"; print_r($groupDN); echo "<br>";
echo "groupcn:"; print_r($groupcn); echo "<br>";
*/ 

$seconds = 1;
$url = 'groupoverview.php';
 
echo "
<html>
<head>
	<title>AU Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $groupDN != ""){
	
	if ( delete_group($groupDN) ){
		$mesg = "Rechnergruppe <b>".$groupcn."</b> erfolgreich gel&ouml;scht!<br><br>";
	}
	else{
		$mesg = "Fehler beim l&ouml;schen der Rechnergruppe <b>".$groupcn."</b> !<br><br>";
	}

}



$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>