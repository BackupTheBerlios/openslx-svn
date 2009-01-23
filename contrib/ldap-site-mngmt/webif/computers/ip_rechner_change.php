<?php

include('../standard_header.inc.php');

$hostDN = $_POST['hostdn'];
$oldip = $_POST['oldip'];
$newip = $_POST['newip'];
$fixadd = $_POST['fixadd'];
$dhcp = $_POST['dhcp'];
$olddhcp = $_POST['olddhcp'];
$rbs = $_POST['rbs'];
$oldrbs = $_POST['oldrbs'];


$dhcpsrv_dn = $_POST['dhcpsrv_dn'];

$syntax = new Syntaxcheck;
$url = "ip_rechner.php";

$dhcpchange = 0;

echo "
<html>
<head>
	<title>IP Address Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr valign='top'><td width='33%' class='tab_d'>";

#print_r($dhcpsrv_dn); echo "<br><br>";
#print_r($dhcp); echo "<br><br>";
#print_r($olddhcp); echo "<br><br>";
#print_r($newip); echo "<br><br>";
#print_r($oldip); echo "<br><br>";
#print_r($hostDN); echo "<br><br>";

# IP Adressen
echo "<br><b>IP Adressen:</b> <br><br>";
$diff1 = array_keys(array_diff_assoc($oldip,$newip)); 
$diff2 = array_keys(array_diff_assoc($newip,$oldip));
$tochange = array_unique(array_merge($diff1,$diff2));

#print_r($tochange); echo "<br><br>";

foreach ($tochange as $i){

	$hostexp = ldap_explode_dn($hostDN[$i],1);
	echo "<b>$hostexp[0]</b> - ";

	if ( $oldip[$i] == "" && $newip[$i] != "" ){
		echo "IP <b>$newip[$i]</b> eintragen <br>";
		
		if ($syntax->check_ip_syntax($newip[$i])){
			#echo "korrekte IP Syntax";
			$newip[$i] = htmlentities($newip[$i]);
			$newip_array = array($newip[$i],$newip[$i]);
			#print_r($newip_array);
			$newipp = implode('_',$newip_array);
			#print_r($newipp);
			$oldip[$i] = htmlentities($oldip[$i]);
			if (new_ip_host($newipp,$hostDN[$i],$auDN)){
			 	#$mesg = "Neue IP Adresse eingetragen<br>";
			 	# falls Rechner in DHCP -> fixed-address auf IP Setzen...
			 	if ( $dhcp[$i] ) {
			 		$entryfa ['dhcpoptfixed-address'] = "ip";
					if ( $fixadd ) {
						if ( ldap_mod_replace($ds,$hostDN[$i],$entryfa) ){
							$mesg .= "DHCP Fixed-Address erfolgreich auf IP gesetzt.";
						}else{
							$mesg .= "Fehler beim setzen von DHCP Fixed-Address auf IP!.";
						}
					}else{
						if ( ldap_mod_add($ds,$hostDN[$i],$entryfa) ){
							$mesg .= "DHCP Fixed-Address erfolgreich auf IP gesetzt.";
						}else{
							$mesg .= "Fehler beim setzen von DHCP Fixed-Address auf IP!.";
						}
					}
					# das ganze besser in function new_ip_host umsetzen 
			 		$dhcpchange = 1;
			 	}
			}#else{$mesg = "Fehler beim eintragen der neuen IP Adresse<br>";}
		}else{echo "falsche IP Syntax";}
		echo "<br>";
	}
	
	elseif ( $oldip[$i] != "" && $newip[$i] != "" ){
		echo "IP von <b>$oldip[$i]</b> nach <b>$newip[$i]</b> &auml;ndern <br>";
		
		if ($syntax->check_ip_syntax($newip[$i])){
			#echo "korrekte IP Syntax";
			$newip[$i] = htmlentities($newip[$i]);
			$newip_array = array($newip[$i],$newip[$i]);
			#print_r($newip_array);
			$newipp = implode('_',$newip_array);
			#print_r($newipp);
			$oldip[$i] = htmlentities($oldip[$i]);
			$oldip_array = array($oldip[$i],$oldip[$i]); 
			$oldipp = implode('_',$oldip_array);
			if (modify_ip_host($newipp,$hostDN[$i],$auDN,$fixadd[$i])){
				#$mesg = "IP Adresse geaendert<br>";
				adjust_hostip_tftpserverip($oldip[$i],$newip[$i]);
				if ( $dhcp[$i] ) {
					$dhcpchange = 1;
				}
			}else{
				#$mesg = "Fehler beim aendern der IP Adresse<br>";
				# oldip die schon gelöscht wurde wieder einfügen
				new_ip_host($oldipp,$hostDN[$i],$auDN);}
		}else{echo "falsche IP Syntax";}
		echo "<br>";
	}

	elseif ( $oldip[$i] != "" && $newip[$i] == "" ){
		echo "IP <b>$oldip[$i]</b> l&ouml;schen <br>";
		
		$newip[$i] = htmlentities($newip[$i]);
		$oldip[$i] = htmlentities($oldip[$i]);
		if (delete_ip_host($hostDN[$i],$auDN)){
			#$mesg = "IP Adresse geloescht<br>";
			adjust_hostip_tftpserverip($oldip[$i],"");
			if ( $dhcp[$i] ) {
				$dhcpchange = 1;
			}
		}#else{$mesg = "Fehler beim loeschen der IP Adresse<br>";}
		echo "<br>";
	}
}

