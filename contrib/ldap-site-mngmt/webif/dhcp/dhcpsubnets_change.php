<?php
include('../standard_header.inc.php');

$syntax = new Syntaxcheck;

$dhcpservice = $_POST['dhcpsrv'];
$olddhcpservice = $_POST['olddhcpsrv'];

$subnetDN = $_POST['subnetdn'];
$subnetaudn = get_audn_of_objectdn($subnetDN);

$dhcpchange = 0;
$seconds = 200;
$url = "dhcpsubnets.php?mnr=0";
 
echo "
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>";

#####################################
# DHCP Dienstzuordnung ändern
print_r($olddhcpservice);
echo "<br><br>";
print_r($dhcpservice);
echo "<br><br>";
print_r($subnetDN);
/*for ( $i=0; $i < count($subnetDN); $i++) {

if ( $dhcpservice[$i] != $olddhcpservice[$i] ){
   
   if ( $olddhcpservice[$i] == "no" ){
   	$entrysv ['dhcphlpcont'] = $DHCP_SERVICE;
   	if(ldap_mod_add($ds,$subnetDN[$i],$entrysv)){
   		$mesg = "Subnetz erfolgreich im DHCP Dienst eingetragen<br><br>";
   		$dhcpchange = 1;
   	}else{
   		$mesg = "Fehler beim eintragen des Subnetzes im DHCP Dienst.<br><br>";
   	}
   }
   elseif( $olddhcpservice[$i] == "yes" ){
   	$entrysv ['dhcphlpcont'] = array();
   	if(ldap_mod_del($ds,$subnetDN[$i],$entrysv)){
   		$mesg = "Subnetz erfolgreich aus DHCP Dienst ausgetragen<br><br>";
   		$dhcpchange = 1;
   	}
   	else{
   		$mesg = "Fehler beim austragen des Subnetzes aus dem DHCP Dienst!<br><br>";
   	}
   }
}

}*/


###########
if ($dhcpchange){
	update_dhcpmtime($subnetaudn);
}

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>