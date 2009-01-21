<?php
include('../standard_header.inc.php');

$syntax = new Syntaxcheck;

$range1 = $_POST['addrange1'];
$range2 = $_POST['addrange2'];
$unknownclients = $_POST['unknownclients'];
$mnr = $_POST['mnr'];

$seconds = 2;
$url = "dhcppool.php?mnr=".$mnr;
 
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
			print_r($subnet);echo"<br><br>";
			if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(&(objectclass=dhcpSubnet)(cn=$subnet))", array("dn","dhcphlpcont"), "", "sub", 0, 0))) {
       		# redirect(5, "", $ldapError, FALSE);
        		echo "no search"; 
        		die;
      	}
      	$result = ldapArraySauber($result);
      	#print_r($result);echo "<br><br>";
         if (count($result[0]) != 0){
				
				$subnetdn = $result[0]['dn'];
				$subnetdnexp = ldap_explode_dn( $subnetdn, 0);
				$subnetauexp = array_slice($subnetdnexp, 3);
				$subnetau = implode(',',$subnetauexp);
				         	
            # Range zusammenstellen
            $range = implode("_", array($range1,$range2));
            
            # Freie IP Bereiche testen
            $fipb_array = get_freeipblocks_au($auDN);
         	for ($i=0; $i < count($fipb_array); $i++){
         		if ( split_iprange($range,$fipb_array[$i]) != 0 ){
         			$ipranges = split_iprange($range,$fipb_array[$i]);
         			array_splice($fipb_array, $i, 1, $ipranges);
         			break;
         		}		
         	}
         	if ($i < count($fipb_array) ){	
         		foreach ( $fipb_array as $item ){
         		 	$entry ['FreeIPBlock'][] = $item;
         		}
         		$results = ldap_mod_replace($ds,$auDN,$entry);
         		if ($results){
         			echo "<br>Neue FIPBs erfolgreich eingetragen!<br>";
         			$result = add_dhcppool($subnetdn,$range,$unknownclients,$result[0]['dhcphlpcont']);         			
         			if ($result){
         				echo "<br>Dynamischer DHCP Pool erfolgreich eingetragen!<br>" ;
         				update_dhcpmtime(array($subnetau));
         	   	}else{
         	   		echo "<br>Fehler beim eintragen des dynamischen DHCP Pools!<br>";
         	   		# Range wieder in FIPBs aufnehmen.
         	   		$entry2 ['FreeIPBlock'] = $range;
         	   		ldap_mod_add($ds,$auDN,$entry2);
         	   		merge_ipranges($auDN);
         	   	} 
         		}else{
         	   	echo "<br>Fehler beim eintragen der FIPBs!<br>";
         	   }	  		
         	}else{
         		printf("<br>IP Range %s ist nicht im verfuegbaren Bereich!<br>", $range );
         	}
      	}else{
   	      echo "DHCP Subnet nicht im System vorhanden!<br>";
   	   }	
      }else{
         echo "erster Range Wert gr&ouml;sser als zweiter Range Wert<br>";
      }	
   }else{
      echo "Range nicht im gleichen Subnetz<br>";
   }
}else{
   echo "falsche IP Syntax<br>";
}

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>