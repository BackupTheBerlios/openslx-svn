<?php

include('../standard_header.inc.php');
$syntax = new Syntaxcheck;

$audn = $_POST['audn'];
$auzone = $_POST['auzone'];
$oldauzone = $_POST['oldauzone'];

$seconds = 2;
$url = 'dns_au_zones.php?';

echo "
	<html>
	<head>
		<title>DNS Management</title>
		<link rel='stylesheet' href='../styles.css' type='text/css'>
	</head>
	<body>
	<table border='0' cellpadding='30' cellspacing='0'>
	<tr><td>";

#######################################
# AU - Zone Zuordnung

for ($i=0; $i < count($auzone); $i++) {


$auzone[$i] = strtolower($auzone[$i]);
$oldauzone[$i] = strtolower($oldauzone[$i]);

#echo "<br>$i| new: $auzone[$i] | ";
#echo "old: $oldauzone[$i] | dn: $audn[$i]<br>";
$change_zone = 1;
$expou = ldap_explode_dn($audn[$i],1);

if ($auzone[$i] != $oldauzone[$i]) {
	
	if (!$oldauzone[$i]){
		# Zone eintragen
		if ( $syntax->is_hostname($auzone[$i]) ) {
			# if AU IP Ranges ... DNS Lookup Test
			$mipbs = get_maxipblocks_au($audn[$i]);
			if ($mipbs[0] != "") {
				foreach ($mipbs as $mipb) {
					$exp = explode("_",$mipb);
					if (!check_iprange_zone($exp[0],$exp[1],$auzone[$i],$expou[0])){
						$change_zone = 0;
					}
				} 
			}
			
			if ( in_array($auzone[$i], $oldauzone) ) {
				# Zone existiert bereits
				$mesg .= "<br>Zone $auzone[$i] existiert bereits.<br>";
				# eigene Host auf Eindeutigkeit testen in neuer Zone ...
				$hosts = get_hosts($audn[$i],array("dn","hostname"),"");
				if ( $matches = check_hostarray_fqdn2($hosts,$auzone[$i]) ) {
					$change_zone = 0;
					$mesg .= "Folgende Hostname sind in der neuen Zone bereits vergeben:<br>";
					foreach ($matches as $match) {
						$mesg .= "<b>$match</b><br>";
						# oder hosts auf neue standardnamen setzen ...
					}
					$mesg .= "Zone kann nicht ge&auml;ndert werden<br>
									Geben Sie diesen Hosts zun&auml;chst andere Namen, die nicht in
									$auzone[$i] vergeben sind<br>";
				}else{
					$mesg .= "Keine &Uuml;berschneidungen mit Hostnamen in der neuen Zone $auzone[$i]<br>";
				}					
			}
			if ($change_zone) {
				$entry['objectclass'] = "domainRelatedObject";
				$entry['associateddomain'] = $auzone[$i];
				$mesg .= "Zone eintragen<br>";
				$result = ldap_mod_add($ds,$audn[$i],$entry);	
				if ($result) {
					$mesg .= "<b>$auzone[$i]</b> erfolgreich in $audn[$i] eingetragen<br>";
				}else {
					$mesg .= "Fehler beim eintragen von <b>$auzone[$i]</b> in $audn[$i]<br>";
				}
			}
		}else{
			print $syntax->ERROR;
		}
	}
	elseif (!$auzone[$i]) {
		# Zone löschen
		#$entry['objectclass'] = "domainRelatedObject";
		#$entry['associateddomain'] = $oldauzone[$i];
		#$result = ldap_mod_del($ds,$audn[$i],$entry);	
		#if ($result) {
		#	$mesg .= "<b>$oldauzone[$i]</b> erfolgreich in $audn[$i] gel&ouml;scht<br>";
		#}else {
		#	$mesg .= "Fehler beim l&ouml;schen von <b>$oldauzone[$i]</b> in $audn[$i]<br>";
		#}
		$mesg .= "<b>$oldauzone[$i]</b> kann nicht gel&ouml;scht werden<br>
					Administrative Einheiten (AUs) m&uuml;ssen einer DNS Zone zugeordnet sein!<br>";
	}
	else{
		# Zone ändern
		if ( $syntax->is_hostname($auzone[$i]) ) {
			
			# if AU IP Ranges ... DNS Lookup Test
			$mipbs = get_maxipblocks_au($audn[$i]);
			#echo "MIPBS: <br>";print_r($mipbs);
			if ($mipbs[0] != "") {
				foreach ($mipbs as $mipb) {
					$exp = explode("_",$mipb);
					if (!check_iprange_zone($exp[0],$exp[1],$auzone[$i],$expou[0])){
						$change_zone = 0;
					}
				} 
			}
			
			if ( in_array($auzone[$i], $oldauzone) ) {
				# Zone existiert bereits
				$mesg .= "<br>Zone $auzone[$i] existiert bereits.<br>";
				# eigene Host auf Eindeutigkeit testen in neuer Zone ...
				$hosts = get_hosts($audn[$i],array("dn","hostname"),"");
				if ( $matches = check_hostarray_fqdn2($hosts,$auzone[$i]) ) {
					$change_zone = 0;
					$mesg .= "Folgende Hostnamen sind in der neuen Zone bereits vergeben:<br>";
					#$j=1;
					foreach ($matches as $match) {
						$mesg .= "<b>$match</b><br>";
						# hosts löschen?
						# oder hosts auf neue standardnamen setzen ...
						#$expou = ldap_explode_dn($audn[$i],1);
						#$c = 0;
						#while ( !$c ) {
						# 	$newhostname = "$expou[0]_$j";
						# 	if (check_host_fqdn2($newhostname,$auzone[$i]) && check_host_fqdn2($newhostname,$oldauzone[$i])){
						# 		$c = 1;
						#	}
						#	$j++;				
						#}
						#$mesg .= "Hostname -> $newhostname<br>";
						#$hostDN = "$match,cn=computers,$audn[$i]s";
						#$newhostDN = "$newhostname,cn=computers,$audn[$i]";
						#modify_host_dn($hostDN, $newhostDN);
						#$j++;
					}
					$mesg .= "Zone kann nicht ge&auml;ndert werden<br>
									Geben Sie diesen Hosts zun&auml;chst andere Namen, die nicht in
									$auzone[$i] vergeben sind<br>";
				}else{
					$mesg .= "Keine &Uuml;berschneidungen mit Hostnamen in der neuen Zone $auzone[$i]<br>";
				}				
			}
			if ($change_zone) {
				$entry['associateddomain'] = $auzone[$i];
				$result = ldap_mod_replace($ds,$audn[$i],$entry);
				$mesg .= "Zone &auml;ndern<br>";	
				if ($result) {
					$mesg .= "&Auml;nderung von <b>$oldauzone[$i]</b> nach <b>$auzone[$i]</b> erfolgreich in $audn[$i] eingetragen<br>";
				}else {
					$mesg .= "Fehler bei &Auml;nderung von <b>$oldauzone[$i]</b> nach <b>$auzone[$i]</b> in $audn[$i]<br>";
				}
			}
		}else{
			print $syntax->ERROR;
		}
	}
}

}



$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
	Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body></html>";

function zone_exists($zonename) {
	
	global $ds, $suffix, $rootAU, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $rootAU, "(&(objectclass=administrativeUnit)(associateddomain=$zonename))", array("dn"), "", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}else{
	}
}

?>