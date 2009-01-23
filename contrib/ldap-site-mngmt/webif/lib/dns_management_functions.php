<?php

/**  
* dns_management_functions.php - DNS Management Funktions-Bibliothek
* Diese Bibliothek enthält alle Funktionen für die Verwaltung des DNS Dienstes
*
* @param string ldapError
* @param resource ds
* 
* @author Tarik Gasmi
* @copyright Tarik Gasmi
*/  

# Konfiguration laden
require_once("config.inc.php");

$ldapError = null;

###################################################################################################

# wenn DNS Objekte geändert werden DNS modify time der AU aktualisieren, und auch der AUs 
function update_dnsmtime($au_array){

   global $ds, $auDN, $ldapError;
   
   $entry ['dnsmtime'] = time();
   
   
}


function check_iprange_zone($range1,$range2,$zone,$au) {
	
	global $ds, $suffix, $ldapError;
	
	
	if ($zone) {
	
	$dnsentries = array();
	$badips = array();	
	
	$first = ip2long($range1);
	$last = ip2long($range2);
	
	if ($range1 < $range2) {
		echo "DNS Lookup f&uuml;r IP Range <b>$range1 - $range2</b> ...<br>";
	}else{
		echo "DNS Lookup f&uuml;r IP <b>$range1</b> ...<br>";
	}
	for ($i=$first; $i <= $last; $i++) {
		$address = long2ip($i);
		#print $address;
		$dig = `dig @dns2.fun.uni-freiburg.de -x $address`; # +time=3
		$rev_address = implode(".", array_reverse(explode(".",$address)));
		#print " -> $rev_address<br>";
		#print "$dig<br><br>";
		$pattern = '/'.$rev_address.'\.in-addr\.arpa\.\s(\d+)\sIN\sPTR\s(([^\.]+)\.(\S+))\./';
		if (preg_match($pattern,$dig,$match) ){
			#print "DNS: <b>$match[2]</b><br>";
			#print "Hostname: <b>$match[3]</b><br>";
			#print "Zone: <b>$match[4]</b><br>";
			$digfqdn = $match[2];
			$dighost = $match[3];
			$digzone = $match[4];
			if ($digzone != $zone) {
				$badips [$address] = "Vom DNS zur&uuml;ckgelieferte Zone <b>$digzone</b> stimmt nicht &uuml;berein mit <b>$au</b> Zone <b>$zone</b>";
			}else{
				$dnsentries [$address] = $digfqdn;
			}
		}else{
			#print "$pattern not found<br>";
			$badips [$address] = "Kein DNS Eintrag";
		}
	}
	
	if ($badips) {
		echo "Fehlgeschlagen f&uuml;r IP Adressen :<br><br>";
		foreach (array_keys($badips) as $key) {
			echo "$key &nbsp;->&nbsp; $badips[$key]<br>";
		}
		echo "<br>
				Passen Sie zun&auml;chst diese IP Adressen im DNS an die <b>Zone $zone</b> an!<br><br>";
		return 0;
	}else{
		echo "<br>F&uuml;r jede IP Adresse Eintrag in Zone <b>$zone</b> von AU <b>$au</b> gefunden:<br><br>";
		foreach (array_keys($dnsentries) as $key) {
			echo "$key &nbsp;->&nbsp; $dnsentries[$key]<br>";
		}
		return 1;
	}
	
	}else{
		echo "Parameter DNS Zone der AU nicht mitgegeben! AU hat keine DNS Zonen Zuordnung!";
		return 0;
	}
}


# Einzelner DNS Eintrag -> Zone, Hostname
function check_ip_zone($ip,$zone,$hostname,$au) {
	
	global $ds, $suffix, $ldapError;
	
	$dns_check = "";
	
	if ($zone) {
	
	$dig = `dig @dns2.fun.uni-freiburg.de -x $ip`; # +time=3
	$rev_address = implode(".", array_reverse(explode(".",$ip)));
	#print " -> $rev_address<br>";
	#print "$dig<br><br>";
	$pattern = '/'.$rev_address.'\.in-addr\.arpa\.\s(\d+)\sIN\sPTR\s(([^\.]+)\.(\S+))\./';
	if (preg_match($pattern,$dig,$match) ){
		#print "DNS: <b>$match[2]</b><br>";
		#print "Hostname: <b>$match[3]</b><br>";
		#print "Zone: <b>$match[4]</b><br>";
		$digfqdn = $match[2];
		$dighost = $match[3];
		$digzone = $match[4];
		if ($digzone != $zone) {
			#$dns_check = "Vom DNS zur&uuml;ckgelieferte Zone <b>$digzone</b> stimmt nicht &uuml;berein mit <b>$au</b> Zone <b>$zone</b>";
			$dns_check = "DNS: Zone $digzone";
		}elseif ( strtolower($dighost) != strtolower($hostname) ) {
		#}elseif ( strtolower($dighost) != $hostname ) {
		#}elseif ( $dighost != strtolower($hostname) ) {
			#$dns_check = "Hostname <b>$host</b> stimmt nicht mit DNS Hostname <b>$dighost</b> &uuml;berein";
			$dns_check = "DNS: $dighost";
		}else{
			$dnsentry = $digfqdn;
		}
	}else{
		#print "$pattern not found<br>";
		$dns_check = "DNS: Kein Eintrag";
	}
	
	return $dns_check;
	
	
	}else{
		#echo "Parameter DNS Zone der AU nicht mitgegeben! AU hat keine DNS Zonen Zuordnung!";
		return "";
	}
}


?>