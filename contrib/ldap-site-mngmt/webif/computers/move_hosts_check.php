<?php
include('../standard_header.inc.php');

$hostsmove = $_POST['hostsmove'];
$automove = $_POST['automove'];

$confirm = $_POST['confirm'];
#$hostsmove = htmlentities($hostsmove);
#$automove = htmlentities($automove);

#echo "hostsmove:"; print_r($hostsmove); echo "<br>";
#echo "automove:"; print_r($automove); echo "<br>";

$dhcpchange = 0;
$seconds = 2000;
$url = "hostoverview.php";
  
echo "
<html>
<head>
	<title>AU Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>
<form action='move_hosts.php' method='post'>";

if ( !$automove ) {
	$seconds = 2;
	$mesg .= "Sie haben keine Ziel-AU gew&auml;hlt!<br>";
}
if ( !$hostsmove ) {
	$seconds = 2;
	$mesg .= "Sie haben keine Clients zum verschieben gew&auml;hlt!<br>";
}
elseif ( $automove && $hostsmove ){

	$exp_automove = explode("_",$automove);
	$target_audn = $exp_automove[0];
	$target_zone = $exp_automove[1];
	$target_ou = ldap_explode_dn($target_audn, 1);
	#echo "$target_audn<br>";
	#echo "$target_zone<br>";
	$target_fipbs = get_freeipblocks_au($target_audn);
	$ip_select = array();
	foreach ($target_fipbs as $fipb) {
		$fipbexp = explode('_',$fipb);
		if ( $fipbexp[0] == $fipbexp[1] ){
			$ip_select [] = $fipbexp[0];
		}else{
			$ip = ip2long($fipbexp[0]);
			$ipmax = ip2long($fipbexp[1]);
			while ($ip <= $ipmax) {
				$ip_select [] = long2ip($ip);
				$ip++;
			}
		}
	}
	natsort($ip_select);
	#print_r($ip_select);
	
	$mesg .= "<br>Clients nach AU <b>$target_ou[0]</b> verschieben:<br><br>";
	
	foreach ($hostsmove as $hostname){
		
		$selfhost = "HostName=$hostname,cn=computers,$auDN"; 
		$found_hostdn = return_zone_hostdn($target_zone,$hostname);
		#echo "$found_hostdn<br>";
		if (!$found_hostdn || $found_hostdn == $selfhost) {
		
			
			#echo "$selfhost<br>";
			#echo "$found_hostdn<br>";
			$attributes = array("hwaddress","description","geolocation","geoattribut","dhcphlpcont",
				"dhcpoptfixed-address","hlprbservice","dhcpoptnext-server","dhcpoptfilename");
			$host_data = get_node_data($selfhost,$attributes);
			#print_r($host_data); echo "<br><br>";
			
			$newhost = array();
			$newhost['objectclass'][] = "top";
			$newhost['objectclass'][] = "Host";
			$newhost['objectclass'][] = "dhcpHost";
			$newhost['objectclass'][] = "dhcpOptions";
			$newhost['hostname'] = $hostname;
			$newhost['domainname'] = $target_zone;
			$standard_atts = array("hwaddress","description","geolocation","geoattribut");
			foreach ($standard_atts as $st_att) {
				if ($host_data[$st_att]) {
					$newhost[$st_att] = $host_data[$st_att];
				}
			}
			if ($host_data['dhcphlpcont']) {
				$dhcpchange = 1;
				$newhost['dhcphlpcont'] = $host_data['dhcphlpcont'];
				if ($host_data['hlprbservice']) {
					$target_rbs_offers = get_rbsoffers_other($target_audn);
					#print_r($target_rbs_offers); echo "<br><br>";
					if ( in_array($host_data['hlprbservice'],$target_rbs_offers) ) {
						$newhost['hlprbservice'] = $host_data['hlprbservice'];
						$newhost['dhcpoptnext-server'] = $host_data['dhcpoptnext-server'];
						$newhost['dhcpoptfilename'] = $host_data['dhcpoptfilename'];
					}
				}
			}
			
			$mesg .= "Client <b>$hostname</b> wird mit folgenden Daten verschoben:<br>
				<table cellpadding='0' cellspacing='0' border='0' width= 40%>";
			foreach (array_keys($newhost) as $att) {
				if ($att == "objectclass") {
				#	$mesg .= "<tr height='15'><td>$att: </td><td>&nbsp;&nbsp;</td><td><b>";
				#	foreach ($newhost[$att] as $oc) {
				#		$mesg .= "$oc ";
				#	}
				#	$mesg .= "</b></td></tr>";
				}else{
					$mesg .= "<tr height='15'><td>$att: </td><td>&nbsp;&nbsp;</td><td><b>$newhost[$att]</b></td></tr>";
				}
			}
			$mesg .= "</table><br>";
			
			$newhostdn = "HostName=$hostname,cn=computers,$target_audn";
			#$mesg .= "$newhostdn<br>";
			#$mesg .= "$selfhost<br>";
			
			
			
		}else{
			#echo "$found_hostdn<br>";
			$mesg .= "<br>Name <b>$hostname</b> in DNS Zone <b>$target_zone</b> der Ziel-AU <b>$target_ou[0]</b> bereits vergeben!<br><br>
						<b>$hostname</b> konnte <b>nicht</b> verschoben werden (Sie m&uuml;ssen den Rechner zun&auml;chst umbenennen).<br>";
		}
	}
}

if ( $dhcpchange ){
#	update_dhcpmtime(array($target_audn));
}


$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>