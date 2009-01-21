<?php
include('../standard_header.inc.php');

$syntax = new Syntaxcheck;

$dhcp = $_POST['dhcpcont'];
$olddhcp = $_POST['olddhcp'];

$hostip = $_POST['hostip'];
$fixedaddress = $_POST['fixadd'];
$oldfixedaddress = $_POST['oldfixadd'];

$hostDN = $_POST['hostdn'];
$sbmnr = $_POST['sbmnr'];

$dhcp = htmlentities($dhcp);
$olddhcp = htmlentities($olddhcp);



/*echo "new dhcp:"; print_r($dhcp); echo "<br>";
echo "old dhcp:"; print_r($olddhcp); echo "<br>";
echo "new rbs:"; print_r($rbs); echo "<br>";
echo "old rbs:"; print_r($oldrbs); echo "<br>";
echo "Host DN:"; print_r($hostDN); echo "<br>";
echo "submenuNR:"; print_r($sbmnr); echo "<br><br>";*/


$seconds = 40;
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
	   echo "DHCP delete "; echo "<br>";
	   if ($result = ldap_mod_del($ds,$hostDN,$entrydhcp)){
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
   	   	$mesg = "Option Fixed-Address erfolgreich auf <b>".$fixedaddress."</b> ge&auml;ndert<br><br>";
   	   }else{
   	   	$mesg = "Fehler beim &auml;ndern der Option Fixed-Address auf <b>".$fixedaddress."</b>!<br><br>";
   	   }
   	}else{
         echo "Fixed Address auf IP Adresse setzen"; echo "<br>";
         if ($result = ldap_mod_add($ds,$hostDN,$entryfixadd)){
   	   	$mesg = "Option Fixed-Address erfolgreich auf <b>".$fixedaddress."</b> gesetzt<br><br>";
   	   }else{
   	   	$mesg = "Fehler beim setzen der Option Fixed-Address auf <b>".$fixedaddress."</b>!<br><br>";
   	   }
      }
   }else{
      $entryfixadd ['dhcpoptfixed-address'] = array();
      echo "No Fixed Address"; echo "<br>";
	   if ($result = ldap_mod_del($ds,$hostDN,$entryfixadd)){
	   	$mesg = "Option Fixed-Address erfolgreich gel&ouml;scht<br><br>";
	   }else{
	   	$mesg = "Fehler beim l&ouml;schen der Option Fixed-Address!<br><br>";
	   }
   }
}


#####################

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>