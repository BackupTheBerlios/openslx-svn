<?php
include('../standard_header.inc.php');

$syntax = new Syntaxcheck;

$hostip = $_POST['hostip'];

$rbs = $_POST['rbs'];
$oldrbs = $_POST['oldrbs'];

$hostDN = $_POST['hostdn'];
$sbmnr = $_POST['sbmnr'];

$rbs = htmlentities($rbs);
$oldrbs = htmlentities($oldrbs);


/*echo "new dhcp:"; print_r($dhcp); echo "<br>";
echo "old dhcp:"; print_r($olddhcp); echo "<br>";
echo "new rbs:"; print_r($rbs); echo "<br>";
echo "old rbs:"; print_r($oldrbs); echo "<br>";
echo "Host DN:"; print_r($hostDN); echo "<br>";
echo "submenuNR:"; print_r($sbmnr); echo "<br><br>";*/


$seconds = 2;
$url = 'rbshost.php?dn='.$hostDN.'&sbmnr='.$sbmnr;
 
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
# RBS

if ($rbs != "none" && $rbs != $oldrbs){
   if ($rbs != ""){
   	$exp = ldap_explode_dn($rbs, 1);
	   $rbscn = $exp[0];
	   $rbsau = $exp[2];
	   
	   $dhcpdata = get_node_data($rbs,array("tftpserverip","initbootfile"));
	   $entryrbs ['hlprbservice'] = $rbs;
	   $entryrbs ['dhcpoptnext-server'] = $dhcpdata['tftpserverip'];
      $entryrbs ['dhcpoptfilename'] = $dhcpdata['initbootfile'];
	   if ($oldrbs != ""){
	      echo "RBS replace "; print_r($oldrbs); echo " with "; print_r($entryrbs); echo "<br>";
   	   if ($result = ldap_mod_replace($ds,$hostDN,$entryrbs)){
      	   update_dhcpmtime();
   	      rbs_adjust_host($hostDN, $rbs);
         	$mesg = "Remote Boot Service erfolgreich zu <b>".$rbscn." [Abt.: ".$rbsau."]</b> ge&auml;ndert<br><br>";
   	   }else{
   	      $mesg = "Fehler beim &auml;ndern des Remote Boot Services zu <b>".$rbscn."</b>!<br><br>";
   	   }
   	}else{
   	   echo "RBS add "; print_r($entryrbs); echo "<br>";
   	   if ($result = ldap_mod_add($ds,$hostDN,$entryrbs)){
   	      update_dhcpmtime();
   	      rbs_adjust_host($hostDN, $rbs);
         	$mesg = "Remote Boot Service erfolgreich zu <b>".$rbscn." [Abt.: ".$rbsau."]</b> ge&auml;ndert<br><br>";
   	   }else{
   	      $mesg = "Fehler beim &auml;ndern des Remote Boot Services zu <b>".$rbscn."</b>!<br><br>";
   	   }
   	}
	}else{
	   $entryrbs ['hlprbservice'] = array();
	   $entryrbs ['dhcpoptnext-server'] = array();
	   $entryrbs ['dhcpoptfilename'] = array();
	   echo "RBS delete "; echo "<br>";
	   if ($result = ldap_mod_del($ds,$hostDN,$entryrbs)){
	      update_dhcpmtime();
	   	$mesg = "Rechner erfolgreich aus RBS gel&ouml;scht<br><br>";
	   }else{
	   	$mesg = "Fehler beim l&ouml;schen aus RBS!<br><br>";
	   }
	}
}
if ($rbs == "none"){
   echo "RBS none <br>";
}


#####################

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>