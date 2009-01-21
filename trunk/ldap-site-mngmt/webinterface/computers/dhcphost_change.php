<?php
include('../standard_header.inc.php');

$syntax = new Syntaxcheck;

$dhcp = $_POST['dhcpcont'];
$olddhcp = $_POST['olddhcp'];

$hostip = $_POST['hostip'];
$fixedaddress = $_POST['fixadd'];
$oldfixedaddress = $_POST['oldfixadd'];
$oldrbs = $_POST['oldrbs'];

$hostDN = $_POST['hostdn'];
$sbmnr = $_POST['sbmnr'];

$dhcp = htmlentities($dhcp);
$olddhcp = htmlentities($olddhcp);

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

/*echo "new dhcp:"; print_r($dhcp); echo "<br>";
echo "old dhcp:"; print_r($olddhcp); echo "<br>";
echo "new rbs:"; print_r($rbs); echo "<br>";
echo "old rbs:"; print_r($oldrbs); echo "<br>";
echo "Host DN:"; print_r($hostDN); echo "<br>";
echo "submenuNR:"; print_r($sbmnr); echo "<br><br>";*/


$seconds = 2;
$url = 'dhcphost.php?dn='.$hostDN.'&sbmnr='.$sbmnr;
 
echo "  
<html>
<head>
	<title>AU Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>";

##########################################
# DHCP

if ($dhcp != "none" && $dhcp != $olddhcp){
   if ($dhcp != ""){
   	$exp = ldap_explode_dn($dhcp, 1);
	   $dhcpcn = $exp[0];
	   $dhcpau = $exp[2];
	   
	   $entrydhcp ['dhcphlpcont'] = $dhcp;
	   if ($olddhcp != ""){
	      echo "DHCP replace "; print_r($olddhcp); echo " with "; print_r($entrydhcp); echo "<br>";
   	   if ($result = ldap_mod_replace($ds,$hostDN,$entrydhcp)){
   	      update_dhcpmtime(array());
   	   	$mesg = "Rechner erfolgreich in DHCP <b>".$dhcpcn." [Abt.: ".$dhcpau."]</b> angemeldet<br><br>";
   	   }else{
   	   	$mesg = "Fehler beim &auml;ndern des DHCP Dienstes zu <b>".$dhcpcn."</b>!<br><br>";
   	   }
	   }else{
	      if ( $hostip != "" ){
	         $entrydhcp ['dhcpoptfixed-address'] = "ip";
	      }
	      echo "DHCP add "; print_r($entrydhcp); echo "<br>";
	      if ($result = ldap_mod_add($ds,$hostDN,$entrydhcp)){
	         update_dhcpmtime(array());
   	   	$mesg = "Rechner erfolgreich in DHCP <b>".$dhcpcn." [Abt.: ".$dhcpau."]</b> angemeldet<br><br>";
   	   }else{
   	   	$mesg = "Fehler beim &auml;ndern des DHCP Dienstes zu <b>".$dhcpcn."</b>!<br><br>";
   	   }
	   }
	}else{
	   $entrydhcp ['dhcphlpcont'] = array();
	   if ( $oldfixedaddress != "" ){
	      $entrydhcp ['dhcpoptfixed-address'] = array();
	   }
	   #if ( $oldrbs != "" ){
	   #   $entrydhcp ['hlprbservice'] = array();
	   #}
	   echo "DHCP delete "; echo "<br>";
	   if ($result = ldap_mod_del($ds,$hostDN,$entrydhcp)){
	      update_dhcpmtime(array());
	   	$mesg = "Rechner erfolgreich aus DHCP gel&ouml;scht<br><br>";
	   }else{
	   	$mesg = "Fehler beim l&ouml;schen aus DHCP Dienst!<br><br>";
	   }
	}
	
}
if ($dhcp == "none"){
   echo " DHCP none <br>";
}

# DHCP Option fixed-address
if ($fixedaddress != "none" && $fixedaddress != $oldfixedaddress){
   if ($fixedaddress != ""){
      $entryfixadd ['dhcpoptfixed-address'] = $fixedaddress;
      if ($oldfixedaddress != ""){
         echo "Fixed Address &auml;ndern"; echo "<br>";
         if ($result = ldap_mod_replace($ds,$hostDN,$entryfixadd)){
            update_dhcpmtime(array());
   	   	$mesg = "Option Fixed-Address erfolgreich auf <b>".$fixedaddress."</b> ge&auml;ndert<br><br>";
   	   }else{
   	   	$mesg = "Fehler beim &auml;ndern der Option Fixed-Address auf <b>".$fixedaddress."</b>!<br><br>";
   	   }
   	}else{
         echo "Fixed Address auf IP Adresse setzen"; echo "<br>";
         if ($result = ldap_mod_add($ds,$hostDN,$entryfixadd)){
            update_dhcpmtime(array());
   	   	$mesg = "Option Fixed-Address erfolgreich auf <b>".$fixedaddress."</b> gesetzt<br><br>";
   	   }else{
   	   	$mesg = "Fehler beim setzen der Option Fixed-Address auf <b>".$fixedaddress."</b>!<br><br>";
   	   }
      }
   }else{
      $entryfixadd ['dhcpoptfixed-address'] = array();
      echo "No Fixed Address"; echo "<br>";
	   if ($result = ldap_mod_del($ds,$hostDN,$entryfixadd)){
	      update_dhcpmtime(array());
	   	$mesg = "Option Fixed-Address erfolgreich gel&ouml;scht<br><br>";
	   }else{
	   	$mesg = "Fehler beim l&ouml;schen der Option Fixed-Address!<br><br>";
	   }
   }
}

#####################################
# Restliche Attribute (u.a. Description)

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
	if(ldap_mod_add($ds,$hostDN,$entryadd)){
		$mesg = "Attribute ".$addatts." erfolgreich eingetragen<br><br>";
		update_dhcpmtime(array());
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
		update_dhcpmtime(array());
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
      update_dhcpmtime(array());
	}else{
		$mesg = "Fehler beim loeschen der Attribute ".$delatts."<br><br>";
	}
}


#####################

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>