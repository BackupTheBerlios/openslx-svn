<?php
include('../standard_header.inc.php');

$syntax = new Syntaxcheck;

$hostDN = $_POST['hostdn'];
$hostname = $_POST['hostname'];
$hostip = $_POST['hostip'];
#$hostmac = $_POST['hostmac'];
$fixedaddress = $_POST['fixadd'];
$oldfixedaddress = $_POST['oldfixadd'];

$dhcp = $_POST['dhcpcont'];
$olddhcp = $_POST['olddhcp'];
$rbs = $_POST['rbs'];
$oldrbs = $_POST['oldrbs'];

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

$dhcpchange = 0;

$seconds = 3;
$url = 'dhcphost.php?host='.$hostname.'&sbmnr='.$sbmnr;
 
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
# DHCP Einbindung

if ( $dhcp != $olddhcp){
	if ( $dhcp == "") {
		# austragen 
		$entrydhcp ['dhcphlpcont'] = array();
	   if ( $oldfixedaddress != "" ){
	      $entrydhcp ['dhcpoptfixed-address'] = array();
	   }
	   #if ( $oldrbs != "" ){
	   #   $entrydhcp ['hlprbservice'] = array();
	   #	 $entrydhcp ['dhcpoptfilename'] = array();
	   #	 $entrydhcp ['dhcpoptnext-server'] = array();
	   #}
	   echo "DHCP delete "; echo "<br>";
	   if ($result = ldap_mod_del($ds,$hostDN,$entrydhcp)){
	   	$dhcpchange = 1;
	   	$mesg = "Client erfolgreich aus dem zentralen DHCP ausgetragen.<br><br>";
	   }else{
	   	$mesg = "Fehler beim austragen aus dem zentralen DHCP Dienst!<br><br>";
	   }
	}
	elseif ( $olddhcp == "") {
		# eintragen
		$entrydhcp ['dhcphlpcont'] = $dhcp;
		if ( $hostip != "" ){
			$entrydhcp ['dhcpoptfixed-address'] = "ip";
		}
		echo "DHCP add "; print_r($entrydhcp); echo "<br>";
		if ($result = ldap_mod_add($ds,$hostDN,$entrydhcp)){
			$dhcpchange = 1;
			$mesg = "Client erfolgreich im zentralen DHCP Dienst eingetragen.<br><br>";
		}else{
			$mesg = "Fehler beim eintragen im zentralen DHCP Dienst!<br><br>";
		}
	}
}
else{
	#############################
	# DHCP Option fixed-address
	if ($fixedaddress != $oldfixedaddress){
	
		$entryfixadd ['dhcpoptfixed-address'] = $fixedaddress;
   	if ($result = ldap_mod_replace($ds,$hostDN,$entryfixadd)){
   	   $dhcpchange = 1;
   	   $mesg = "Option Fixed-Address erfolgreich auf <b>".$fixedaddress."</b> ge&auml;ndert<br><br>";
  		}else{
  		   $mesg = "Fehler beim &auml;ndern der Option Fixed-Address auf <b>".$fixedaddress."</b>!<br><br>";
  		}
	}
}

#############################
# DHCP / RBS
if ( $rbs != $oldrbs){
	if ( $rbs == "" ) {
	   $entryrbs ['hlprbservice'] = array();
	   $entryrbs ['dhcpoptnext-server'] = array();
	   $entryrbs ['dhcpoptfilename'] = array();
		if ($result = ldap_mod_del($ds,$hostDN,$entryrbs)){
	      $dhcpchange = 1;
	   	$mesg = "Rechner erfolgreich aus RBS gel&ouml;scht<br><br>";
	   }else{
	   	$mesg = "Fehler beim l&ouml;schen aus RBS!<br><br>";
	   }
	} else {
		$exprbs = ldap_explode_dn($rbs, 1);
		$dhcpdata = get_node_data($rbs,array("tftpserverip","initbootfile"));
	   $entryrbs ['hlprbservice'] = $rbs;
	   $entryrbs ['dhcpoptnext-server'] = $dhcpdata['tftpserverip'];
      $entryrbs ['dhcpoptfilename'] = $dhcpdata['initbootfile'];
		
		if ( $oldrbs == "" ) {
			if ($result = ldap_mod_add($ds,$hostDN,$entryrbs)){
   	      $dhcpchange = 1;
   	      rbs_adjust_host($hostDN, $rbs);
         	$mesg = "Remote Boot Service erfolgreich zu <b>".$exprbs[0]." [Abt.: ".$exprbs[2]."]</b> ge&auml;ndert<br><br>";
   	   }else{
   	      $mesg = "Fehler beim &auml;ndern des Remote Boot Services zu <b>".$exprbs[0]."</b>!<br><br>";
   	   }
		}	else {
			if ($result = ldap_mod_replace($ds,$hostDN,$entryrbs)){
      	   $dhcpchange = 1;
   	      rbs_adjust_host($hostDN, $rbs);
         	$mesg = "Remote Boot Service erfolgreich zu <b>".$exprbs[0]." [Abt.: ".$exprbs[2]."]</b> ge&auml;ndert<br><br>";
   	   }else{
   	      $mesg = "Fehler beim &auml;ndern des Remote Boot Services zu <b>".$exprbs[0]."</b>!<br><br>";
   	   }
		}
	}
}




#####################################
# Restliche Attribute ...

#if (count($atts) != 0){
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
			$dhcpchange = 1;
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
			$dhcpchange = 1;
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
			$dhcpchange = 1;
		}else{
			$mesg = "Fehler beim loeschen der Attribute ".$delatts."<br><br>";
		}
	}
	
#}

#####################

if ( $dhcpchange ){
	update_dhcpmtime($auDN);
}

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>