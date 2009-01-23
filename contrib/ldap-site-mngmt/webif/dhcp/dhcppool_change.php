<?php
include('../standard_header.inc.php');

$syntax = new Syntaxcheck;

$pooldn = $_POST['pooldn'];
$poolaudn = $_POST['poolaudn'];
#echo "POOL AUDN: $poolaudn <br><br>";
$subnet = $_POST['subnet'];
$subnetau = $_POST['subnetau'];
$subnetaudn = $_POST['subnetaudn'];

$subnetdn = $_POST['subnetdn'];
$oldsubnetdn = $_POST['oldsubnetdn'];
#echo "subnetdn: $subnetdn<br>";
#echo "oldsubnetdn: $oldsubnetdn<br>";
#$delpool = $_POST['delpool'];
$range1 = $_POST['range1'];
$range2 = $_POST['range2'];
$oldrange1 = $_POST['oldrange1'];
$oldrange2 = $_POST['oldrange2'];;
$addrange1 = $_POST['addrange1'];
$addrange2 = $_POST['addrange2'];
$pcl = $_POST['pcl'];
$oldpcl = $_POST['oldpcl'];
$rbs = $_POST['rbs'];
$oldrbs = $_POST['oldrbs'];

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

$mnr = $_POST['mnr'];
$backurl = $_POST['backurl'];


$range_delete = 0;
$dhcpchange = 0;
$seconds = 2;
$url = "dhcppool_one.php?dn=$pooldn&mnr=".$mnr."&url=".$backurl;
 
echo " 
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

#########################################################################################

#############################
# IP Range

/*
# Range hinzufügen
if ( $addrange1 != "" && $addrange2 != "" ){
   if ($syntax->check_ip_syntax($addrange1) && $syntax->check_ip_syntax($addrange2)){
   	$add1_long = ip2long($addrange1);
   	$add2_long = ip2long($addrange2);
   	if ( $add1_long <= $add2_long) {
      $net = strrev(strchr(strrev($subnet), "."));
      $add1 = strrev(strchr(strrev($addrange1), "."));
      $add2 = strrev(strchr(strrev($addrange2), "."));
      if ( $net == $add1 && $net == $add2 ){
         printf("Range %s -%s in %s0-Pool %s hinzuf&uuml;gen<br>",$addrange1,$addrange2,$net,$pooldn);
         # Range zusammenstellen
         $newrange = implode("_", array($addrange1,$addrange2));
         $result = add_dhcprange($newrange,$pooldn);
         if ($result){
				$dhcpchange = 1;
            printf("Neue dynamische IP Range %s - %s erfolgreich in Subnetz %s0 eingetragen!<br>",$addrange1,$addrange2,$net);
         }else{
            printf("<br>Fehler beim eintragen des dynamischen DHCP Pools!<br>");
         }
      }else{
         printf("Neue Range %s - %s nicht in Subnetz %s0<br>",$addrange1,$addrange2,$net);
      }
      }else{
      	printf("IP Range fehlerhaft: %s sollte kleiner sein als %s<br>",$addrange1,$addrange2);
      }
   }else{
      printf("falsche IP Syntax der neuen Range %s - %s<br>", $addrange1,$addrange2);
   }
}
*/


$range = implode('_',array($range1,$range2));
$oldrange = implode('_',array($oldrange1,$oldrange2));

