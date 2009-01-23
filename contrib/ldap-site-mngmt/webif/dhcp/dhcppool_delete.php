<?php
include('../standard_header.inc.php');

$poolDN = $_POST['dn'];
$cn = $_POST['name'];
$subnetaudn = $_POST['subnetaudn'];
$dhcpsrv = $_POST['dhcpsrv'];
$mnr = $_POST['mnr'];

$seconds = 2;
$url = "dhcppools.php?mnr=".$mnr;

echo "
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $poolDN != ""){
   if( delete_dhcppool($poolDN)){
      $mesg = "Pool <b>".$cn."</b> erfolgreich gel&ouml;scht!<br><br>";
      update_dhcpmtime($subnetaudn);
   }else{
      $mesg = "Fehler beim l&ouml;schen des Pools <b>".$cn."</b> !<br><br>";
   }
}

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>