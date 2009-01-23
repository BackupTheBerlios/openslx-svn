<?php
include('../standard_header.inc.php');

$dhcpDN = $_POST['dhcpdn'];
$dhcpaudn = get_audn_of_objectdn($dhcpDN);
$changedhcpdn = $_POST['altdhcpsrv'];

#$maxlease = $_POST['dhcpoptmax-lease-time'];
#$defaultlease = $_POST['dhcpoptdefault-lease-time'];
#$oldmaxlease = $_POST['oldmax-lease-time'];
#$olddefaultlease = $_POST['olddefault-lease-time'];
$pcl = $_POST['pcl'];
$oldpcl = $_POST['oldpcl'];

$adddhcpoptdefinition = $_POST['adddhcpoptdefinition'];
#$dhcpoptdefinition = $_POST['dhcpoptdefinition'];
#$olddhcpoptdefinition = $_POST['olddhcpoptdefinition'];

# sonstige Attribute
$attribs = $_POST['attribs'];
if (count($attribs) != 0){
	foreach (array_keys($attribs) as $key){
		$atts[$key] = htmlentities($attribs[$key]);
	}
}

$oldattribs = $_POST['oldattribs'];
if (count($oldattribs) != 0){
	foreach (array_keys($oldattribs) as $key){
		$oldatts[$key] = htmlentities($oldattribs[$key]);
	}
}

#
#$atts['dhcpoptmax-lease-time'] = htmlentities($maxlease);
#$oldatts['dhcpoptmax-lease-time'] = htmlentities($oldmaxlease);
#$atts['dhcpoptdefault-lease-time'] = htmlentities($defaultlease);
#$oldatts['dhcpoptdefault-lease-time'] = htmlentities($olddefaultlease);

#print_r($atts); echo "<br><br>";
#print_r($oldatts); echo "<br><br>";

$dhcpchange = 0;
$seconds = 2;
$url = "dhcpservice.php?dn=".$dhcpdn;
 
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

