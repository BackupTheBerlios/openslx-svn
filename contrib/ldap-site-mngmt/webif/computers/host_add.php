<?php
include('../standard_header.inc.php');
$syntax = new Syntaxcheck;

$hostname = $_POST['hostname'];
$hostdesc = $_POST['hostdesc'];
$mac = $_POST['mac'];
$ip = $_POST['ip'];
$dhcp = $_POST['dhcpcont'];

#$hostname = htmlentities($hostname);
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

$automatic_back = 1;
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

if ( $hostname != "" ){
	
	# Formulareingaben anpassen (Leerzeichen raus da Teil des DN)
	#$exphn = explode(" ",$hostname);
	#foreach ($exphn as $word){$expuc[] = ucfirst($word);}
	#$hostname = implode(" ",$expuc);
	#$hostname = preg_replace ( '/\s+([0-9a-zA-Z])/', '$1', $hostname);

	$hostname = preg_replace ( '/^([^\.]+)\.(.*)/', '$1', $hostname);
	$hostname = preg_replace ( '/[^0-9a-zA-Z_-]/', '', $hostname);
	$hostname = htmlentities($hostname);

	
	if ( check_host_fqdn($hostname) ) {
		# Host Objekt anlegen
		$hostDN = "HostName=".$hostname.",cn=computers,".$auDN;
		# print_r($hostDN); echo "<br>";
		
		if ( $ip ){
			if ( $syntax->check_ip_syntax($ip) ) { 
				# sonst vorher absturz durch unendlichen zone_check ...
				if ( !check_iprange_zone($ip,$ip,$assocdom,$au_ou) ) {
				#	$ip = "";
		   	   echo "IP Adresse <b>$ip</b> nicht in DNS eingetragen.<br>";
		   	#			Client wird ohne IP Adresse angelegt<br>";
		   	}
		   	# Wenn DHCP Subnet zu IP nicht existiert dann kein Eintrag DHCP
		   	if ( $network = test_ip_dhcpsubnet($ip)){
		   		print "<b>Subnetz $network/24</b> nicht im DHCP eingetragen<br>Client wird nicht in DHCP eingetragen<br><br>";
		   		#$ip = "";
		   		$dhcp = "";
		   	}
		   }else{
		   	echo "IP Adresse $ip nicht korrekt!<br>Client wird ohne IP Adresse eingetragen.<br><br>";
		   	$ip = "";
		   	if ( $dhcp ){
		   		echo "Client wird nicht in DHCP eingetragen.<br><br>";
		   		$dhcp = "";
		   	}
		   }
   	}
		
		if ( add_host($hostDN,$hostname,$hostdesc,$mac,$ip,$atts,$dhcp) ) {
			$mesg .= "<br>Neuer Rechner erfolgreich angelegt<br>";
		}
		else{
			$automatic_back = 0;
			$mesg .= "<br>Fehler beim anlegen des Rechners!<br>";
		}
		
		$url = 'hostoverview.php';
		
	}else{
		$seconds = 4;
		$mesg = "In der Domain <b>$assocdom</b> existiert bereits ein Client mit Namen <b>$hostname</b>!<br><br>
					Bitte w&auml;hlen Sie einen anderen HOSTNAMEN.<br><br>";
		$get_hostdesc = str_replace ( " ", "_", $hostdesc );
		$get_mac = str_replace ( " ", "_", $mac );
		$get_ip = str_replace ( " ", "_", $ip );
		$url = "new_host.php?hostname=Hier_anderen_HOSTNAME_eingeben&hostdesc=".$get_hostdesc."&mac=".$get_mac."&ip=".$ip;
	}
}

else{
	$get_hostdesc = str_replace ( " ", "_", $hostdesc );
	$get_mac = str_replace ( " ", "_", $mac );
	$get_ip = str_replace ( " ", "_", $ip );
	$mesg = "Sie haben den HOSTNAME des neuen Rechners nicht angegeben. Dieser ist aber ein notwendiges Attribut.<br>
			Bitte geben Sie ihn an.<br><br>";
	$url = "new_host.php?ou=Hier_HOSTNAME_eingeben&hostdesc=".$get_hostdesc."&mac=".$get_mac."&ip=".$ip;
}


if ( $automatic_back ) {
	$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>zur&uuml;ck</a>";
	redirect($seconds, $url, $mesg, $addSessionId = TRUE);
}
else {
	$mesg .= "<br><br><a href=$url style='publink'><b>gelesen</b> &nbsp;&nbsp;(<< zur&uuml;ck)</a>";
	echo $mesg;
}

echo "</td></tr></table></body>
</html>";
?>
