<?php
include('../standard_header.inc.php');

$cn = "DHCP_".$_POST['cn'];
$oldcn = "DHCP_".$_POST['oldcn'];
$dhcpoffer = $_POST['dhcpoffer'];
$olddhcpoffer = $_POST['olddhcpoffer'];
$dhcpoptdefinition = $_POST['dhcpoptdefinition'];
$olddhcpoptdefinition = $_POST['olddhcpoptdefinition'];
$adddhcpoptdefinition = $_POST['adddhcpoptdefinition'];

$dhcpDN = $_POST['dhcpdn'];

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
}
#print_r($oldatts); echo "<br><br>";


$nodeDN = "cn=dhcp,".$auDN;
$mnr = $_POST['mnr'];
$sbmnr = $_POST['sbmnr'];
$mcnr = $_POST['mcnr'];

#$deltr = $_POST['deltr'];

$seconds = 2;
$url = "dhcpservice.php?dn=".$dhcpdn."&mnr=1";
 
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
# DHCP Service CN (DN) 

if ( $oldcn == $cn ){
	# $mesg = "keine Aenderung<br>";
}

if ( $oldcn != "" && $cn != "" && $oldcn != $cn ){
	echo "DHCP Service Name aendern<br>";
	# hier noch Syntaxcheck
	# Formulareingaben anpassen
	$exp = explode(" ",$cn);
	foreach ($exp as $word){$expuc[] = ucfirst($word);}
	$cn = implode(" ",$expuc);
	$cn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $cn);
	
	$newdhcpDN = "cn=".$cn.",".$nodeDN;
	print_r($newdhcpDN); echo "<br><br>";
	
	if(move_subtree($dhcpDN, $newdhcpDN)){
		adjust_dhcpservice_dn($newdhcpDN, $dhcpDN);
		$dhcpDN = $newdhcpDN;
		$mesg = "DHCP Service Name erfolgreich ge&auml;ndert<br><br>";
	}else{
		$mesg = "Fehler beim &auml;ndern des DHCP Service Namen!<br><br>";
	}
}

if ( $oldcn != "" && $cn == "" ){
	echo "DHCP Service Name loeschen!<br> 
			Dieser ist Teil des DN, Sie werden den DHCP Service komplett l&ouml;schen<br><br>";
	echo "Wollen Sie den DHCP Service <b>".$oldcn."</b> wirklich l&ouml;schen?<br><br>
			<form action='dhcpservice_delete.php' method='post'>
				Falls ja:<br><br>
				<input type='hidden' name='dn' value='".$dhcpDN."'>
				<input type='hidden' name='name' value='".$oldcn."'>
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

if ( $dhcpoffer != "none" ){
   
   if ( $dhcpoffer != "off" && $dhcpoffer == $olddhcpoffer ){
   	$mesg = "Sie haben die gleiche Abteilung ausgew&auml;hlt<br>
   				Keine &Auml;nderung!";
   }
   
   if ( $dhcpoffer != "off" && $dhcpoffer != $olddhcpoffer ){
   	$entryoffer ['dhcpofferdn'] = $dhcpoffer;
   	if(ldap_mod_replace($ds,$dhcpDN,$entryoffer)){
   		$mesg = "DHCP Service Offer erfolgreich ge&auml;ndert<br><br>";
   	}
   	else{
   		$mesg = "Fehler beim &auml;ndern des DHCP Service Offers!<br><br>";
   	}
   }
   
   /*if ( $dhcpoffer == "off" && $olddhcpoffer != "" ){
      $entryoffer ['dhcpofferdn'] = array();
   	if(ldap_mod_del($ds,$dhcpDN,$entryoffer)){
   		$mesg = "DHCP Service Offer erfolgreich ge&auml;ndert<br><br>";
   	}
   	else{
   		$mesg = "Fehler beim &auml;ndern des DHCP Service Offers!<br><br>";
   	}
   }*/

}

#####################################
# Selbstdefinierte Optionen

if ( $adddhcpoptdefinition != "" ){
   echo "Selbst-definierte DHCP Option hinzuf&uuml;gen.<br>";
   $entryadd['optiondefinition'] = $adddhcpoptdefinition;
   if(ldap_mod_add($ds,$dhcpDN,$entryadd)){
		$mesg = "Selbst-definierte DHCP Option erfolgreich eingetragen<br><br>";
		update_dhcpmtime();
	}else{
		$mesg = "Fehler beim eintragen Selbst-definierte DHCP Option<br><br>";
	}
}

#todo: array_vergleich -> Änderung -> ldap_modify 
#print_r($dhcpoptdefinition);echo "<br>";
#print_r($olddhcpoptdefinition);echo "<br>";

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


if (count($entryadd) != 0 ){
	foreach (array_keys($entryadd) as $key){
		$addatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_add($ds,$dhcpDN,$entryadd)){
		$mesg = "Attribute ".$addatts." erfolgreich eingetragen<br><br>";
		update_dhcpmtime();
	}else{
		$mesg = "Fehler beim eintragen der Attribute ".$addatts."<br><br>";
	}
}

if (count($entrymod) != 0 ){
	foreach (array_keys($entrymod) as $key){
		$modatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_replace($ds,$dhcpDN,$entrymod)){
		$mesg = "Attribute ".$modatts." erfolgreich geaendert<br><br>";
		update_dhcpmtime();
	}else{
		$mesg = "Fehler beim aendern der Attribute ".$modatts."<br><br>";
	}
}

if (count($entrydel) != 0 ){
	foreach (array_keys($entrydel) as $key){
		$delatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_del($ds,$dhcpDN,$entrydel)){
		$mesg = "Attribute ".$delatts." erfolgreich geloescht<br><br>";
      update_dhcpmtime();
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