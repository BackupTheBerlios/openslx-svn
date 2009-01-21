<?php
include('../standard_header.inc.php');

$hostname = $_POST['hostname'];
$hostdesc = $_POST['hostdesc'];
$mac = $_POST['mac'];
$ip = $_POST['ip'];
$dhcp = $_POST['dhcpcont'];

$hostname = htmlentities($hostname);
$hostdesc = htmlentities($hostdesc);
$mac = htmlentities($mac);
$mac = strtolower($mac);
$ip = htmlentities($ip);

/* 
echo "AU dn:"; print_r($auDN); echo "<br>";
echo "hostname:"; print_r($hostname); echo "<br>";
echo "hostdesc:"; print_r($hostdesc); echo "<br>";
echo "mac:"; print_r($mac); echo "<br>";
echo "ip:"; print_r($ip); echo "<br><br>";
*/

$attribs = $_POST['attribs'];
if (count($attribs) != 0){
	foreach (array_keys($attribs) as $key){
		$atts[$key] = htmlentities($attribs[$key]);
	}
}

$seconds = 2;
 
echo "
<html>
<head>
	<title>AU Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $hostname != ""){
	
	# Formulareingaben anpassen
	$exphn = explode(" ",$hostname);
	foreach ($exphn as $word){$expuc[] = ucfirst($word);}
	$hostname = implode(" ",$expuc);
	$hostname = preg_replace ( '/\s+([0-9A-Z])/', '$1', $hostname);
	
	# Host Objekt anlegen
	$brothers = get_hosts($auDN,array("hostname"));
	$brother = 0;
	foreach ($brothers as $item){
		if( $item['hostname'] == $hostname ){
			$mesg = "Es existiert bereits ein Rechner mit dem eingegebenen HOSTNAME!<br>
						Bitte geben Sie einen anderen HOSTNAME ein.<br><br>";
			$get_hostdesc = str_replace ( " ", "_", $hostdesc );
			$get_mac = str_replace ( " ", "_", $mac );
			$get_ip = str_replace ( " ", "_", $ip );
			$url = "new_host.php?hostname=Hier_anderen_HOSTNAME_eingeben&hostdesc=".$get_hostdesc."&mac=".$get_mac."&ip=".$ip;
			$brother = 1;
			break;
		}
	}
	if ($brother == 0){
		$hostDN = "HostName=".$hostname.",cn=computers,".$auDN;
		# print_r($hostDN); echo "<br>";
		
		if (add_host($hostDN,$hostname,$hostdesc,$mac,$ip,$atts,$dhcp)){			
			$mesg .= "<br>Neuer Rechner erfolgreich angelegt<br>";
		}
		else{
			$mesg .= "<br>Fehler beim anlegen des Rechners!<br>";
		}
		
		# DHCP
		
		$url = 'hostoverview.php';
	}
}


elseif ( $hostname == ""){
	
	$get_hostdesc = str_replace ( " ", "_", $hostdesc );
	$get_mac = str_replace ( " ", "_", $mac );
	$get_ip = str_replace ( " ", "_", $ip );
	$mesg = "Sie haben den HOSTNAME des neuen Rechners nicht angegeben. Dieser ist aber ein notwendiges Attribut.<br>
				Bitte geben Sie ihn an.<br><br>";
	$url = "new_host.php?ou=Hier_HOSTNAME_eingeben&hostdesc=".$get_hostdesc."&mac=".$get_mac."&ip=".$ip;
}




$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>