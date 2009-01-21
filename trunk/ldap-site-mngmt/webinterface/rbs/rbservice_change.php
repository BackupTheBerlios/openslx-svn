<?php
include('../standard_header.inc.php');
$syntax = new Syntaxcheck;

$rbscn = "RBS_".$_POST['rbscn'];
$oldrbscn = "RBS_".$_POST['oldrbscn'];
$rbsoffer = $_POST['rbsoffer'];
$oldrbsoffer = $_POST['oldrbsoffer'];

$tftpserverip = $_POST['tftpserverip'];
$oldtftpserverip = $_POST['oldtftpserverip'];
#$nfsserverip = $_POST['nfsserverip'];
#$oldnfsserverip = $_POST['oldnfsserverip'];
#$nbdserverip = $_POST['nbdserverip'];
#$oldnbdserverip = $_POST['oldnbdserverip'];

$tftpserver = $_POST['tftpserver'];
#$nfsserver = $_POST['nfsserver'];
#$nbdserver = $_POST['nbdserver'];
$oldtftpserverdn = $_POST['oldtftpserverdn'];
#$oldnfsserverdn = $_POST['oldnfsserverdn'];
#$oldnbdserverdn = $_POST['oldnbdserverdn'];

$initbootfile = $_POST['initbootfile'];
$oldinitbootfile = $_POST['oldinitbootfile'];

$delfsuri = $_POST['delfsuri'];
$addfsuri = $_POST['addfsuri'];
$fstype = $_POST['fstype'];
$fsip = $_POST['fsip'];
$fspath = $_POST['fspath'];

$host_array = get_hosts($auDN,array("dn","hostname","ipaddress"));

$rbsDN = $_POST['rbsdn'];
$nodeDN = "cn=rbs,".$auDN;

$mnr = $_POST['mnr'];
$sbmnr = $_POST['sbmnr'];
$mcnr = $_POST['mcnr'];

# sosntige Attribute
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
}
#print_r($oldatts); echo "<br><br>";

 
echo "
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>";

##############################################
# RBS CN (DN) 

if ( $oldrbscn == $rbscn ){
	# $mesg = "keine Aenderung<br>";
}

if ( $oldrbscn != "" && $rbscn != "" && $oldrbscn != $rbscn ){
	echo "RBS Name aendern<br>";
	# hier noch Syntaxcheck
	# Formulareingaben anpassen
	$exprbs = explode(" ",$rbscn);
	foreach ($exprbs as $word){$expuc[] = ucfirst($word);}
	$rbscn = implode(" ",$expuc);
	$rbscn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $rbscn);
	
	$newrbsDN = "cn=".$rbscn.",".$nodeDN;
	print_r($newrbsDN); echo "<br><br>";
	
	if(move_subtree($rbsDN, $newrbsDN)){
		adjust_rbs_dn($newrbsDN, $rbsDN);
		$rbsDN = $newrbsDN;
		$mesg = "RBS Name erfolgreich ge&auml;ndert<br><br>";
	}else{
		$mesg = "Fehler beim &auml;ndern des RBS Namen!<br><br>";
	}
}

if ( $oldrbscn != "" && $rbscn == "" ){
	echo "Gruppenname loeschen!<br> 
			Dieses ist Teil des DN, Sie werden den RBS komplett l&ouml;schen<br><br>";
	echo "Wollen Sie den RBS Dienst <b>".$oldrbscn."</b> wirklich l&ouml;schen?<br><br>
			<form action='rbservice_delete.php' method='post'>
				Falls ja:<br><br>
				<input type='hidden' name='dn' value='".$pxeDN."'>
				<input type='hidden' name='name' value='".$oldrbscn."'>
				<input type='Submit' name='apply' value='l&ouml;schen' class='small_loginform_button'><br><br>
			</form>
			<form action='".$url."' method='post'>
				Falls, nein:<br><br>
				<input type='Submit' name='apply' value='zur&uuml;ck' class='small_loginform_button'>
			</form>";
			$seconds = 600;
}


#####################################
# Offer ändern 

if ( $rbsoffer != "none" && $rbsoffer == $oldrbsoffer ){
	$mesg = "Sie haben die gleiche Abteilung ausgew&auml;hlt<br>
				Keine &Auml;nderung!";
}

