<?php
include('../standard_header.inc.php');

$syntax = new Syntaxcheck;

$subnet = $_POST['dhcpsubnet'];
$subnetexp = explode("|",$subnet);
$cn = $subnetexp[0];
$netmask = $subnetexp[1];
#print_r($subnet); echo "<br><br>";
#print_r($cn); echo "<br><br>";
#print_r($netmask); echo "<br><br>";

$dhcpservice = $_POST['dhcpservice'];
#$range1 = $_POST['range1'];
#$range2 = $_POST['range2'];
# sonstige Attribute
$attribs = $_POST['attribs'];
if (count($attribs) != 0){
	foreach (array_keys($attribs) as $key){
		$atts[$key] = htmlentities($attribs[$key]);
	}
}
#print_r($atts); echo "<br><br>";

$nodeDN = "cn=dhcp,".$auDN;
$mnr = $_POST['mnr'];
$sbmnr = $_POST['sbmnr'];

$get_dhcpcn = str_replace ( " ", "_", $cn );
$seconds = 2;
$url = "new_dhcpsubnet.php?&mnr=2";
 
echo "
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $cn != "" && $cn != "Hier_Subnetz_eintragen" && $netmask != "" && $netmask != "Hier_Netzmaske_eintragen" ){

	if ( $syntax->check_netip_syntax($cn) && $syntax->check_ip_syntax($netmask) ){
	   
   	if (add_dhcpsubnet ($cn,$dhcpservice,$netmask,$atts)){			
   		$mesg .= "<br>DHCP Subnet erfolgreich angelegt<br>";
   		$url = "dhcpsubnets.php?mnr=".$mnr;
   	}else{
   		$mesg .= "<br>Fehler beim anlegen des DHCP Subnets!<br>";
   	}
	
	}else{
	   $mesg .= "Falsche IP Syntax! Geben Sie eine korrekte IP Adresse als Subnet Name oder Netzmaske ein.";
	   $url = "new_dhcpsubnet.php?subnetcn=Hier_Subnetz_eintragen&netmask=".$netmask."&mnr=".$mnr;
	}
}

elseif ( $cn == "" || $cn == "Hier_Subnetz_eintragen" || $netmask == "" || $netmask == "Hier_Netzmaske_eintragen" ){
   
   if ( $cn == ""){ $cn = "Hier_Subnetz_eintragen";}
   if ( $netmask == ""){ $netmask = "Hier_Netzmaske_eintragen";}
	$mesg = "Sie haben die notwendigen Attribute: Name (IP) und Netzmaske des neuen DHCP Subnets nicht angegeben.<br>
				Bitte geben Sie fehlende ein.<br><br>";
	$url = "new_dhcpsubnet.php?subnetcn=".$cn."&netmask=".$netmask."&mnr=".$mnr;
}

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>