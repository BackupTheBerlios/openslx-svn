<?php
include('../standard_header.inc.php');

$syntax = new Syntaxcheck;

$pooldn = $_POST['pooldn'];
$subnet = $_POST['subnet'];
$subnetau = $_POST['subnetau'];
$delpool = $_POST['delpool'];
$poolranges = array();
foreach ($pooldn as $dn){
   $poolranges [$dn] = get_dhcppoolranges($dn);
}
$range1 = $_POST['range1'];
$range2 = $_POST['range2'];
$oldrange1 = $_POST['oldrange1'];
$oldrange2 = $_POST['oldrange2'];
$rangepooldn = $_POST['rangepooldn'];
$addrange1 = $_POST['addrange1'];
$addrange2 = $_POST['addrange2'];
$uc = $_POST['unknownclients'];
$olduc = $_POST['olduc'];

$rbs = $_POST['rbs'];
$oldrbs = $_POST['oldrbs'];

# Array to fill with AUs to update dhcpMTime
$au_to_update = array();

$mnr = $_POST['mnr'];

#print_r($pooldn); echo "<br>";
#print_r($subnet); echo "<br>";
#print_r($subnetau); echo "<br>";
#print_r($delpool); echo "<br><br>";
#print_r($oldrange1); echo "<br>"; 
#print_r($oldrange2); echo "<br>";
#print_r($range1); echo "<br>";
#print_r($range2); echo "<br>";
#print_r($rangepooldn); echo "<br><br>";
#print_r($addrange1); echo "<br>";
#print_r($addrange2); echo "<br><br>";
#print_r($olduc); echo "<br><br>";
#print_r($uc); echo "<br><br>";

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

#########################################################################################
# Pools löschen, entsprechende Arrays ($pooldn, $uc, ...) zur weiteren Verarbeitung anpassen
for ($i=0;$i<count($delpool);$i++){
   
   $key = array_keys ( $pooldn, $delpool[$i] );
   $key_r = array_keys ( $rangepooldn, $delpool[$i] );
   
   # Ranges wieder in FIPBs aufnehmen
   if (count($key_r) > 1){
      foreach ($key_r as $item){
         $modentry['FreeIPBlock'][] = $oldrange1[$item]."_".$oldrange2[$item];
      }
   }else{
      $modentry['FreeIPBlock'] = $oldrange1[$key_r[0]]."_".$oldrange2[$key_r[0]];
   }
   print_r($modentry); echo "<br><br>";
   $add_fipb = ldap_mod_add($ds,$auDN,$modentry);  
   if ($add_fipb){
   	echo "<br>geloeschte IP Range(s) erfolgreich als neuer FIPB in die AU eingetragen!<br>" ;
   	merge_ipranges($auDN);
   	
   	$delete = ldap_delete($ds,$delpool[$i]);
   	if ($delete){
   		# Subnet-AU auf DHCP-Modify setzen
   		$au_to_update [] = $subnetau[$i];
   	   # Arrays von gelöschten Pools für weitere Verarbeitung bereinigen
      	foreach ( $key as $nr ){
            array_splice ( &$pooldn, $nr, 1 );
            array_splice ( &$addrange1, $nr, 1 );
            array_splice ( &$addrange2, $nr, 1 );
            array_splice ( &$uc, $nr, 1 );
            array_splice ( &$olduc, $nr, 1 );
            array_splice ( &$rbs, $nr, 1 );
            array_splice ( &$oldrbs, $nr, 1 );
         }
         # da sich Arrays verkleinern, Wert in $key_r entsprechend verkleinern,
         $j=0; # Variable $j als Zähler um wieviel
         foreach ( $key_r as $nr ){
            array_splice ( &$rangepooldn, $nr-$j, 1 );
            array_splice ( &$range1, $nr-$j, 1 );
            array_splice ( &$range2, $nr-$j, 1 );
            array_splice ( &$oldrange1, $nr-$j, 1 );
            array_splice ( &$oldrange2, $nr-$j, 1 );
            $j++;
         }
      	printf("Pool <b>%s</b> erfolgreich gel&ouml;scht<br>", $delpool[$i]);
      }else{
         printf("Fehler beim L&ouml;schen des Pools <b>%s</b>", $delpool[$i]); 
      }
   }else{ 
		echo "<br>Fehler beim eintragen der geloeschten IP Range(s) als neuen FIPB! <br>DHCP Pool nicht gel&ouml;scht<br>";
	}			
}

