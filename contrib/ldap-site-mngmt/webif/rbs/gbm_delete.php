<?php
include('../standard_header.inc.php');

$gbmDN = $_POST['dn'];
$gbmcn = $_POST['name'];

$seconds = 1;
$url = "gbm_overview.php?";

echo " 
<html> 
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $gbmDN != ""){
	
	clean_up_del_gbm($gbmDN);
	if ( dive_into_tree_del($gbmDN,"") ){
		clean_up_del_gbm($gbmDN);
		$mesg = "Generisches Bootmen&uuml; <b>".$gbmcn."</b> erfolgreich gel&ouml;scht!<br><br>";
	}
	else{
		$mesg = "Fehler beim l&ouml;schen des Generischen Bootmen&uuml;s <b>".$gbmcn."</b> !<br><br>";
	}

}


$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>