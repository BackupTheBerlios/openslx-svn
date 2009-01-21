<?php
include('../standard_header.inc.php');

$cn = $_POST['cn'];
$dhcpoffer = $_POST['dhcpoffer'];

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
$mcnr = $_POST['mcnr'];

$get_dhcpcn = str_replace ( " ", "_", $cn );
$seconds = 2;
$url = "new_dhcpservice.php?&mnr=1";
 
echo "
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $cn != "" && $cn != "Hier_DHCP_NAME_eintragen" ){

	$dhcpcn = "DHCP_".$cn;

	# Formulareingaben anpassen
	$exp = explode(" ",$dhcpcn);
	foreach ($exp as $word){$expuc[] = ucfirst($word);}
	$dhcpcn = implode(" ",$expuc);
	$dhcpcn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $dhcpcn);
	
	#$dhcpDN = "cn=".$dhcpcn.",".$nodeDN;
	#print_r($dhcpDN); echo "<br><br>";
	
	if (add_dhcpservice ($dhcpcn,$dhcpoffer,$atts)){			
		$mesg .= "<br>DHCP Service erfolgreich angelegt<br>";
		$url = "dhcpservice.php?mnr=1";
	}else{
		$mesg .= "<br>Fehler beim anlegen des DHCP Services!<br>";
	}
}

elseif ( $cn == "" || $cn == "Hier_DHCP_NAME_eintragen" ){

	$mesg = "Sie haben den Namen des neuen DHCP Service nicht angegeben. Dieser ist 
				aber ein notwendiges Attribut.<br>
				Bitte geben Sie ihn an.<br><br>";
	$url = "new_dhcpservice.php?dhcpcn=Hier_DHCP_NAME_eintragen&mnr=1";
}

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>