if ( $rbsoffer != "none" && $rbsoffer != $oldrbsoffer ){
	$entryoffer ['rbsofferdn'] = $rbsoffer;
	if(ldap_mod_replace($ds,$rbsDN,$entryoffer)){
		$mesg = "RBS Offer erfolgreich ge&auml;ndert<br><br>";
	}
	else{
		$mesg = "Fehler beim &auml;ndern des RBS Offers!<br><br>";
	}
}

/*if ( $rbsoffer == "off" && $olddhcpoffer != "" ){
   $entryoffer ['dhcpofferdn'] = array();
	if(ldap_mod_del($ds,$dhcpDN,$entryoffer)){
		$mesg = "DHCP Service Offer erfolgreich ge&auml;ndert<br><br>";
	}
	else{
		$mesg = "Fehler beim &auml;ndern des DHCP Service Offers!<br><br>";
	}
}*/


#####################################
# TFTP Server ändern 

# über IP Feld
/*if ( $tftpserverip == $oldtftpserverip ){
	# $mesg = "keine Aenderung<br>";
}

if ( $tftpserverip != "" && $oldtftpserverip == "" ){
   if ($syntax->check_ip_syntax($tftpserverip)){
		$tftpserverip = htmlentities($tftpserverip);
		
		$mesg .= "Suche nach dem Rechner mit IP ".$tftpserverip." :<br>";
		foreach ($host_array as $host){
			$hostipexp = explode('_',$host['ipaddress']);
			$hostip = $hostipexp[0];
			if ($tftpserverip == $hostip){
				$entrytftp ['tftpserverip'] = $tftpserverip;			
				if (ldap_mod_add($ds,$rbsDN,$entrytftp)){
				   adjust_dhcpnextserver($tftpserverip, $rbsDN);
					$mesg .= "Treffer: Rechner ".$host['hostname']."<br>TFTP Server erfolgreich eingetragen<br>";
				}else{
					$mesg .= "Fehler beim  Eintragen des TFTP Servers!<br>";
				}
				break;
			}else{
				 $mesg .= "Rechner ".$host['hostname'].":  keine &Uuml;bereinstimmung mit eingegebener IP ".$tftpserverip."!<br>";
			}
		}
	}
	else{
		$mesg .= "Falsche IP Syntax!<br>";
	}
}

if ( $tftpserverip != "" && $tftpserverip != $oldtftpserverip ){
	
	if ($syntax->check_ip_syntax($tftpserverip)){
		$tftpserverip = htmlentities($tftpserverip);
		
		$mesg .= "Suche nach dem Rechner mit IP ".$tftpserverip." :<br>";
		foreach ($host_array as $host){
			$hostipexp = explode('_',$host['ipaddress']);
			$hostip = $hostipexp[0];
			if ($tftpserverip == $hostip){
				$entrytftp ['tftpserverip'] = $tftpserverip;			
				if (ldap_mod_replace($ds,$rbsDN,$entrytftp)){
				   adjust_dhcpnextserver($tftpserverip, $rbsDN);
					$mesg .= "Treffer: Rechner ".$host['hostname']."<br>TFTP Server erfolgreich ge&auml;ndert<br>";
				}else{
					$mesg .= "Fehler beim  &auml;ndern des TFTP Servers!<br>";
				}
				break;
			}else{
				 $mesg .= "Rechner ".$host['hostname'].":  keine &Uuml;bereinstimmung mit eingegebener IP ".$tftpserverip."!<br>";
			}
		}
	}
	else{
		$mesg .= "Falsche IP Syntax!<br>";
	}
}

if ( $tftpserverip == "" && $oldtftpserverip != "" ){
   $entrytftp ['tftpserverip'] = array();			
	if (ldap_mod_del($ds,$rbsDN,$entrytftp)){
	   adjust_dhcpnextserver($tftpserverip, $rbsDN);
		$mesg .= "Treffer: Rechner ".$host['hostname']."<br>TFTP Server erfolgreich gel&ouml;scht<br>";
	}else{
		$mesg .= "Fehler beim  l&ouml;schen des TFTP Servers!<br>";
	}
}*/

