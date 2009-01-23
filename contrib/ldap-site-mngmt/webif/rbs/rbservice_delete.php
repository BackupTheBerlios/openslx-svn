<?php
include('../standard_header.inc.php');

$rbsDN = $_POST['dn'];
$rbscn = $_POST['name'];

$seconds = 100;
$url = 'rbs.php';

echo " 
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $rbsDN != ""){
	
	if ( dive_into_tree_del($rbsDN,"") ){
		clean_up_del_rbs($rbsDN);
		$mesg = "Remote Boot Service <b>".$rbscn."</b> erfolgreich gel&ouml;scht!<br><br>";
	}
	else{
		$mesg = "Fehler beim l&ouml;schen des Remote Boot Services <b>".$rbscn."</b> !<br><br>";
	}

}




$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>