if ( $changedhcpdn != 'none' ){
	adjust_dhcpservice_dn ($dhcpdn,$changedhcpdn);
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

#############################
# Permitted Pool Clients

/*if ( $pcl != $oldpcl ) {
	if ($pcl == "") {
		$pclmodentry ['dhcppermittedclients'] = array();
		if ( ldap_mod_del($ds,$dhcpDN,$pclmodentry) ){
			printf("Zugelassene Subnet Clients auf <b>%s</b> gesetzt<br><br>",$pcl);
			$dhcpchange = 1;
		}
	}
	elseif ( $oldpcl == "" ) {
		$pclmodentry ['dhcppermittedclients'] = $pcl;
		if ( ldap_mod_add($ds,$dhcpDN,$pclmodentry) ){
			printf("Zugelassene Subnet Clients auf <b>%s</b> gesetzt<br><br>",$pcl);
			$dhcpchange = 1;
		}
	}
}*/

#####################################
# Offer ändern 

/*if ( $dhcpoffer != "none" ){
   
   if ( ($dhcpoffer != "off" && $dhcpoffer == $olddhcpoffer) || ($dhcpoffer == "off" && $olddhcpoffer == "") ){
   	$mesg = "Sie haben die gleiche Abteilung ausgew&auml;hlt<br>
   				Keine &Auml;nderung!<br><br>";
   }
   
   if ( $dhcpoffer != "off" && $dhcpoffer != $olddhcpoffer ){
   	$entryoffer ['dhcpofferdn'] = $dhcpoffer;
   	if ($olddhcpoffer == ""){
   	   # Offer anlegen
      	if(ldap_mod_add($ds,$dhcpDN,$entryoffer)){
      		$mesg = "DHCP Service Offer erfolgreich angelegt<br><br>";
      	}
      	else{
      		$mesg = "Fehler beim &auml;ndern des DHCP Service Offers!<br><br>";
      	}
   	}
   	else{
   	   # Offer ändern
      	if(ldap_mod_replace($ds,$dhcpDN,$entryoffer)){
      		$mesg = "DHCP Service Offer erfolgreich ge&auml;ndert<br><br>";
      	}
      	else{
      		$mesg = "Fehler beim &auml;ndern des DHCP Service Offers!<br><br>";
      	}
   	}
   }
   
   if ( $dhcpoffer == "off" && $olddhcpoffer != "" ){
      $entryoffer ['dhcpofferdn'] = array();
   	if(ldap_mod_del($ds,$dhcpDN,$entryoffer)){
   		$mesg = "DHCP Service Offer erfolgreich gel&ouml;scht<br><br>";
   		cleanup_del_dhcpservice ($dhcpDN);
   	}
   	else{
   		$mesg = "Fehler beim &auml;ndern des DHCP Service Offers!<br><br>";
   	}
   }

}*/

#####################################
# Selbstdefinierte Optionen

if ( $adddhcpoptdefinition != "" ){
   echo "Selbst-definierte DHCP Option hinzuf&uuml;gen.<br>";
   $entryadd['optiondefinition'] = $adddhcpoptdefinition;
   if(ldap_mod_add($ds,$dhcpDN,$entryadd)){
		$mesg = "Selbst-definierte DHCP Option erfolgreich eingetragen<br><br>";
		$dhcpchange = 1;
	}else{
		$mesg = "Fehler beim eintragen Selbst-definierte DHCP Option<br><br>";
	}
}

if ( $pcl != $oldpcl ) {
	if ($pcl != "") {
		$pcladdentry ['dhcppermittedclients'] = $pcl;
		if ( ldap_mod_add($ds,$dhcpDN,$pcladdentry) ){
			printf("Zugelassene dynamische Clients auf <b>%s</b> gesetzt<br><br>",$pcl);
			$dhcpchange = 1;
		}else{
			printf("Fehler beim setzen der zugelassenen dynamischen Clients auf <b>%s</b><br><br>",$pcl);
		}
	}else{
		$pcldelentry ['dhcppermittedclients'] = array();
		if ( ldap_mod_del($ds,$dhcpDN,$pcldelentry) ){
			printf("Zugelassene dynamische Clients auf <b>allow unknown-clients</b> gesetzt<br><br>");
			$dhcpchange = 1;
		}else{
			printf("Fehler beim setzen der zugelassenen dynamischen Clients auf <b>allow unknown-clients</b><br><br>");
		}
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
	
	if ( $oldatts[$key] != $atts[$key] ){
		if ( $oldatts[$key] == "" ){
			# hier noch Syntaxcheck
			$entryadd[$key] = $atts[$key];
		}
		elseif ( $atts[$key] == "" ){
			# hier noch Syntaxcheck
			$entrydel[$key] = $oldatts[$key];
		}
		else {
			# hier noch Syntaxcheck
			$entrymod[$key] = $atts[$key];
		}
	}
}


if (count($entryadd) != 0 ){
	foreach (array_keys($entryadd) as $key){
		$addatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_add($ds,$dhcpDN,$entryadd)){
		$mesg .= "Attribute ".$addatts." erfolgreich eingetragen<br>";
		$dhcpchange = 1;
	}else{
		$mesg .= "Fehler beim eintragen der Attribute ".$addatts."<br>";
	}
}

if (count($entrymod) != 0 ){
	foreach (array_keys($entrymod) as $key){
		$modatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_replace($ds,$dhcpDN,$entrymod)){
		$mesg .= "Attribute ".$modatts." erfolgreich geaendert<br>";
		$dhcpchange = 1;
	}else{
		$mesg .= "Fehler beim aendern der Attribute ".$modatts."<br>";
	}
}

if (count($entrydel) != 0 ){
	foreach (array_keys($entrydel) as $key){
		$delatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_del($ds,$dhcpDN,$entrydel)){
		$mesg .= "Attribute ".$delatts." erfolgreich geloescht<br>";
      $dhcpchange = 1;
	}else{
		$mesg .= "Fehler beim loeschen der Attribute ".$delatts."<br>";
	}
}

if ( $dhcpchange ) {
	update_dhcpmtime($dhcpaudn);
}

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>