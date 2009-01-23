<?php
include('../standard_header.inc.php');
$syntax = new Syntaxcheck;

$hostDN = $_POST['hostdn'];
$hostname = $_POST['hostname'];
$oldhostname = $_POST['oldhostname'];
$mac = $_POST['mac'];
$oldmac = $_POST['oldmac'];
$ip = $_POST['ip'];
$oldip = $_POST['oldip'];
$desc = $_POST['desc'];
$olddesc = $_POST['olddesc'];

$dhcphlpcont = $_POST['dhcphlpcont'];
$fixadd = $_POST['fixadd'];

$sbmnr = $_POST['sbmnr'];



$hostname = htmlentities($hostname);
$oldhostname = htmlentities($oldhostname);
$mac = htmlentities($mac);
$mac = strtolower($mac);
$oldmac = htmlentities($oldmac);
$ip = htmlentities($ip);
$oldip = htmlentities($oldip);
$desc = htmlentities($desc);
$olddesc = htmlentities($olddesc);

/*
# sonstige Attribute
$attribs = $_POST['attribs'];
if (count($attribs) != 0){
	foreach (array_keys($attribs) as $key){
		$atts[$key] = htmlentities($attribs[$key]);
	}
}
#print_r($atts); echo "<br><br>";
$oldattribs = $_POST['oldattribs'];
if (count($oldattribs) != 0){
	foreach (array_keys($oldattribs) as $key){
		$oldatts[$key] = htmlentities($oldattribs[$key]);
	}
}*/
#print_r($oldatts); echo "<br><br>";

/*
echo "new hostname:"; print_r($hostname); echo "<br>";
echo "old hostname:"; print_r($oldhostname); echo "<br>";
echo "new mac:"; print_r($mac); echo "<br>";
echo "old mac:"; print_r($oldmac); echo "<br>";
echo "new ip:"; print_r($ip); echo "<br>";
echo "old ip:"; print_r($oldip); echo "<br>";
echo "new desc:"; print_r($desc); echo "<br>";
echo "old desc:"; print_r($olddesc); echo "<br><br>";
echo "Host DN:"; print_r($hostDN); echo "<br>";
echo "submenuNR:"; print_r($submenu); echo "<br><br>";
*/

$dhcpchange = 0;
$seconds = 2;
$url = 'host.php?host='.$hostname.'&sbmnr='.$sbmnr;
 
echo "  
<html>
<head>
	<title>AU Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>";

##############################################
# Hostname

if ( $oldhostname == $hostname ){
	$mesg = "keine Aenderung<br>";
}

if ( $oldhostname != "" && $hostname != "" && $oldhostname != $hostname ){
	echo "Hostname &auml;ndern<br><br>";
	# Check ob Host schon existiert in AU/Domain
	if ( check_host_fqdn($hostname) ) {
		# Formulareingaben anpassen (Leerzeichen raus da Teil des DN)
		$hostname = preg_replace ( '/\s+([0-9a-zA-Z])/', '$1', $hostname);
		
		$newhostDN = "hostname=".$hostname.",cn=computers,".$auDN;
		# print_r($newhostDN); echo "<br><br>";
		modify_host_dn($hostDN, $newhostDN);
		$hostDN = $newhostDN;
		$newhostname = get_rdn_value($newhostDN);
		# newsubmenu holen...hosts neu holen, sortieren, ->position
		#$newhosts = get_hosts($auDN,array("dn"));
		#print_r($newhosts); echo "<br><br>";
		#foreach ($newhosts as $item){
		#	$newdnarray [] = $item['dn'];
		#}
		#$key = array_search($newhostDN, $newdnarray);
		#print_r($key); echo "<br>";
		
		$url = 'host.php?host='.$newhostname.'&sbmnr='.$sbmnr;
		$dhcpchange = 1;
	}else{
		#$brothers = get_hosts($auDN,array("hostname"),"");
		#if ( check_hostname($hostname) ){
		$url = "hostoverview.php";
		$mesg = "In der Domain <b>$assocdom</b> existiert bereits ein Client mit Namen <b>$hostname</b>!<br><br>
					Bitte w&auml;hlen Sie einen anderen HOSTNAMEN,<br>oder l&ouml;schen
					Sie zun&auml;chst den gleichnamigen Client.<br><br>
					<a href=".$url." style='publink'><< &Uuml;bersicht Clients</a>";
		redirect(4, $url, $mesg, $addSessionId = TRUE);
		die;
	}
}

if ( $oldhostname != "" && $hostname == "" ){
	echo "Hostname l&ouml;schen!<br>>br>
			Dies ist Teil des DN, Sie werden den Rechner komplett l&ouml;schen<br><br>";
	echo "Wollen Sie den Rechner <b>".$oldhostname."</b> mit seinen Hardware-Profilen (MachineConfigs) 
			und PXE Bootmen&uuml;s wirklich l&ouml;schen?<br><br>
			<form action='host_delete.php' method='post'>
				Falls ja:<br><br>
				<input type='hidden' name='dn' value='".$hostDN."'>
				<input type='hidden' name='name' value='".$oldhostname."'>
				<input type='Submit' name='apply' value='l&ouml;schen' class='small_loginform_button'><br><br>
			</form>
			<form action='".$url."' method='post'>
				Falls, nein:<br><br>
				<input type='Submit' name='apply' value='zur&uuml;ck' class='small_loginform_button'>
			</form>";
			$seconds = 600;
}