if ( $oldrange1 != "" && $oldrange2 != "" && $range1 == "" && $range2 == "" ){
	
	$range_delete = 1;
	/*
   # Range löschen
   $addentry ['freeipblock'] = $oldrange;
   $delentry ['dhcpRange'] = $oldrange;
   print_r($addentry); echo "<br>";
   print_r($delentry); echo "<br>";
   
   $result1 = ldap_mod_del($ds,$pooldn,$delentry);
   if ($result1) {
   	$mesg .= "<br>IP Range $oldrange1[$i] - $oldrange2[$i] erfolgreich aus Pool gel&ouml;scht!<br>";
   	$result2 = ldap_mod_add($ds,$poolaudn,$addentry);
   	if ($result2) {
   		merge_ipranges($poolaudn);
   		$mesg .= "<br>geloeschte IP Range erfolgreich als neuer FIPB in die AU eingetragen!<br>";
   		$dhcpchange = 1;
   	}else{
   		$mesg .= "Fehler beim eintragen als neuer FIPB!";
   		ldap_mod_add($ds,$pooldn,$delentry);
   	}
   }else{
   	$mesg .= "Fehler beim l&ouml;schen der Pool IP Range $oldrange1[$i] - $oldrange2[$i]";
   }*/
}
elseif ( $oldrange1 != "" && $oldrange2 != "" && $range1 != "" && $range2 != "" ){
	
	if ($syntax->check_ip_syntax($range1) && $syntax->check_ip_syntax($range2)){
	
		$or1 = ip2long($oldrange1);
		$or2 = ip2long($oldrange2);
		$nr1 = ip2long($range1);
		$nr2 = ip2long($range2);
		if ( $nr2 >= $nr1 ) {
			# korrekte IP Range
			$modentry ['dhcpRange'] = $range;
	
			if ( ($nr1 > $or1 || $nr2 < $or2) && !($nr1 < $or1 || $nr2 > $or2) ){
		   
			   # Range verkleinern
			   $diffrange = split_iprange($range,$oldrange);
		      echo "<br>verkleinern - diffrange: "; print_r($diffrange); echo "<br>";
	
				if ( $modresult = ldap_mod_replace($ds,$pooldn,$modentry) ) {
						$new_fipbs = array();
	         		#if (count($diffrange > 1) {
	         		foreach ($diffrange as $dr){
	           			 $new_fipbs ['freeipblock'][] = $dr;
	        			}
	         		$result = ldap_mod_add($ds,$poolaudn,$new_fipbs);
	         		merge_ipranges($poolaudn);
						printf("IP Range erfolgreich verkleinert auf $range1 - $range2");
				}else{
	         	printf("Fehler beim L&ouml;schen von "); print_r($delentry);
	         }
	      
			}
			elseif( ($nr1 < $or1 || $nr2 > $or2) && !($nr1 > $or1 || $nr2 < $or2) ){
			   # Range vergrößern 
			   $expandrange_array = split_iprange($oldrange,$range);
			   printf("vergroessern - addrange: "); 
			   print_r($expandrange_array); echo "<br>";
			   
			   foreach ($expandrange_array as $addrange) {
			   	$result = add_dhcprange($addrange,$pooldn);
	      		if ($result){
						$dhcpchange = 1;
						printf("Dynamische IP Range erfolgreich auf %s - %s erweitert!<br>",$range1,$range2);
			   	}else{
	     	 	   	echo "<br>Fehler beim erweitern der dynamischen DHCP Pools!<br>";
	      		} 
	      	}
			}
		}else{
			printf("Neue IP Range nicht korrekt: %s sollte kleiner sein als %s<br>",$range1[$i],$range2[$i]);
		}
	}else{
      printf("falsche IP Syntax der neuen Range %s - %s<br>", $range1[$i],$range2[$i]);
   }
}



#############################
# Permitted Pool Clients
if ( $pcl != $oldpcl ) {
	if ($pcl == "") {
		$pclmodentry ['dhcppermittedclients'] = array();
		if ( ldap_mod_del($ds,$pooldn,$pclmodentry) ){
			printf("Zugelassene Pool Clients auf <b>%s</b> gesetzt<br><br>",$pcl);
			$dhcpchange = 1;
		}
	}
	elseif ( $oldpcl == "" ) {
		$pclmodentry ['dhcppermittedclients'] = $pcl;
		if ( ldap_mod_add($ds,$pooldn,$pclmodentry) ){
			printf("Zugelassene Pool Clients auf <b>%s</b> gesetzt<br><br>",$pcl);
			$dhcpchange = 1;
		}
	}
}

#####################################
# DHCP Pool (De)Aktivierung 

