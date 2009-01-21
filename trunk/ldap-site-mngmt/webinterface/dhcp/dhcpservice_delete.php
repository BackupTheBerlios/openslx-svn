<?php
include('../standard_header.inc.php');

$dhcpDN = $_POST['dn'];
$dhcpcn = $_POST['name'];

$seconds = 100;
$url = "dhcpservice.php?mnr=1";

echo "
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $dhcpDN != ""){	
	if ( dive_into_tree_del($dhcpDN,"") ){
		cleanup_del_dhcpservice($dhcpDN);
		$mesg = "DHCP Service <b>".$dhcpcn."</b> erfolgreich gel&ouml;scht!<br><br>";
	}
	else{
		$mesg = "Fehler beim l&ouml;schen des DHCP Services <b>".$dhcpcn."</b> !<br><br>";
	}
}


$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>