#####################################
# MAC
 
if ( $oldmac == $mac ){
	#$mesg = "keine Aenderung<br>";
}

if ( $oldmac == "" && $mac != "" ){
	#echo "MAC neu anlegen<br>";
	# hier noch Syntaxcheck
	if( $syntax->check_mac_syntax($mac) ){
		$entry['hwaddress'] = $mac;
		$result = ldap_mod_add($ds,$hostDN,$entry);
		if($result){
			$mesg = "MAC erfolgreich eingetragen<br><br>";
		}else{
			$mesg = "Fehler beim eintragen der MAC<br><br>";
		}
	}else{
		echo "Falsche MAC Syntax<br><br>";
	}
}

if ( $oldmac != "" && $mac != "" && $oldmac != $mac ){
	#echo "MAC aendern<br>";
	# hier noch Syntaxcheck
	if( $syntax->check_mac_syntax($mac) ){
		$entry['hwaddress'] = $mac;
		$pxemac = str_replace (":","-",$mac);
		$pxeoldmac = str_replace (":","-",$oldmac);
		$result = ldap_mod_replace($ds,$hostDN,$entry);
		if($result){
			$dhcpchange = 1;
			# in den PXEs auch ändern
			$pxes = get_pxeconfigs($hostDN,array("dn","filename"));
			if ( count($pxes) != 0 ){
				foreach ($pxes as $pxe){
					$entrynewmac ['filename'] = "01-".$pxemac;
					ldap_mod_replace($ds,$pxe['dn'],$entrynewmac);
				}
			}
			# und in Gruppen PXEs 
			$groups = get_groups_member($auDN,array("dn"),$hostDN);
			if ( count($groups) != 0 ){
				$pxes = get_pxeconfigs($groups[0]['dn'],array("dn","filename"));
				if ( count($pxes) != 0 ){
					foreach ($pxes as $pxe){
						if (count($pxe['filename']) > 1){
							for ($i=0; $i<count($pxe['filename']); $i++){
								if ($pxe['filename'][$i] == $pxeoldmac){
									$entrynewmac ['filename'][$i] = "01-".$pxemac;
								}else{
									$entrynewmac ['filename'][$i] = $pxe['filename'][$i];
								}
							}
						}
						if (count($pxe['filename']) == 1 && $pxe['filename'][$i] == $pxeoldmac){
							$entrynewmac ['filename'] = "01-".$pxemac;
						}
						ldap_mod_replace($ds,$pxe['dn'],$entrynewmac);
					}
				}
			}
			$mesg = "MAC erfolgreich geaendert<br><br>
						Falls Rechner-Konfiguration via File, <b>Client-Conf</b> Dateiname in untergeordneten <br>
						PXEs bitte auch &auml;ndern";
		}else{
			$mesg = "Fehler beim aendern der MAC<br><br>";
		}
	}else{
		echo "Falsche MAC Syntax<br><br>";
	}
}

if ( $oldmac != "" && $mac == "" ){
	#echo "MAC loeschen<br>";
	# check ob PXEs am Rechnerobjekt hängen 
	$pxes = get_pxeconfigs($hostDN,array("dn","filename"));
	$groups = get_groups_member($auDN,array("dn"),$hostDN);
	if ( count($groups) != 0 ){
		$pxes2 = get_pxeconfigs($groups[0]['dn'],array("dn","filename"));
	}
	if ( count($pxes) != 0 || count($pxes2) != 0){
		echo "F&uuml;r den Rechner sind PXE Bootmen&uuml;s angelegt welche die MAC Adresse als <br>
				Dateinamen verwenden. Sie k&ouml;ennen die MAC erst l&ouml;schen, wenn Sie diese PXEs <br>
				entfernt haben.<br><br>
				MAC nicht gel&ouml;scht!";
	}
	else{
		$entry['hwaddress'] = $oldmac;
		#$entry['hwaddress'] = array();
		$dhcptext = "";
		if ($dhcphlpcont != ""){
			$entry['dhcphlpcont'] = array();
			if ($fixadd) {
				$entry['dhcpoptfixed-address'] = array();
			}
			#$entry['dhcpoptnext-server'] = array();
			#$entry['dhcpoptfilename'] = array();
			$dhcptext = "Da die MAC-Adresse Voruassetzung f&uuml;r den
						Eintrag DHCP Dienst ist, wurde der Client dort ausgetragen.<br>";
		}
		$result = ldap_mod_del($ds,$hostDN,$entry);
		if($result){
			$dhcpchange = 1;
			$mesg = "MAC erfolgreich geloescht.<br>$dhcptext<br>";
		}else{
			$mesg = "Fehler beim loeschen der MAC<br><br>";
		}
	}
}


########################################
# IP 

