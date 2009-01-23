<?php

include('../standard_header.inc.php');

# $_POST form variables
$childou = $_POST['childou'];
$childcn = $_POST['childcn'];
$childdesc = $_POST['childdesc'];
$childdomain = strtolower($_POST['childdomain']);
$mainadmin = $_POST['adduser'];
$hosts = $_POST['addhost'];

$childou = htmlentities($childou);
$childcn = htmlentities($childcn);
$childdesc = htmlentities($childdesc);
$childdomainfull = htmlentities($childdomain).".".$domsuffix;

/*
echo "AU dn:"; print_r($auDN); echo "<br>";
echo "ou:"; print_r($childou); echo "<br>";
echo "cn:"; print_r($childcn); echo "<br>";
echo "desc:"; print_r($childdesc); echo "<br>";
echo "domain:"; print_r($childdomainfull); echo "<br>";
echo "mainadmin:"; print_r($mainadmin); echo "<br><br>";
echo "hosts:"; print_r($hosts); echo "<br><br>";
*/

$seconds = 2;
# $url = 'new_child.php?ou='.$childou.'&cn='.$get_childcn.'&desc='.$get_childdesc.'&childdomain='.$childdomain;

echo "
	<html>
	<head>
		<title>AU Management</title>
		<link rel='stylesheet' href='../styles.css' type='text/css'>
	</head>
	<body>
	<table border='0' cellpadding='30' cellspacing='0'>
	<tr><td>";

if ( $childou != "" && $mainadmin != none && $mainadmin != "") {
	
	# Formulareingaben anpassen
	$expou = explode(" ",$childou);
	foreach ($expou as $word) {$expuc[] = ucfirst($word);}
	$childou = implode(" ",$expuc);
	$childou = preg_replace ( '/\s+([0-9A-Z])/', '$1', $childou);
	
	# AU Objekt anlegen
	# Test auf gleichnamige Geschwister-AUs
	#$sisters = get_childau($auDN,array("ou"));
	# Test alle AUs im LDAP (jede AU hat eindeutigen Namen)
	$sisters = get_all_aus(array("ou"));
	$sister = 0;
	foreach ($sisters as $item) {
		if ( strtolower($item['ou']) == strtolower($childou) ) {
			$mesg = "Es existiert bereits eine AU mit dem eingegebenen 'ou' Namen!<br>
				Bitte geben Sie einen anderen 'ou' Namen ein.<br><br>";
			$get_childcn = str_replace ( " ", "_", $childcn );
			$get_childdesc = str_replace ( " ", "_", $childdesc );
			$url = "new_child.php?ou=Hier_andere_OU_eingeben&cn=".$get_childcn."&desc=".$get_childdesc."&childdomain=".$childdomain;
			$sister = 1;
			break;
		}
	}
	if ($sister == 0) {
		
		$childDN = "ou=".$childou.",".$auDN;
		if (new_childau($childDN,$childou,$childcn,$childdesc,$mainadmin,$childdomain)) {
			
			# Host Objekete verschieben
			$i = array_search('none',$hosts);
			#print_r($i); echo "<br>";
			if ($i === 0 ) {array_splice($hosts, $i, 1);}
			#print_r($hosts ); echo "<br>";
			
			if (count($hosts) != 0) {
				foreach ($hosts as $host) {
					$exp = explode('_',$host);
					$hostDN = $exp[0];
					$hostname = $exp[1];
					print_r($hostDN); echo "<br>";
					print_r($hostname);  echo "<br><br>";
					# IP Adresse nicht verschieben (IPs werden später delegiert)
					$hoip = get_node_data($hostDN, array("ipaddress"));
					# print_r($hoip); echo "<br>";
					if ($hoip['ipaddress'] != "") {
						delete_ip_host($hostDN,$auDN);
					}
					if (move_subtree($hostDN, "hostname=".$hostname.",cn=computers,".$childDN)) {
						# bestimmte Attribute loeschen ...
						$newhostDN = "hostname=".$hostname.",cn=computers,".$childDN;
						$dhcp = get_node_data($newhostDN, array("dhcphlpcont"));
						# print_r($dhcp); echo "<br>";
						if ($dhcp['dhcphlpcont'] != "") {
							$entrydel ['dhcphlpcont'] = array();
							#$entrydel ['objectclass'] = "dhcpHost";
							# print_r($dhcphlpcont);
							ldap_mod_del($ds, "hostname=".$hostname.",cn=computers,".$childDN, $entrydel);
						}
					}
				}
			}
			
			# Domain anlegen falls erforderlich
			/*if ($childdomain) {
				
				$entry['objectclass'] = "domainRelatedObject";
				$entry['associateddomain'] = $childdomain;
				$result = ldap_mod_add($ds,$audn[$i],$entry);	
				if ($result) {
			if (new_child_domain($childdomain, $childDN, $assocdom, $domDN)) {
				$mesg .= "<br>AU Domain erfolgreich eingetragen<br>";
			}
			else {
				$mesg .= "<br>Fehler beim eintragen der AU Domain<br>";
			}*/
					
			$mesg .= "<br>Untergeordnete AU erfolgreich angelegt<br>";
		}
		else {
			$mesg .= "<br>Fehler beim anlegen der untergeordneten AU<br>";
		}
		
		$url = 'au_childs.php';
	}
}


elseif ( $childou == "") {
	$get_childcn = str_replace ( " ", "_", $childcn );
	$get_childdesc = str_replace ( " ", "_", $childdesc );
	$mesg = "Sie haben den OU der neuen AU nicht angegeben. Dieser ist aber ein notwendiges Attribut.<br>
		Bitte geben Sie ihn an.<br><br>";
	$url = "new_child.php?ou=Hier_OU_eingeben&cn=".$get_childcn."&desc=".$get_childdesc."&childdomain=".$childdomain;
}

elseif ($mainadmin == "none" || $mainadmin == "") {
	$get_childcn = str_replace ( " ", "_", $childcn );
	$get_childdesc = str_replace ( " ", "_", $childdesc );
	$mesg = "Sie haben keinen MainAdmin f&uuml;r die neue AU gew&auml;hlt.<br>
				Bitte w&auml;hlen Sie einen MainAdmin.<br><br>";
	$url = 'new_child.php?ou='.$childou.'&cn='.$get_childcn.'&desc='.$get_childdesc.'&childdomain='.$childdomain;
}


$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
	Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body></html>";

?>