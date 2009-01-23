<?php
include('../standard_header.inc.php');

$syntax = new Syntaxcheck;

$subnetDN = $_POST['subnetdn'];
$subnetaudn = $_POST['subnetaudn'];

$cn = $_POST['cn'];
$oldcn = $_POST['oldcn'];
$netmask = $_POST['netmask'];
$oldnetmask = $_POST['oldnetmask'];
$dhcpservice = $_POST['dhcpservice'];
$olddhcpservice = $_POST['olddhcpservice'];
#$get_lease_hostnames = $_POST['get-lease-hostnames'];
#$oldget_lease_hostnames = $_POST['oldget-lease-hostnames'];
$pcl = $_POST['pcl'];
$oldpcl = $_POST['oldpcl'];

$rbsself = $_POST['rbsself'];
$rbs = $_POST['rbs'];
$oldrbs = $_POST['oldrbs'];

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

$nodeDN = "cn=dhcp,".$auDN;
$mnr = $_POST['mnr'];
$sbmnr = $_POST['sbmnr'];
$mcnr = $_POST['mcnr'];

$dhcpchange = 0;
$seconds = 2;
$url = "dhcpsubnet.php?dn=".$subnetDN."&mnr=".$mnr."&sbmnr=".$sbmnr;
 
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
# DHCP Subnet CN (DN) 

if ( $oldcn == $cn ){
	# $mesg = "keine Aenderung<br>";
}

if ( $oldcn != "" && $cn != "" && $oldcn != $cn ){
	
	if ( $syntax->check_netip_syntax($cn) ){
	   echo "Subnetz aendern<br>";
   	$newsubnetDN = "cn=".$cn.",".$nodeDN;
   	#print_r($newsubnetDN); echo "<br><br>";
   	
   	if(modify_subnet_dn($subnetDN,$newsubnetDN)){
   		$subnetDN = $newsubnetDN;
   		$dhcpchange = 1;
   		$mesg = "DHCP Subnet erfolgreich ge&auml;ndert<br><br>";
   		$url = "dhcpsubnet.php?dn=".$subnetDN."&mnr=".$mnr."&sbmnr=".$sbmnr;
   	}else{
   		$mesg = "Fehler beim &auml;ndern des DHCP Subnets!<br><br>";
   	}	
	}else{
	   $mesg = "falsche IP Syntax<br>";
	}
}

