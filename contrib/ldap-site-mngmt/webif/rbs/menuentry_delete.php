<?php
include('../standard_header.inc.php');

$meDN = $_POST['dn'];
$mecn = $_POST['name'];

$pxeDN = $_POST['pxedn'];

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

if ( $meDN != ""){
	
	if ( dive_into_tree_del($meDN,"") ){
		cleanup_menupositions($pxeDN);
		$mesg = "Bootmen&uuml; Eintrag <b>".$mecn."</b> erfolgreich gel&ouml;scht!<br><br>";
	}
	else{
		$mesg = "Fehler beim l&ouml;schen des Bootmen&uuml; Eintrags <b>".$mecn."</b> !<br><br>";
	}

}


$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>