<?php
include('../standard_header.inc.php');

$hostname = $_POST['hostname'];
$oldhostname = $_POST['oldhostname'];
$mac = $_POST['mac'];
$oldmac = $_POST['oldmac'];
$ip = $_POST['ip'];
$oldip = $_POST['oldip'];
$desc = $_POST['desc'];
$olddesc = $_POST['olddesc'];

$dhcphlpcont = $_POST['dhcphlpcont'];
$dhcptype = $_POST['dhcptype'];
$hostDN = $_POST['hostdn'];
$sbmnr = $_POST['sbmnr'];

$syntax = new Syntaxcheck;

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

$seconds = 2;
$url = 'host.php?dn='.$hostDN.'&sbmnr='.$sbmnr;
 
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
	echo "Hostname aendern<br>";
	# hier noch Syntaxcheck
	# Formulareingaben anpassen
	$exphn = explode(" ",$hostname);
	foreach ($exphn as $word){$expuc[] = ucfirst($word);}
	$hostname = implode(" ",$expuc);
	$hostname = preg_replace ( '/\s+([0-9A-Z])/', '$1', $hostname);
	
	$newhostDN = "hostname=".$hostname.",cn=computers,".$auDN;
	# print_r($newhostDN); echo "<br><br>";
	modify_host_dn($hostDN, $newhostDN);
	
	# newsubmenu holen...hosts neu holen, sortieren, ->position
	#$newhosts = get_hosts($auDN,array("dn"));
	#print_r($newhosts); echo "<br><br>";
	#foreach ($newhosts as $item){
	#	$newdnarray [] = $item['dn'];
	#}
	#$key = array_search($newhostDN, $newdnarray);
	#print_r($key); echo "<br>";
	 
	$url = 'host.php?dn='.$newhostDN.'&sbmnr='.$sbmnr;

}

if ( $oldhostname != "" && $hostname == "" ){
	echo "Hostname loeschen!<br> 
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
	echo "MAC neu anlegen<br>";
	# hier noch Syntaxcheck
	$entry['hwaddress'] = $mac;
	$result = ldap_mod_add($ds,$hostDN,$entry);
	if($result){
		$mesg = "MAC erfolgreich eingetragen<br><br>";
	}else{
		$mesg = "Fehler beim eintragen der MAC<br><br>";
	}
}

if ( $oldmac != "" && $mac != "" && $oldmac != $mac ){
	echo "MAC aendern<br>";
	# hier noch Syntaxcheck
	$entry['hwaddress'] = $mac;
	$pxemac = str_replace (":","-",$mac);
	$pxeoldmac = str_replace (":","-",$oldmac);
	$result = ldap_mod_replace($ds,$hostDN,$entry);
	if($result){
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
}

if ( $oldmac != "" && $mac == "" ){
	echo "MAC loeschen<br>";
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
		# hier noch Syntaxcheck
		$entry['hwaddress'] = $oldmac;
		$result = ldap_mod_del($ds,$hostDN,$entry);
		if($result){
			$mesg = "MAC erfolgreich geloescht<br><br>";
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
	echo "IP neu anlegen<br>";
	# hier noch Syntaxcheck
	if( $syntax->check_ip_syntax($ip) ){
		$newip_array = array($ip,$ip);
		$newip = implode('_',$newip_array);
		# print_r($newip); echo "<br><br>";
		if (new_ip_host($newip,$hostDN,$auDN)){
			$mesg = "IP erfolgreich eingetragen<br><br>";
			if ($dhcptype == "subnet"){
   			adjust_hostip_dhcpsubnet($ip,$hostDN,$dhcphlpcont);
		   }
		}else{
			$mesg = "Fehler beim eintragen der IP<br><br>";
		}
	}
	else{echo "Falsche IP Syntax<br><br>";}
}

if ( $oldip != "" && $ip != "" && $oldip != $ip ){
	echo "IP aendern<br>";
	# hier noch Syntaxcheck
	if( $syntax->check_ip_syntax($ip) ){
		$newip_array = array($ip,$ip);
		$newip = implode('_',$newip_array);
		# print_r($newip); echo "<br><br>";
		$oldip_array = array($oldip,$oldip); 
		$oldipp = implode('_',$oldip_array);
		if (modify_ip_host($newip,$hostDN,$auDN)){
			$mesg = "IP erfolgreich geaendert<br><br>";
			if ($dhcptype == "subnet"){
   			adjust_hostip_dhcpsubnet($ip,$hostDN,$dhcphlpcont);
		   }
		}else{
			$mesg = "Fehler beim aendern der IP<br><br>";
			# oldip die schon gelöscht wurde wieder einfügen
			new_ip_host($oldipp,$hostDN,$auDN);
		}
	}
	else{echo "Falsche IP Syntax<br><br>";}
}

if ( $oldip != "" && $ip == "" ){
	echo "IP loeschen<br>";

	if(delete_ip_host($hostDN,$auDN)){
		$mesg = "IP erfolgreich geloescht<br><br>";
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

#################################### 
# restliche Attribute
/*
$entryadd = array();
$entrymod = array();
$entrydel = array();

foreach (array_keys($atts) as $key){
	
	if ( $oldatts[$key] == $atts[$key] ){
		#$mesg = "keine Aenderung<br>";
	}
	if ( $oldatts[$key] == "" && $atts[$key] != "" ){
		# hier noch Syntaxcheck
		$entryadd[$key] = $atts[$key];
	}
	if ( $oldatts[$key] != "" && $atts[$key] != "" && $oldatts[$key] != $atts[$key] ){
		# hier noch Syntaxcheck
		$entrymod[$key] = $atts[$key];
	}
	if ( $oldatts[$key] != "" && $atts[$key] == "" ){
		# hier noch Syntaxcheck
		$entrydel[$key] = $oldatts[$key];
	}
}
#print_r($entryadd); echo "<br>";
#print_r($entrymod); echo "<br>";
#print_r($entrydel); echo "<br>";

if (count($entryadd) != 0 ){
	#print_r($entryadd); echo "<br>";
	#echo "neu anlegen<br>"; 
	foreach (array_keys($entryadd) as $key){
		$addatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_add($ds,$hostDN,$entryadd)){
		$mesg = "Attribute ".$addatts." erfolgreich eingetragen<br><br>";
	}else{
		$mesg = "Fehler beim eintragen der Attribute ".$addatts."<br><br>";
	}
}

if (count($entrymod) != 0 ){
	#print_r($entrymod); echo "<br>";
	#echo "&auml;ndern<br>";
	foreach (array_keys($entrymod) as $key){
		$modatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_replace($ds,$hostDN,$entrymod)){
		$mesg = "Attribute ".$modatts." erfolgreich geaendert<br><br>";
	}else{
		$mesg = "Fehler beim aendern der Attribute ".$modatts."<br><br>";
	}
}

if (count($entrydel) != 0 ){
	#print_r($entrydel); echo "<br>";
	#echo "l&ouml;schen<br>";
	foreach (array_keys($entrydel) as $key){
		$delatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_del($ds,$hostDN,$entrydel)){
		$mesg = "Attribute ".$delatts." erfolgreich geloescht<br><br>";
	}else{
		$mesg = "Fehler beim loeschen der Attribute ".$delatts."<br><br>";
	}
}

*/


$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>