if ( $oldip == $ip ){
	# $mesg = "keine Aenderung<br>";
}

if ( $oldip == "" && $ip != "" ){
	#echo "IP neu anlegen<br>";
	# Wenn DHCP Subnet zu IP nicht existiert dann kein Eintrag DHCP
	if ( $network = test_ip_dhcpsubnet($ip)){
		print "<b>Client bereits als dynamisch im DHCP eingetragen.<br>
				IP Adresse $ip kann nicht gesetzt werden, da Subnetz $network/24 nicht im DHCP eingetragen ist</b><br><br>";
	}else{
		# Syntaxcheck
		if( $syntax->check_ip_syntax($ip) ){
			$newip_array = array($ip,$ip);
			$newip = implode('_',$newip_array);
			# print_r($newip); echo "<br><br>";
			if (new_ip_host($newip,$hostDN,$auDN)){
				$mesg = "IP erfolgreich eingetragen<br><br>";
				# Falls Host in DHCP dann Fixed-Address setzen
				if ( $dhcphlpcont ) {
					$dhcpchange = 1;
					$entryfa ['dhcpoptfixed-address'] = "ip";
					if ( $fixadd ) {
						if ( ldap_mod_replace($ds,$hostDN,$entryfa) ){
							$mesg .= "DHCP Fixed-Address erfolgreich auf IP gesetzt.";
						}else{
							$mesg .= "Fehler beim setzen von DHCP Fixed-Address auf IP!.";
						}
					}else{
						if ( ldap_mod_add($ds,$hostDN,$entryfa) ){
							$mesg .= "DHCP Fixed-Address erfolgreich auf IP gesetzt.";
						}else{
							$mesg .= "Fehler beim setzen von DHCP Fixed-Address auf IP!.";
						}
					}
				}
			}else{
				$mesg = "Fehler beim eintragen der IP<br><br>";
			}
		}
		else{
			echo "Falsche IP Syntax<br><br>";
		}
	}
}

if ( $oldip != "" && $ip != "" && $oldip != $ip ){
	#echo "IP aendern<br>";
	# hier noch Syntaxcheck
	if( $syntax->check_ip_syntax($ip) ){
		$newip_array = array($ip,$ip);
		$newip = implode('_',$newip_array);
		# print_r($newip); echo "<br><br>";
		$oldip_array = array($oldip,$oldip); 
		$oldipp = implode('_',$oldip_array);
		if (modify_ip_host($newip,$hostDN,$auDN,$fixadd)){
			$dhcpchange = 1;
			$mesg = "IP erfolgreich geaendert<br><br>";
			# falls Host ein RBS_Server ist
		   adjust_hostip_tftpserverip($oldip,$ip);
		}else{
			$mesg = "Fehler beim aendern der IP<br><br>";
			# oldip die schon gelöscht wurde wieder einfügen
			new_ip_host($oldipp,$hostDN,$auDN);
		}
	}
	else{echo "Falsche IP Syntax<br><br>";}
}

if ( $oldip != "" && $ip == "" ){
	#echo "IP loeschen<br>";

	if(delete_ip_host($hostDN,$auDN)){
		$dhcpchange = 1;
		$mesg = "IP erfolgreich geloescht<br><br>";
		# falls Host ein RBS_Server ist
		adjust_hostip_tftpserverip($oldip,"");
	}else{
		$mesg = "Fehler beim loeschen der IP<br><br>";
	}
}


#####################################
# Description
 
if ( $olddesc == $desc ){
	# $mesg = "keine Aenderung<br>";
}

if ( $olddesc == "" && $desc != "" ){
	echo "Rechner-Beschreibung neu anlegen<br>";
	# hier noch Syntaxcheck
	$entry['description'] = $desc;
	$result = ldap_mod_add($ds,$hostDN,$entry);
	if($result){
		$mesg = "Rechner-Beschreibung erfolgreich eingetragen<br><br>";
	}else{
		$mesg = "Fehler beim eintragen der Rechner-Beschreibung<br><br>";
	}
}

if ( $olddesc != "" && $desc != "" && $olddesc != $desc ){
	echo "Rechner-Beschreibung aendern<br>";
	# hier noch Syntaxcheck
	$entry['description'] = $desc;
	$result = ldap_mod_replace($ds,$hostDN,$entry);
	if($result){
		$mesg = "Rechner-Beschreibung erfolgreich geaendert<br><br>";
	}else{
		$mesg = "Fehler beim aendern der Rechner-Beschreibung<br><br>";
	}
}

if ( $olddesc != "" && $desc == "" ){
	echo "Rechner-Beschreibung loeschen<br>";
	# hier noch Syntaxcheck
	$entry['description'] = $olddesc;
	$result = ldap_mod_del($ds,$hostDN,$entry);
	if($result){
		$mesg = "Rechner-Beschreibung erfolgreich geloescht<br><br>";
	}else{
		$mesg = "Fehler beim loeschen der Rechner-Beschreibung<br><br>";
	}
}




if ( $dhcphlpcont != "" && $dhcpchange ){
	update_dhcpmtime($auDN);
}

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>