#########################################################################################
# Änderungen in bestehenden Pools (unknown-clients) und Ranges hinzufügen
for ($i=0;$i<count($pooldn);$i++){
   
   $entrydel = array();
   $entryadd = array();
	$entryrbs = array();
   # DENY, ALLOW, IGNORE Unknown-clients verarbeiten
   if ( $uc[$i] != $olduc[$i] ){
      $dhcpoptdel = "dhcpopt".$olduc[$i];
      $entrydel [$dhcpoptdel] = array();
      #print_r($entrydel); echo "<br>";
      ldap_mod_del($ds,$pooldn[$i],$entrydel);
      $dhcpoptadd = "dhcpopt".$uc[$i];
      $entryadd [$dhcpoptadd] = "unknown-clients";
      #print_r($entryadd); echo "<br><br>";
      ldap_mod_add($ds,$pooldn[$i],$entryadd);
      printf("Pool %s:<br>DHCP Option <b>unknown-clients</b> von <b>%s</b> auf <b>%s</b> ge&auml;ndert<br><br>",$pooldn[$i],$olduc[$i],$uc[$i]);
   	# Subnet-AU auf DHCP-Modify setzen
		$au_to_update [] = $subnetau[$i];
   }
	# RBS
	if ( $rbs[$i] != "none" && $rbs[$i] != $oldrbs[$i] ){
		$dhcpdata = get_node_data($rbs[$i],array("tftpserverip","initbootfile"));
	   $entryrbs ['hlprbservice'] = $rbs[$i];
	   $entryrbs ['dhcpoptnext-server'] = $dhcpdata['tftpserverip'];
      $entryrbs ['dhcpoptfilename'] = $dhcpdata['initbootfile'];
		if ( $oldrbs[$i] == "" ){
			echo "RBS add "; print_r($entryrbs); echo "<br>";
   	   if ($result = ldap_mod_add($ds,$pooldn[$i],$entryrbs)){
   	      echo "DHCP Pool erfolgreich in RBS eingebunden.<br>";
			}
		}elseif ( $rbs[$i] == "" ){
			$entryrbs ['hlprbservice'] = array();
			$entryrbs ['dhcpoptnext-server'] = array();
			$entryrbs ['dhcpoptfilename'] = array();
			echo "RBS delete "; echo "<br>";
			if ($result = ldap_mod_del($ds,$pooldn[$i],$entryrbs)){
				echo "DHCP Pool erfolgreich aus RBS gel&ouml;scht.<br>";
			}
		}else{
			echo "RBS replace "; print_r($oldrbs[$i]); echo " with "; print_r($entryrbs); echo "<br>";
   	   if ($result = ldap_mod_replace($ds,$pooldn[$i],$entryrbs)){
      	   echo "DHCP Pool RBS Einbindung erfolgreich ge&auml;ndert.<br>";
			}
		}
	}
	
   # Ranges hinzufügen
   if ( $addrange1[$i] != "" && $addrange2[$i] != "" ){
      if ($syntax->check_ip_syntax($addrange1[$i]) && $syntax->check_ip_syntax($addrange2[$i])){
         $net = strrev(strchr(strrev($subnet[$i]), "."));
         $add1 = strrev(strchr(strrev($addrange1[$i]), "."));
         $add2 = strrev(strchr(strrev($addrange2[$i]), "."));
         if ( $net == $add1 && $net == $add2 ){

            printf("Range in Pool %s hinzuf&uuml;gen<br>",$pooldn[$i]);
            # Range zusammenstellen
            $newrange = implode("_", array($addrange1[$i],$addrange2[$i]));
            $result = add_dhcprange($newrange,$pooldn[$i]);
            if ($result){
            	# Subnet-AU auf DHCP-Modify setzen
					$au_to_update [] = $subnetau[$i];
               printf("Neue dynamische IP Range %s - %s erfolgreich in Subnetz %s0 eingetragen!<br>",$addrange1[$i],$addrange2[$i],$net);
            }else{
               echo "<br>Fehler beim eintragen des dynamischen DHCP Pools!<br>";
            }

         }else{
            printf("Neue Range %s - %s nicht in Subnetz %s0",$addrange1[$i],$addrange2[$i],$net);
         }
      }else{
         printf("falsche IP Syntax der neuen Range %s - %s<br>", $addrange1[$i],$addrange2[$i]);
      }
   }

}