if ( $subnetdn != $oldsubnetdn ){
   
   if ( !$oldsubnetdn ){
   	$entrysv ['dhcphlpcont'] = $subnetdn;
   	if(ldap_mod_add($ds,$pooldn,$entrysv)){
   		$dhcpchange = 1;
   		$mesg = "Pool erfolgreich im DHCP Subnet eingetragen (aktiviert)<br><br>";
   	}else{
   		$mesg = "Fehler beim eintragen des Pools.<br><br>";
   	}
   }
   elseif( !$subnetdn ){
   	$entrysv ['dhcphlpcont'] = array();
   	if(ldap_mod_del($ds,$pooldn,$entrysv)){
   		$dhcpchange = 1;
   		$mesg = "Pool erfolgreich aus DHCP Subnet ausgetragen (deaktiviert)<br><br>";
   	}
   	else{
   		$mesg = "Fehler beim austragen des Pools!<br><br>";
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
		if ($result = ldap_mod_del($ds,$pooldn,$entryrbs)){
	      $dhcpchange = 1;
	   	$mesg .= "Pool erfolgreich aus RBS gel&ouml;scht<br><br>";
	   }else{
	   	$mesg .= "Fehler beim l&ouml;schen aus RBS!<br><br>";
	   }
	} else {
		$exprbs = ldap_explode_dn($rbs, 1);
		$dhcpdata = get_node_data($rbs,array("tftpserverip","initbootfile"));
	   $entryrbs ['hlprbservice'] = $rbs;
	   $entryrbs ['dhcpoptnext-server'] = $dhcpdata['tftpserverip'];
      $entryrbs ['dhcpoptfilename'] = $dhcpdata['initbootfile'];
		
		if ( $oldrbs == "" ) {
			if ($result = ldap_mod_add($ds,$pooldn,$entryrbs)){
   	      $dhcpchange = 1;
         	$mesg .= "Remote Boot Service erfolgreich zu <b>".$exprbs[0]." [Abt.: ".$exprbs[2]."]</b> ge&auml;ndert<br><br>";
   	   }else{
   	      $mesg .= "Fehler beim &auml;ndern des Remote Boot Services zu <b>".$exprbs[0]."</b>!<br><br>";
   	   }
		}	
		else {
			$result = ldap_mod_replace($ds,$pooldn,$entryrbs);
			if ($result){
      	   $dhcpchange = 1;
         	$mesg .= "Remote Boot Service erfolgreich zu <b>".$exprbs[0]." [Abt.: ".$exprbs[2]."]</b> ge&auml;ndert<br><br>";
   	   }else{
   	      $mesg .= "Fehler beim &auml;ndern des Remote Boot Services zu <b>".$exprbs[0]."</b>!<br><br>";
   	   }
		}
	}
}


#################################################
# Restliche Attribute (Lease Times, Description)
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
	if(ldap_mod_add($ds,$pooldn,$entryadd)){
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
	if(ldap_mod_replace($ds,$pooldn,$entrymod)){
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
	if(ldap_mod_del($ds,$pooldn,$entrydel)){
		$dhcpchange = 1;
		$mesg .= "Attribute ".$delatts." erfolgreich geloescht<br>";
	}else{
		$mesg .= "Fehler beim loeschen der Attribute ".$delatts."<br>";
	}
}



#########################################################################################

if ( $dhcpchange ){
	update_dhcpmtime($subnetaudn);
}

if ($range_delete) {
	echo "Eine IP Range ist notwendig in einem dynamischen DHCP Pool.<br>
			Wollen Sie stattdessen den dynamischen Pool $oldrange1 - $oldrange2 l&ouml;schen?<br><br>
			
			<form action='dhcppool_delete.php' method='post'>
				Ja:<br><br>
				<input type='hidden' name='dn' value='".$pooldn."'>			
				<input type='hidden' name='name' value='Pool'>
				<input type='hidden' name='subnetaudn' value='".$subnetaudn."'>
				<input type='hidden' name='mnr' value='".$mnr."'>
				<input type='Submit' name='apply' value='l&ouml;schen' class='small_loginform_button'><br><br>
			</form>
			<br>
			<form action='".$url."' method='post'>
				nein:<br><br>
				<input type='Submit' name='apply' value='zur&uuml;ck' class='small_loginform_button'>
			</form> 
			";
}else{
	$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
				Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
	redirect($seconds, $url, $mesg, $addSessionId = TRUE);
}

echo "</td></tr></table></body>
</html>";
?>