echo "</td><td width='33%' class='tab_d'>";
# DHCP 
echo "<br><b>DHCP Dienst:</b> <br><br>";
for ($j=0; $j < count($dhcp); $j++) {
	$entryadd = array();
	$entrymod = array();
	$entrydel = array();
	
	$hostexp = ldap_explode_dn($hostDN[$j],1);
	
	if ( $dhcp[$j] != $olddhcp[$j]) {
		echo "<b>$hostexp[0]</b> - ";
		
		if ( $dhcp[$j] == "" ){
			$entrydel ['dhcphlpcont'] = array();
			if ( $olddhcp[$j] != "dyn" ) {
				$entrydel ['dhcpoptfixed-address'] = array();
			}
			$result = ldap_mod_del($ds,$hostDN[$j],$entrydel);
			if ($result){
				echo "erfolgreich ausgetragen, alter Wert: <b>$olddhcp[$j]</b> <br>";
			}else{
				echo "Fehler beim austragen aus Dienst DHCP <br>";
			}
		}
		elseif ( $olddhcp[$j] == "" ) {
			$entryadd ['dhcphlpcont'] = $dhcpsrv_dn;
			switch ($dhcp[$j]) {
			case 'fix':
				$entryadd ['dhcpoptfixed-address'] = "ip";
				break;
			case 'fixdns':
				$entryadd ['dhcpoptfixed-address'] = "hostname";
				break;
			}
			$result = ldap_mod_add($ds,$hostDN[$j],$entryadd);
			if ($result){
				echo "erfolgreich eingetragen: <b>$dhcp[$j]</b> ("; print($entryadd ['dhcpoptfixed-address']." / ".$entryadd ['dhcphlpcont'].")<br>");
			}else{
				echo "Fehler beim eintragen in Dienst DHCP <br>";
			}
		}else{
			switch ($olddhcp[$j]) {
			case 'fix':
				$entrymod ['dhcpoptfixed-address'] = "hostname";
				break;
			case 'fixdns':
				$entrymod ['dhcpoptfixed-address'] = "ip";
				break;
			}
			$result = ldap_mod_replace($ds,$hostDN[$j],$entrymod);
			if ($result){
				echo "erfolgreich ge&auml;ndert: <b>$olddhcp[$j] -> $dhcp[$j]</b> ("; print($entrymod ['dhcpoptfixed-address'].")<br>");
			}else{
				echo "Fehler beim &auml;ndern der Option fixed-address in Dienst DHCP <br>";
			}
			
		}
		
		$dhcpchange = 1;
	}else{
	#	echo "kein &Auml;nderung <br>";
	}
}

echo "</td><td width='33%' class='tab_d'>";
echo "<br><b>RemoteBoot Dienst:</b> <br><br>";
for ($j=0; $j < count($rbs); $j++) {
	$rbsadd = array();
	$rbsdel = array();
	
	$hostexp = ldap_explode_dn($hostDN[$j],1);
	
	
	if ( $rbs[$j] != $oldrbs[$j]) {
		echo "<b>$hostexp[0]</b> - ";
		
		$exp = ldap_explode_dn($rbs[$j], 1);
	   $rbscn = $exp[0];
	   $oldexp = ldap_explode_dn($oldrbs[$j], 1);
	   $oldrbscn = $oldexp[0];
	   
		if ( $rbs[$j] == "" ){
			$rbsdel ['hlprbservice'] = array();
			$rbsdel ['dhcpoptnext-server'] = array();
			$rbsdel ['dhcpoptfilename'] = array(); 
			
			$result = ldap_mod_del($ds,$hostDN[$j],$rbsdel);
			if ($result){
				echo "erfolgreich ausgetragen, alter Wert: <b>$oldrbscn</b> <br>";
			}else{
				echo "Fehler beim austragen aus Remote Boot Dienst <b>$oldrbscn</b> <br>";
			}
		}else{
			$rbsdhcpdata = get_node_data($rbs[$j],array("tftpserverip","initbootfile"));
	   	$rbsadd ['hlprbservice'] = $rbs[$j];
	   	$rbsadd ['dhcpoptnext-server'] = $rbsdhcpdata['tftpserverip'];
      	$rbsadd ['dhcpoptfilename'] = $rbsdhcpdata['initbootfile'];
			if ( $oldrbs[$j] == "" ) {
				$result = ldap_mod_add($ds,$hostDN[$j],$rbsadd);
				if ($result){
					echo "erfolgreich eingetragen: <b>$rbscn</b> (Next-Server: ";
					print($rbsadd ['dhcpoptnext-server']." / Filename: ".$rbsadd ['dhcpoptfilename'].")<br>");
					rbs_adjust_host($hostDN[$j], $rbs[$j]);
				}else{
					echo "Fehler beim eintragen in Remote Boot Dienst <b>$rbscn</b> <br>";
				}
			}else{
				if ($result = ldap_mod_replace($ds,$hostDN[$j],$rbsadd)){
         		echo "Remote Boot Service erfolgreich ge&auml;ndert (<b>$oldrbscn</b> -> <b>$rbscn</b>)<br>";         		
   	      	rbs_adjust_host($hostDN[$j], $rbs[$j]);
   	   	}else{
   	     	 	echo "Fehler beim &auml;ndern des Remote Boot Dienstes (<b>$oldrbscn</b> -> <b>$rbscn</b>)!<br>";
   	   	}
			}
		}
		$dhcpchange = 1;
	}else{
	#	echo "kein &Auml;nderung <br>";
	}
}

echo "</td><td></tr><tr><td colspan='3'>";

#########

if ( $dhcpchange ){
	update_dhcpmtime($auDN);
}
$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
			Falls nicht, klicken Sie hier <a href='ip_rechner.php' style='publink'>back</a>";
redirect(500, $url, $mesg, $addSessionId = TRUE);

echo "
</td></tr></table>
</head>
</html>";
?>