#über Selectbox an verfügbaren alternativen Rechnern mit IPs
if ($tftpserver != "none" && $tftpserver != $oldtftpserverdn){
	$host = get_host_ip($tftpserver);
	$hostipexp = explode('_',$host['ipaddress']);
	$entrytftp ['tftpserverip'] = $hostipexp[0];
	if (ldap_mod_replace($ds,$rbsDN,$entrytftp)){
	   adjust_dhcpnextserver($hostipexp[0], $rbsDN);
		$mesg .= "TFTP Server erfolgreich ge&auml;ndert<br>";
	}else{
		$mesg .= "Fehler beim  &auml;ndern des TFTP Servers!<br>";
	}	
}		


#####################################
# Init Boot File

if ( $initbootfile == $oldinitbootfile ){
	# $mesg = "keine Aenderung<br>";
}

if ( $initbootfile != "" && $oldinitbootfile == "" ){
   $entrydelibf ['initbootfile'] = $initbootfile;
   if(ldap_mod_add($ds,$rbsDN,$entrydelibf)){
      adjust_dhcpfilename($initbootfile, $rbsDN, "add");
		$mesg = "Initial Boot File erfolgreich eingetragen<br><br>";
	}
	else{
		$mesg = "Fehler beim eintragen von Initial Boot File!<br><br>";
	}
}

if ( $initbootfile == "" && $oldinitbootfile != "" ){
   $entrydelibf ['initbootfile'] = array();
   if(ldap_mod_del($ds,$rbsDN,$entrydelibf)){
      adjust_dhcpfilename($initbootfile, $rbsDN, "delete");
		$mesg = "Initial Boot File erfolgreich gel&ouml;scht<br><br>";
	}
	else{
		$mesg = "Fehler beim l&ouml;schen von Initial Boot File!<br><br>";
	}
}

if ( $initbootfile != "" && $initbootfile != $oldinitbootfile ){
   $entryibf ['initbootfile'] = $initbootfile;
	if(ldap_mod_replace($ds,$rbsDN,$entryibf)){
	   adjust_dhcpfilename($initbootfile, $rbsDN, "replace");
		$mesg = "Initial Boot File erfolgreich ge&auml;ndert<br><br>";
	}
	else{
		$mesg = "Fehler beim &auml;ndern des Initial Boot Files!<br><br>";
	}
}


#######################################
# Fileserver URI anlegen

if ( $addfsuri[1] != "" ){
   # tests: ipsyntax, und spezifische URI-Syntax-Checks...
   if( $syntax->check_ip_syntax($addfsuri[1]) ){
      
      $newfsuri = $addfsuri[0]."://".$addfsuri[1].$addfsuri[2];
      echo "FS URI <b>".$newfsuri."</b> anlegen<br>";
      
      $entryfsadd ['fileserveruri'] = $newfsuri;
      if(ldap_mod_add($ds,$rbsDN,$entryfsadd)){
			$mesg = "FS URI erfolgreich eingetragen<br><br>";
		}else{
			$mesg = "Fehler beim eintragen der FS URI<br><br>";
		}
	}
	else{echo "Falsche IP Syntax<br><br>";}
}

#####################################
# Fileserver URIs löschen

if ( count($delfsuri) != 0 ){
	echo "Fileserver URI l&ouml;schen<br>";
	
	$i = 0;
	foreach ($delfsuri as $fsuri){
		$entry['fileserveruri'][$i] = $fsuri;
		$i++;
	}
	#print_r($entry); echo "<br><br>";
	
	if ($result = ldap_mod_del($ds,$rbsDN,$entry)){
		$mesg = "Zu l&ouml;schende Fileserver URIs erfolgreich gel&ouml;scht<br><br>";
	}else{
		$mesg = "Fehler beim l&ouml;schen der Fileserver URIs<br><br>";
	}
} 

 
#####################################
# Restliche Attribute

$entryadd = array();
$entrymod = array();
$entrydel = array();

foreach (array_keys($atts) as $key){
	
	if ( $oldatts[$key] == $atts[$key] ){
	
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
	if(ldap_mod_add($ds,$rbsDN,$entryadd)){
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
	if(ldap_mod_replace($ds,$rbsDN,$entrymod)){
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
	if(ldap_mod_del($ds,$rbsDN,$entrydel)){
		$mesg = "Attribute ".$delatts." erfolgreich geloescht<br><br>";
	}else{
		$mesg = "Fehler beim loeschen der Attribute ".$delatts."<br><br>";
	}
}


$url = "rbservice.php?rbsdn=".$rbsDN."&mnr=".$mnr;
$seconds = 2;


$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>