<?php
include('../standard_header.inc.php');

$syntax = new Syntaxcheck;

$range1 = $_POST['addrange1'];
$range2 = $_POST['addrange2'];
$pcl = $_POST['pcl'];
$unknownclients = $_POST['unknownclients'];
$rbs = "";
$mnr = $_POST['mnr'];

$poolopt_domain = "";

$seconds = 2;
$url = "dhcppools.php?mnr=".$mnr;
 
echo "
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ($syntax->check_ip_syntax($range1) && $syntax->check_ip_syntax($range2)){
   
   $fs = explode('.',$range1);
   $fe = explode('.',$range2);
   if ( $fs[0] == $fe[0] && $fs[1] == $fe[1] && $fs[2] == $fe[2] ) {
      if ( $fs[3] <= $fe[3] ){
		   
         # DHCP Subnet DN finden
			$subnet = implode(".", array($fs[0],$fs[1],$fs[2],"0"));
			if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(&(objectclass=dhcpSubnet)(cn=$subnet))", array("dn","dhcphlpcont"), "", "sub", 0, 0))) {
       		# redirect(5, "", $ldapError, FALSE);
        		echo "no search"; 
        		die;
      	}
      	$result = ldapArraySauber($result);
      	#print_r($result);echo "<br><br>";
         if (count($result[0]) != 0){
				
				$subnetdn = $result[0]['dn'];
				$subnetau = get_audn_of_objectdn($subnetdn);
				
				$subnet_data = get_node_data($subnetdn, array("dhcpoptdomain-name"));
				if ($subnet_data['dhcpoptdomain-name'] != $assocdom) {
					$poolopt_domain = $assocdom;
					echo "Pool spezifische Option <b>domain-name</b> auf <b>".$assocdom."</b> gesetzt<br>";
				}
				      	
            # Range zusammenstellen
            $range = implode("_", array($range1,$range2));
            
            # Freie IP Bereiche testen
            $ipmatch = 0;
            $fipb_array = get_freeipblocks_au($auDN);
            #echo "<br>FIPB: <br>";print_r($fipb_array);echo "<br>";
         	for ($i=0; $i < count($fipb_array); $i++){
         		if ( split_iprange($range,$fipb_array[$i]) != 0 ){
         			$ipranges = split_iprange($range,$fipb_array[$i]);
         			array_splice($fipb_array, $i, 1, $ipranges);
         			$ipmatch = 1;
         			break;
         		}		
         	}
				#echo "<br>FIPB: <br>";print_r($fipb_array);echo "<br>";
         	if ( $ipmatch ){
         		
         		if ($fipb_array){
	         		foreach ( $fipb_array as $item ){
   	      		 	$entry ['FreeIPBlock'][] = $item;
      	   		}
      	   	}else{
      	   		$entry ['FreeIPBlock'] = array();
      	   	}
         		# poolaudn .vs. auDN
         		$results = ldap_mod_replace($ds,$auDN,$entry);
         		if ($results){
         			#echo "<br>Neue FIPBs erfolgreich eingetragen!<br>";
         			$result = add_dhcppool($subnetdn,$range,$pcl,$result[0]['dhcphlpcont'],$poolopt_domain,$rbs);
         			if ($result){
         				echo "<br>Dynamischer DHCP Pool erfolgreich eingetragen!<br>" ;
         				update_dhcpmtime($subnetau);
         	   	}else{
         	   		echo "<br>Fehler beim eintragen des dynamischen DHCP Pools!<br>";
         	   		# Range wieder in FIPBs aufnehmen.
         	   		$entry2 ['FreeIPBlock'] = $range;
         	   		ldap_mod_add($ds,$auDN,$entry2);
         	   		merge_ipranges($auDN);
         	   	} 
         		}else{
         	   	echo "<br>Fehler beim anpassen der freien IP Bereiche!<br>Pool nicht angelegt!<br><br>";
         	   }		
         	}else{
         		printf("<br>IP Range %s ist nicht im verfuegbaren Bereich!!<br>Pool nicht angelegt!<br><br>", $range );
         	}
      	}else{
   	      echo "DHCP Subnet $subnet nicht im System eingetragen!<br>Pool nicht angelegt!<br><br>";
   	   }
      }else{
         echo "erste Range IP gr&ouml;sser als zweite Range IP!<br>Pool nicht angelegt!<br><br>";
      }	
   }else{
      echo "Range nicht in einem Subnetz!<br>Pool wird nicht angelegt!<br><br>";
   }
}else{
   echo "falsche IP Syntax!<br>Pool wird nicht angelegt!<br><br>";
}

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>