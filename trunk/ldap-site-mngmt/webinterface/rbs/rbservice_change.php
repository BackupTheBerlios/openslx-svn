<?php
include('../standard_header.inc.php');

$rbscn = "RBS_".$_POST['rbscn'];
$oldrbscn = "RBS_".$_POST['oldrbscn'];
$rbsoffer = $_POST['rbsoffer'];
$oldrbsoffer = $_POST['oldrbsoffer'];

$tftpserverip = $_POST['tftpserverip'];
$oldtftpserverip = $_POST['oldtftpserverip'];
$nfsserverip = $_POST['nfsserverip'];
$oldnfsserverip = $_POST['oldnfsserverip'];
$nbdserverip = $_POST['nbdserverip'];
$oldnbdserverip = $_POST['oldnbdserverip'];

$tftpserver = $_POST['tftpserver'];
$nfsserver = $_POST['nfsserver'];
$nbdserver = $_POST['nbdserver'];
$oldtftpserverdn = $_POST['oldtftpserverdn'];
$oldnfsserverdn = $_POST['oldnfsserverdn'];
$oldnbdserverdn = $_POST['oldnbdserverdn'];

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


$seconds = 2;
$url = "rbservice.php?&mnr=1";
 
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


#####################################
# Server ändern über IP Feld

$syntax = new Syntaxcheck;

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

if ( $nfsserverip != "" && $nfsserverip != $oldnfsserverip ){
	
	if ($syntax->check_ip_syntax($nfsserverip)){
		$nfsserverip = htmlentities($nfsserverip);
		
		$mesg .= "Suche nach dem Rechner mit IP ".$nfsserverip." :<br>";
		foreach ($host_array as $host){
			$hostipexp = explode('_',$host['ipaddress']);
			$hostip = $hostipexp[0];
			if ($nfsserverip == $hostip){
				$entrytnfs ['nfsserverip'] = $nfsserverip;			
				if (ldap_mod_replace($ds,$rbsDN,$entrytnfs)){
					$mesg .= "Treffer: Rechner ".$host['hostname']."<br>NFS Server erfolgreich ge&auml;ndert<br>";
				}else{
					$mesg .= "Fehler beim  &auml;ndern des NFS Servers!<br>";
				}
				break;
			}else{
				 $mesg .= "Rechner ".$host['hostname'].":  keine &Uuml;bereinstimmung mit eingegebener IP ".$nfsserverip."!<br>";
			}
		}
	}
	else{
		$mesg .= "Falsche IP Syntax!<br>";
	}
}

if ( $nbdserverip != "" && $nbdserverip != $oldnbdserverip ){
	
	if ($syntax->check_ip_syntax($nbdserverip)){
		$nbdserverip = htmlentities($nbdserverip);
		
		$mesg .= "Suche nach dem Rechner mit IP ".$nbdserverip." :<br>";
		foreach ($host_array as $host){
			$hostipexp = explode('_',$host['ipaddress']);
			$hostip = $hostipexp[0];
			if ($nbdserverip == $hostip){
				$entrytnbd ['nbdserverip'] = $nbdserverip;			
				if (ldap_mod_replace($ds,$rbsDN,$entrytnbd)){
					$mesg .= "Treffer: Rechner ".$host['hostname']."<br>NBD Server erfolgreich ge&auml;ndert<br>";
				}else{
					$mesg .= "Fehler beim  &auml;ndern des NBD Servers!<br>";
				}
				break;
			}else{
				 $mesg .= "Rechner ".$host['hostname'].":  keine &Uuml;bereinstimmung mit eingegebener IP ".$nbdserverip."!<br>";
			}
		}
	}
	else{
		$mesg .= "Falsche IP Syntax!<br>";
	}
}

#####################################
# Server ändern über Hostname 

if ($tftpserver != "none" && $tftpserver != $oldtftpserverdn){

	$host = get_host_ip($tftpserver);
	$hostipexp = explode('_',$host['ipaddress']);
	$hostip = $hostipexp[0];
	$entrytftp ['tftpserverip'] = $hostip;
	if (ldap_mod_replace($ds,$rbsDN,$entrytftp)){
		$mesg .= "TFTP Server erfolgreich ge&auml;ndert<br>";
	}else{
		$mesg .= "Fehler beim  &auml;ndern des TFTP Servers!<br>";
	}
	
}		

if ($nfsserver != "none" && $nfsserver != $oldnfsserverdn){

	$host = get_host_ip($nfsserver);
	$hostipexp = explode('_',$host['ipaddress']);
	$hostip = $hostipexp[0];
	$entrynfs ['nfsserverip'] = $hostip;
	if (ldap_mod_replace($ds,$rbsDN,$entrynfs)){
		$mesg .= "NFS Server erfolgreich ge&auml;ndert<br>";
	}else{
		$mesg .= "Fehler beim  &auml;ndern des NFS Servers!<br>";
	}
	
}		

if ($nbdserver != "none" && $nbdserver != $oldnbdserverdn){

	$host = get_host_ip($nbdserver);
	$hostipexp = explode('_',$host['ipaddress']);
	$hostip = $hostipexp[0];
	$entrytnbd ['nbdserverip'] = $hostip;
	if (ldap_mod_replace($ds,$rbsDN,$entrytnbd)){
		$mesg .= "NBD Server erfolgreich ge&auml;ndert<br>";
	}else{
		$mesg .= "Fehler beim  &auml;ndern des NBD Servers!<br>";
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




$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>