#########################################################################################
# In Pools bereits angelegte Ranges verarbeiten (löschen, verkleinern, vergrößern)
# vorzunehmende Änderungen in Arrays ($mod_dhcpranges, $new_fibs) speichern
$fipbs = get_freeipblocks_au($auDN);
$new_fipbs ['freeipblock'] = $fipbs;
$mod_dhcpranges = array();

for ($i=0;$i<count($rangepooldn);$i++){

   $range = implode('_',array($range1[$i],$range2[$i]));
   $oldrange = implode('_',array($oldrange1[$i],$oldrange2[$i]));
   
   if ( $oldrange1[$i] != "" && $oldrange2[$i] != "" && $range1[$i] == "" && $range2[$i] == "" ){
      # Range löschen
      $mod_dhcpranges [$rangepooldn[$i]] = $poolranges [$rangepooldn[$i]];
	   $range_key = array_search ( $oldrange, $mod_dhcpranges[$rangepooldn[$i]] );
	   #print_r($range_key); echo "<br>";
	   array_splice ( &$mod_dhcpranges[$rangepooldn[$i]], $range_key, 1 );
	   array_splice ( &$poolranges[$rangepooldn[$i]], $range_key, 1 );
      $new_fipbs ['freeipblock'][] = $oldrange;
      # Subnet-AU auf DHCP-Modify setzen
		$au_to_update [] = $subnetau[$i];
   }
   elseif ( $oldrange1[$i] != "" && $oldrange2[$i] != "" && $range1[$i] != "" && $range2[$i] != "" ){
		$or1 = ip2long($oldrange1[$i]);
		$or2 = ip2long($oldrange2[$i]);
		$nr1 = ip2long($range1[$i]);
		$nr2 = ip2long($range2[$i]);
		
		if ( ($nr1 > $or1 || $nr2 < $or2) && !($nr1 < $or1 || $nr2 > $or2) ){
		   if ($syntax->check_ip_syntax($range1[$i]) && $syntax->check_ip_syntax($range2[$i])){
   		   # Range verkleinern
   		   $diffrange = split_iprange($range,$oldrange);
   	      echo "<br>diffrange: "; print_r($diffrange); echo "<br>";
   		   # array $poolranges aktualisieren (neue Ranges)
   		   $mod_dhcpranges [$rangepooldn[$i]] = $poolranges [$rangepooldn[$i]];
   		   $range_key = array_search ( $oldrange, $mod_dhcpranges [$rangepooldn[$i]] );
   		   #print_r($range_key); echo "<br>";
   		   $poolranges [$rangepooldn[$i]][$range_key] = $range;
   		   $mod_dhcpranges [$rangepooldn[$i]][$range_key] = $range;
   		   # Subnet-AU auf DHCP-Modify setzen
				$au_to_update [] = $subnetau[$i];
        
            foreach ($diffrange as $dr){
               $new_fipbs ['freeipblock'][] = $dr;
            }
         }else{
            printf("falsche IP Syntax der neuen Range %s - %s<br>", $range1[$i],$range2[$i]);
         }
		}
		elseif( ($nr1 < $or1 || $nr2 > $or2) && !($nr1 > $or1 || $nr2 < $or2) ){
		   if ($syntax->check_ip_syntax($range1[$i]) && $syntax->check_ip_syntax($range2[$i])){
   		   # Range vergrößern 
   		   $addrange = split_iprange($oldrange,$range);
   		   echo "addrange: "; print_r($addrange); echo "<br>";
   		   $mod_dhcpranges [$rangepooldn[$i]] = $poolranges [$rangepooldn[$i]];
   		   
            foreach ($addrange as $ar){
               $test = 0;
               for ($c=0; $c < count($new_fipbs['freeipblock']); $c++){
            		if ( split_iprange($ar,$new_fipbs['freeipblock'][$c]) != 0 ){
            			$ipranges = split_iprange($ar,$new_fipbs['freeipblock'][$c]);
            			array_splice($new_fipbs['freeipblock'], $c, 1, $ipranges);
            			$test = 1;
            			break;
            		}		
            	}
            	if ( $test ){
            	   $poolranges [$rangepooldn[$i]][] = $ar;
                  $mod_dhcpranges [$rangepooldn[$i]][] = $ar;
                  # Subnet-AU auf DHCP-Modify setzen
						$au_to_update [] = $subnetau[$i];
            	}
            }
         }else{
            printf("falsche IP Syntax der neuen Range %s - %s<br>", $range1[$i],$range2[$i]);
         }
		}
		#else{ 
		#   $mesg = "<br>Verschieben (Shiften) einer IP Range nicht moeglich!<br>
		#	Nur Vergroessern und Verkleinern moeglich!<br>";
		#	$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
		#				Falls nicht, klicken Sie hier <a href='dhcppool.php' style='publink'>back</a>";
		#	redirect($seconds, $url, $mesg, $addSessionId = TRUE);
		#}
   }
}
#print_r($mod_dhcpranges); echo "<br>";
#print_r($new_fipbs); echo "<br><br>";