if ( $oldcn != "" && $cn == "" ){
	echo "DHCP Subnet loeschen!<br> 
			Dieser ist Teil des DN, Sie werden den DHCP Subnet komplett l&ouml;schen<br><br>";
	echo "Wollen Sie den DHCP Subnet <b>".$oldcn."</b> wirklich l&ouml;schen?<br><br>
			<form action='dhcpsubnet_delete.php' method='post'>
				Falls ja:<br><br>
				<input type='hidden' name='dn' value='".$subnetDN."'>
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
# Netmask

if ( $netmask != $oldnetmask ){
	
   if ( $netmask ){
      if ( $syntax->check_ip_syntax($netmask) ){
      	$entry ['dhcpoptnetmask'] = $netmask;
      	if(ldap_mod_replace($ds,$subnetDN,$entry)){
      		$mesg = "Netzmaske erfolgreich ge&auml;ndert<br><br>";
      		$dhcpchange = 1;
      	}else{
      		$mesg = "Fehler beim &auml;ndern der Netzmaske!<br><br>";
      	}
   	}else{
	      $mesg = "falsche IP Syntax<br>";
	   }
   }else{
      echo "Die Subnetzmaske ist ein notwendiges Attribut.<br>
            Keine &Auml;nderung!<br>";
   }
}


#####################################
# DHCP Dienstzuordnung ändern 

if ( $dhcpservice != $olddhcpservice ){
   
   if ( !$olddhcpservice ){
   	$entrysv ['dhcphlpcont'] = $dhcpservice;
   	if(ldap_mod_add($ds,$subnetDN,$entrysv)){
   		$dhcpchange = 1;
   		$mesg = "Subnetz erfolgreich im DHCP Dienst eingetragen<br><br>";
   	}else{
   		$mesg = "Fehler beim eintragen des Subnetzes im DHCP Dienst.<br><br>";
   	}
   }
   elseif( !$dhcpservice ){
   	$entrysv ['dhcphlpcont'] = array();
   	if(ldap_mod_del($ds,$subnetDN,$entrysv)){
   		$dhcpchange = 1;
   		$mesg = "Subnetz erfolgreich aus DHCP Dienst ausgetragen<br><br>";
   	}
   	else{
   		$mesg = "Fehler beim austragen des Subnetzes aus dem DHCP Dienst!<br><br>";
   	}
   }
}



#####################################
# Radio Button Attribute (u.a. )
/*
if ( $get_lease_hostnames == $oldget_lease_hostnames ) {
	# keine Änderung
}else{
	switch ( $get_lease_hostnames ){
	case $get_lease_hostnames == 'on':
		$entryadd_glh ['dhcpoptget-lease-hostnames'] = "on";
		if(ldap_mod_add($ds,$subnetDN,$entryadd_glh)){
			$mesg = "Attribut <b>get-lease-hostnames</b> erfolgreich eingetragen<br><br>";
		}else{
			$mesg = "Fehler beim eintragen des Attributs <b>get-lease-hostnames</b>!<br><br>";
		}
		break;
	case $get_lease_hostnames == 'off':
		$entrydel_glh ['dhcpoptget-lease-hostnames'] = array();
		if(ldap_mod_del($ds,$subnetDN,$entrydel_glh)){
   		$mesg = "Attribut <b>get-lease-hostnames</b> erfolgreich gel&ouml;scht<br><br>";
   	}
   	else{
   		$mesg = "Fehler beim l&ouml;schen des Attributs <b>get-lease-hostnames</b>!<br><br>";
   	}
		break;
	}
}
*/

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
#print_r($entryadd); echo "<br>";
#print_r($entrymod); echo "<br>";
#print_r($entrydel); echo "<br>";

if (count($entryadd) != 0 ){
	#print_r($entryadd); echo "<br>";
	#echo "neu anlegen<br>"; 
	foreach (array_keys($entryadd) as $key){
		$addatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_add($ds,$subnetDN,$entryadd)){
		$dhcpchange = 1;
		$mesg .= "Attribute ".$addatts." erfolgreich eingetragen<br>";
	}else{
		$mesg .= "Fehler beim eintragen der Attribute ".$addatts."<br>";
	}
}

if (count($entrymod) != 0 ){
	#print_r($entrymod); echo "<br>";
	#echo "&auml;ndern<br>";
	foreach (array_keys($entrymod) as $key){
		$modatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_replace($ds,$subnetDN,$entrymod)){
		$dhcpchange = 1;
		$mesg .= "Attribute ".$modatts." erfolgreich geaendert<br>";
	}else{
		$mesg .= "Fehler beim aendern der Attribute ".$modatts."<br>";
	}
}

if (count($entrydel) != 0 ){
	#print_r($entrydel); echo "<br>";
	#echo "l&ouml;schen<br>";
	foreach (array_keys($entrydel) as $key){
		$delatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_del($ds,$subnetDN,$entrydel)){
		$dhcpchange = 1;
		$mesg .= "Attribute ".$delatts." erfolgreich geloescht<br>";
	}else{
		$mesg .= "Fehler beim loeschen der Attribute ".$delatts."<br>";
	}
}

#############################
# Permitted Pool Clients

if ( $pcl != $oldpcl ) {
	if ($pcl == "") {
		$pclmodentry ['dhcppermittedclients'] = array();
		if ( ldap_mod_del($ds,$subnetDN,$pclmodentry) ){
			printf("Zugelassene Subnet Clients auf <b>%s</b> gesetzt<br><br>",$pcl);
			$dhcpchange = 1;
		}
	}
	elseif ( $oldpcl == "" ) {
		$pclmodentry ['dhcppermittedclients'] = $pcl;
		if ( ldap_mod_add($ds,$subnetDN,$pclmodentry) ){
			printf("Zugelassene Subnet Clients auf <b>%s</b> gesetzt<br><br>",$pcl);
			$dhcpchange = 1;
		}
	}
}


#############################
# DHCP / RBS
if ( $rbs != $oldrbs){
	if ( $rbs == "" ) { 
	#if ( $rbs == "" && $rbsself != "" ) { # falls rbs aus parentscope -> kann nicht gelöscht werden...
	   $entryrbs ['hlprbservice'] = array();
	   $entryrbs ['dhcpoptnext-server'] = array();
	   $entryrbs ['dhcpoptfilename'] = array();
		if ($result = ldap_mod_del($ds,$subnetDN,$entryrbs)){
	      $dhcpchange = 1;
	   	$mesg = "Subnet erfolgreich aus RBS gel&ouml;scht<br><br>";
	   }else{
	   	$mesg = "Fehler beim l&ouml;schen aus RBS!<br><br>";
	   }
	} else {
		$exprbs = ldap_explode_dn($rbs, 1);
		$dhcpdata = get_node_data($rbs,array("tftpserverip","initbootfile"));
	   $entryrbs ['hlprbservice'] = $rbs;
	   $entryrbs ['dhcpoptnext-server'] = $dhcpdata['tftpserverip'];
      $entryrbs ['dhcpoptfilename'] = $dhcpdata['initbootfile'];
		
		if ( $oldrbs == "" ) { # hier ist rbsself immer ""
			if ($result = ldap_mod_add($ds,$subnetDN,$entryrbs)){
   	      $dhcpchange = 1;
         	$mesg = "Remote Boot Service erfolgreich zu <b>".$exprbs[0]." [Abt.: ".$exprbs[2]."]</b> ge&auml;ndert<br><br>";
   	   }else{
   	      $mesg = "Fehler beim &auml;ndern des Remote Boot Services zu <b>".$exprbs[0]."</b>!<br><br>";
   	   }
		}	
		else {
			#if ($rbsself == "") {
			#	$result = ldap_mod_add($ds,$subnetDN,$entryrbs);
			#}else{
				$result = ldap_mod_replace($ds,$subnetDN,$entryrbs);
			#}
			if ($result){
      	   $dhcpchange = 1;
         	$mesg = "Remote Boot Service erfolgreich zu <b>".$exprbs[0]." [Abt.: ".$exprbs[2]."]</b> ge&auml;ndert<br><br>";
   	   }else{
   	      $mesg = "Fehler beim &auml;ndern des Remote Boot Services zu <b>".$exprbs[0]."</b>!<br><br>";
   	   }
		}
	}
}


###########
if ( $dhcpchange ){
	update_dhcpmtime($subnetaudn);
}

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>