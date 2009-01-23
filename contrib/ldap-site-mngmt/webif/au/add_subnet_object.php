<?php
include('../standard_header.inc.php');
$syntax = new Syntaxcheck;

$cn = $_POST['subnet'];
$netmask = $_POST['netmask'];
$childauDN = $_POST['childaudn'];
#print_r($cn); echo "<br><br>";
#print_r($netmask); echo "<br><br>";
#print_r($childauDN); echo "<br><br>";

# sonstige Attribute
$attribs = $_POST['attribs'];
if (count($attribs) != 0){
	foreach (array_keys($attribs) as $key){
		$atts[$key] = htmlentities($attribs[$key]);
	}
}
#print_r($atts); echo "<br><br>";

$seconds = 20;
$url = $_POST['url'];
 
echo "
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $cn != "" && $netmask != "" ){
	if ( $syntax->check_netip_syntax($cn) && $syntax->check_ip_syntax($netmask) ){
	   
   	if (add_dhcpsubnet ($cn,$DHCP_SERVICE,$netmask,$atts,$childauDN)){			
   		#$mesg .= "<br>DHCP Subnet erfolgreich angelegt<br>";
   	}else{
   		$mesg .= "<br>Fehler beim anlegen des DHCP Subnets!<br>";
   	}
   	
	}else{
	   $mesg .= "Falsche IP Syntax! Geben Sie eine korrekte IP Adresse als Subnet Name oder Netzmaske ein.";
	   $url = "new_dhcpsubnet.php?subnetcn=Hier_Subnetz_eintragen&netmask=".$netmask."&mnr=".$mnr;
	}
}else{
	$mesg .= "Subnet oder Netmask nicht angegeben!<br>(Beides notwendige Attribute)<br>";
}


$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "
</td></tr></table></body>
</html>";
?>