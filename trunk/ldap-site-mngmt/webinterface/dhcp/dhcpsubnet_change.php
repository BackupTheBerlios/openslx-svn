<?php
include('../standard_header.inc.php');

$syntax = new Syntaxcheck;

$cn = $_POST['cn'];
$oldcn = $_POST['oldcn'];
$netmask = $_POST['netmask'];
$oldnetmask = $_POST['oldnetmask'];
$dhcpservice = $_POST['dhcpservice'];
$olddhcpservice = $_POST['olddhcpservice'];
$newrange1 = $_POST['range1'];
$oldrange1 = $_POST['oldrange1'];
$newrange2 = $_POST['range2'];
$oldrange2 = $_POST['oldrange2'];

$subnetDN = $_POST['subnetdn'];

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

$seconds = 200;
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
   	print_r($newsubnetDN); echo "<br><br>";
   	
   	if(modify_subnet_dn($subnetDN,$newsubnetDN)){
   		$subnetDN = $newsubnetDN;
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
   
   if ( $netmask == ""){
      echo "Die Subnetzmaske ist ein notwendiges Attribut.<br>
            Keine &Auml;nderung!<br>";
   }
  
   if ( $netmask != "" ){
      if ( $syntax->check_ip_syntax($netmask) ){
      	$entry ['dhcpoptnetmask'] = $netmask;
      	if(ldap_mod_replace($ds,$subnetDN,$entry)){
      		$mesg = "Netzmaske erfolgreich ge&auml;ndert<br><br>";
      	}else{
      		$mesg = "Fehler beim &auml;ndern der Netzmaske!<br><br>";
      	}
   	}else{
	      $mesg = "falsche IP Syntax<br>";
	   }
   }
   
}


#####################################
# DHCP Dienstzuordnung ändern 

if ( $dhcpservice != "none" ){
   
   if ( $dhcpservice != "off" && $dhcpservice == $olddhcpservice ){
   	$mesg = "Sie haben die gleiche Abteilung ausgew&auml;hlt<br>
   				Keine &Auml;nderung!";
   }
   
   if ( $dhcpservice != "off" && $dhcpservice != $olddhcpservice ){
   	$entrysv ['dhcphlpcont'] = $dhcpservice;
   	if(ldap_mod_replace($ds,$subnetDN,$entrysv)){
   		$mesg = "DHCP Dienstzuordnung erfolgreich ge&auml;ndert<br><br>";
   	}
   	else{
   		$mesg = "Fehler beim &auml;ndern der DHCP Dienstzuordnung!<br><br>";
   	}
   }
   
   if ( $dhcpservice == "off" && $olddhcpservice != "" ){
      $entrysv ['dhcphlpcont'] = array();
   	if(ldap_mod_del($ds,$subnetDN,$entrysv)){
   		$mesg = "DHCP Dienstzuordnung erfolgreich ge&auml;ndert<br><br>";
   	}
   	else{
   		$mesg = "Fehler beim &auml;ndern der DHCP Dienstzuordnung!<br><br>";
   	}
   }
   
}


#####################################
# DHCP Range

if ( $newrange1 == $oldrange1 && $newrange2 == $oldrange2 ){
	# $mesg = "keine Aenderung<br>";
}else{

   if ( $newrange1 == "" xor $newrange2 == "" ){
   	$mesg = "Bitte beide DHCP Range Felder ausf&uuml;llen, keine Aenderung<br>";
   }
   
   if ( $oldrange1 == "" && $oldrange2 == "" && $newrange1 != "" && $newrange2 != "" ){
      if ( $syntax->check_ip_syntax($newrange1) && $syntax->check_ip_syntax($newrange2) ){
         if ( check_ip_in_subnet($newrange1,$cn) && check_ip_in_subnet($newrange2,$cn)){
            $dhcprange = implode('_',array($newrange1,$newrange2));
            if ( new_ip_dhcprange($dhcprange,$subnetDN,$auDN) ){
               $mesg = "DHCP Range erfolgreich eingetragen";
            }else{
               $mesg = "Fehler beim eintragen der DHCP Range";
            }
         }else{
            $mesg = "DHCP Range nicht in Subnetz ".$cn." enthalten";
         }
      }else{
         $mesg = "falsche IP Syntax<br>";
      }
   }
   
   if ( $oldrange1 != "" && $oldrange2 != "" && $newrange1 != "" && $newrange2 != "" ){
      if ( $syntax->check_ip_syntax($newrange1) && $syntax->check_ip_syntax($newrange2) ){
         if ( check_ip_in_subnet($newrange1,$cn) && check_ip_in_subnet($newrange2,$cn)){
            $dhcprange = implode('_',array($newrange1,$newrange2));
            $olddhcprange = implode('_',array($oldrange1,$oldrange2));
            if ( modify_ip_dhcprange($dhcprange,$subnetDN,$auDN) ){
               $mesg = "DHCP Range erfolgreich ge&auml;ndert";
            }else{
               $mesg = "Fehler beim &auml;ndern der DHCP Range";
               # alte Range wiederherstellen 
      		   new_ip_dhcprange($olddhcprange,$subnetDN,$auDN);
            }
         }else{
            $mesg = "DHCP Range nicht in Subnetz ".$cn." enthalten";
         }
      }else{
         $mesg = "falsche IP Syntax<br>";
      }
   }
   
   if ( $newrange1 == "" && $newrange2 == "" ){
   	if ( delete_ip_dhcprange($subnetDN,$auDN) ){
   	   $mesg = "DHCP Range erfolgreich gel&ouml;scht";
      }else{
         $mesg = "Fehler beim l&ouml;schen der DHCP Range";
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
	if(ldap_mod_add($ds,$subnetDN,$entryadd)){
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
	if(ldap_mod_replace($ds,$subnetDN,$entrymod)){
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
	if(ldap_mod_del($ds,$subnetDN,$entrydel)){
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