#########################################################################################
# In Arrays $dhcp_modranges und $new_fipbs gespeicherte Änderungen im LDAP schreiben
$keys = array_keys($mod_dhcpranges);
foreach ($keys as $pdn){
   #print_r($pdn); echo "<br>";
   #print_r($mod_dhcpranges[$pdn]); echo "<br>";
   if ( count($mod_dhcpranges[$pdn]) == 0 ){
      printf("Pool %s l&ouml;schen<br>",$pdn);
      if ($res = ldap_delete($ds,$pdn)){
         printf("Pool %s erfolgreich gel&ouml;scht",$pdn);
      }else{
         printf("Fehler beim L&ouml;schen von %s",$pdn);
      }
   }else{
      echo "Pool Ranges anpassen<br>";
      foreach ($mod_dhcpranges[$pdn] as $rg){ 
         $modpool ['dhcprange'][] = $rg;
      }
      #print_r($modpool); echo "<br>";
      $modpool ['dhcprange'] = merge_ipranges_array($modpool ['dhcprange']);
      print_r($modpool); echo "<br>";
      if ($res = ldap_mod_replace($ds,$pdn,$modpool)){
         printf("Pool Ranges von %s erfolgreich angepasst",$pdn);
      }else{
         printf("Fehler beim Anpassen der Pool Ranges von %s",$pdn);
      }
   }
}

$diff = array_diff( $new_fipbs['freeipblock'], $fipbs );
$revdiff = array_diff( $fipbs, $new_fipbs['freeipblock'] );
if ( count($diff) != 0 || count($revdiff) != 0 ){
   echo "<br>FIPBS anpassen<br>";
   #print_r($new_fipbs['freeipblock']); echo "<br>";
   $new_fipbs['freeipblock'] = merge_ipranges_array($new_fipbs['freeipblock']);
   print_r($new_fipbs); echo "<br>";
   if ($res = ldap_mod_replace($ds,$auDN,$new_fipbs)){
      printf("FIPBs erfolgreich angepasst");
   }else{
      printf("Fehler beim Anpassen der FIPBs");
   }
}

#########################################################################################
# DHCP Modify Timestamps in betreffenden AUs aktualisieren
#echo "<br>Subnet-AU: ";print_r ($au_to_update); echo "<br>";
update_dhcpmtime($au_to_update);



$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>