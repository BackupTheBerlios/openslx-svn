<?php
include('../standard_header.inc.php');

$dhcp = $_POST['dhcp'];
$olddhcp = $_POST['olddhcp'];
$mnr = $_POST['mnr'];

$dhcpchange = 0;
$seconds = 2;
$url = $_POST['backurl'];
#$url = "dhcp_classes.php?mnr=".$mnr;
 
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

foreach (array_keys($olddhcp) as $cldn){ 
	#echo $olddhcp[$cldn];echo "<br><br>";
	#echo $dhcp[$cldn];echo "<br><br>";
	#echo $cldn;echo "<br><br>";
	
	$cldnexp = ldap_explode_dn($cldn, 1);
	$classcn = $cldnexp[0];
	if ($olddhcp[$cldn] != $dhcp[$cldn]) {
		if ($olddhcp[$cldn] == "") {
			# add
			$addentry ['dhcphlpcont'] = $dhcp[$cldn];
			if ( $result = ldap_mod_add($ds,$cldn,$addentry) ) {
				echo "DHCP Class <b>$classcn</b> erfolgreich im DHCP Dienst <b>aktiviert</b><br>";
				$dhcpchange = 1;
			}else{
				echo "<b>Fehler</b> beim aktivieren der DHCP Class <b>$classcn</b><br>";
			}
		}else{
			#remove
			$delentry ['dhcphlpcont'] = array();
			if ( $result = ldap_mod_del($ds,$cldn,$delentry) ) {
				echo "DHCP Class <b>$classcn</b> erfolgreich im DHCP Dienst <b>deaktiviert</b><br>";
				$dhcpchange = 1;
			}else{
				echo "<b>Fehler</b> beim deaktivieren der DHCP Class <b>$classcn</b><br>";
			}
		}
	}
}

###########
if ($dhcpchange){
	update_dhcpmtime($rootAU);
}

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>