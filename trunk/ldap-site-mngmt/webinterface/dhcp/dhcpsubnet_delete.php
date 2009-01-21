<?php
include('../standard_header.inc.php');

$subnetDN = $_POST['dn'];
$cn = $_POST['name'];
$mnr = $_POST['mnr'];

$seconds = 1;
$url = "dhcpsubnets.php?mnr=".$mnr;

echo "
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $subnetDN != ""){
   if( delete_dhcpsubnet($subnetDN,$cn)){
      $mesg = "Subnet <b>".$cn."</b> erfolgreich gel&ouml;scht!<br><br>";
      update_dhcpmtime();
   }else{
      $mesg = "Fehler beim l&ouml;schen des Subnets <b>".$cn."</b> !<br><br>";
   }
}

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>