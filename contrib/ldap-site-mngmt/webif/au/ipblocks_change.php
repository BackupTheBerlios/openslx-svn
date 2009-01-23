<?php

include('../standard_header.inc.php');
$syntax = new Syntaxcheck;


#$auDN = $_POST['audn'];
$childauDN = $_POST['childdn'];
$childzone = $_POST['childzone'];
$oldrange1 = $_POST['oldrange1'];
$oldrange2 = $_POST['oldrange2'];
$newrange1 = $_POST['range1'];
$newrange2 = $_POST['range2'];

$childaudnexp = ldap_explode_dn($childauDN, 1);
$childau = $childaudnexp[0];
#print_r($childau);

/*
print_r($oldrange1);echo "<br>";
print_r($newrange1);echo "<br><br>";
print_r($oldrange2);echo "<br>";
print_r($newrange2);echo "<br>";
print_r($childauDN);echo "<br>";
print_r($childau);echo "<br>";
print_r($childzone);echo "<br>";
print_r($auDN);echo "<br><br>";
*/

$url = "child_au.php?cau=".$childau;
$seconds = 5;

echo "
<html>
<head>
	<title>IP Address Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'>
<tr><td>";


$diff1 = array_keys(array_diff_assoc($oldrange1,$newrange1)); 
$diff2 = array_keys(array_diff_assoc($newrange1,$oldrange1));
$tochange1 = array_unique(array_merge($diff1,$diff2));

$diff3 = array_keys(array_diff_assoc($oldrange2,$newrange2)); 
$diff4 = array_keys(array_diff_assoc($newrange2,$oldrange2));
$tochange2 = array_unique(array_merge($diff3,$diff4));

# print_r($tochange1);echo "<br><br>";
# print_r($tochange2);echo "<br><br>"; 

$tochange = array_unique(array_merge($tochange1,$tochange2));
#print_r($tochange);echo "<br><br>"; 

if ($tochange) {

foreach ($tochange as $i){

	if ( $oldrange1[$i] == "" && $oldrange2[$i] == "" && $newrange1[$i] != "" && $newrange2[$i] != "" ){
		
		echo "Neuen IP Bereich <b>$newrange1[$i] - $newrange2[$i]</b> an <b>$childau</b> anlegen:";echo "<br>";echo "<br>";
		#echo "neue IP Range: ";print_r($newrange1[$i]);echo " - ";print_r($newrange2[$i]);echo "<br>";
		
		if ($syntax->check_ip_syntax($newrange1[$i]) && $syntax->check_ip_syntax($newrange2[$i])){
			#echo "korrekte IP Syntax<br>";
			$newrange1[$i] = htmlentities($newrange1[$i]);
			$newrange2[$i] = htmlentities($newrange2[$i]);
			
			# DNS Lookup Test für neue IPs
			#if ( check_iprange_zone($newrange1[$i],$newrange2[$i],$childzone,$childau) ) {
				#echo "bla";
				$newrange_array = array($newrange1[$i],$newrange2[$i]);
				#print_r($newrange_array);
				$newrange = implode('_',$newrange_array);
				#print_r($newrange);
				# $oldip[$i] = htmlentities($oldip[$i]);
				$addentry ['maxipblock'][] = $newrange;
				$addentry ['freeipblock'][] = $newrange;
				if (ldap_mod_add($ds,$childauDN,$addentry)){
				 	echo "<br>Neuer IP Bereich erfolgreich angelegt<br>";
				}else{
					echo "<br>Fehler beim anlegen des neuen IP Bereichs<br>";
				}
			#}else{
			#	echo "IP Bereich <b>$newrange1[$i] - $newrange2[$i]</b> konnte nicht an <b>$childau</b> delegiert werden<br>";
			#}
		}else{echo "falsche IP Syntax<br>";}
	} 
	
	elseif ( $oldrange1[$i] != "" && $oldrange2[$i] != "" && $newrange1[$i] == "" && $newrange2[$i] == "" ){
		
		echo "IP Bereich von <b>$childau</b> l&ouml;schen:";echo "<br>";echo "<br>";
		echo "zu l&ouml;schende IP Range: ";print_r($oldrange1[$i]);echo " - ";print_r($oldrange2[$i]);echo "<br>";
		
		$oldrange1[$i] = htmlentities($oldrange1[$i]);
		$oldrange2[$i] = htmlentities($oldrange2[$i]);
		$oldip_array = array($oldrange1[$i],$oldrange2[$i]); 
		$oldrange = implode('_',$oldip_array);
		$delentry ['maxipblock'][] = $oldrange;
		$delentry ['freeipblock'][] = $oldrange;
		if (ldap_mod_del($ds,$childauDN,$delentry)){
			$mesg = "<br>IP Bereich geloescht<br>";
		}else{
			$mesg = "<br>Fehler beim loeschen des IP Bereichs<br>";
		}
	}
	
	elseif ( $oldrange1[$i] != "" && $oldrange2[$i] != "" && $newrange1[$i] != "" && $newrange2[$i] != "" ){
		$or1 = ip2long($oldrange1[$i]);
		$or2 = ip2long($oldrange2[$i]);
		$nr1 = ip2long($newrange1[$i]);
		$nr2 = ip2long($newrange2[$i]);
		
		if ( ($nr1 > $or1 || $nr2 < $or2) && !($nr1 < $or1 || $nr2 > $or2) ){
		
			echo "IP Delegierung von <b>$childau</b> reduzieren:";echo "<br>";echo "<br>";
			echo "alte IP Range: ";print_r($oldrange1[$i]);echo " - ";print_r($oldrange2[$i]);echo "<br>";
			echo "neue IP Range: ";print_r($newrange1[$i]);echo " - ";print_r($newrange2[$i]);echo "<br>";
		
			if ($syntax->check_ip_syntax($newrange1[$i]) && $syntax->check_ip_syntax($newrange2[$i])){
				#echo "korrekte IP Syntax<br>";
			
				$newrange1[$i] = htmlentities($newrange1[$i]);
				$newrange2[$i] = htmlentities($newrange2[$i]);
				$newrange_array = array($newrange1[$i],$newrange2[$i]);
				$newrange = implode('_',$newrange_array);
				#print_r($newrange);
				
				$oldrange1[$i] = htmlentities($oldrange1[$i]);
				$oldrange2[$i] = htmlentities($oldrange2[$i]);
				$oldip_array = array($oldrange1[$i],$oldrange2[$i]); 
				$oldrange = implode('_',$oldip_array); 
				#print_r($oldrange);
			
				if (reduce_ip_delegation($oldrange,$newrange,$childauDN,$auDN)){
					$mesg = "<br>IP Range verkleinert<br>";
				}else{
					$mesg = "<br>Fehler beim verkleinern der IP Range<br>";
				}
			}else{echo "falsche IP Syntax<br>";}
		
		}elseif( ($nr1 < $or1 || $nr2 > $or2) && !($nr1 > $or1 || $nr2 < $or2) ){
				
			echo "IP Delegierung von <b>$childau</b> erweitern";
			echo " von ";print_r($oldrange1[$i]);echo " - ";print_r($oldrange2[$i]);
			echo " auf <b>";print_r($newrange1[$i]);echo " - ";print_r($newrange2[$i]);echo "</b><br>";
			
			if ($syntax->check_ip_syntax($newrange1[$i]) && $syntax->check_ip_syntax($newrange2[$i])){
				#echo "korrekte IP Syntax<br>";
				$newrange1[$i] = htmlentities($newrange1[$i]);
				$newrange2[$i] = htmlentities($newrange2[$i]);
				
				$newrange_array = array($newrange1[$i],$newrange2[$i]);
				$newrange = implode('_',$newrange_array);
				#print_r($newrange);
				
				$oldrange1[$i] = htmlentities($oldrange1[$i]);
				$oldrange2[$i] = htmlentities($oldrange2[$i]);
				$oldip_array = array($oldrange1[$i],$oldrange2[$i]); 
				$oldrange = implode('_',$oldip_array); 
				#print_r($oldrange);

				# DNS Lookup Test für neue IPs
				$diffrange = split_iprange($oldrange,$newrange);
				# expand momentan nur für das erste element aus Diffrange-Array
				#print_r($diffrange);
				$drexp = explode("_",$diffrange[0]);
				if ( check_iprange_zone($drexp[0],$drexp[1],$childzone,$childau) ){
				
					if (expand_ip_delegation($oldrange,$newrange,$childauDN,$auDN)){
						$mesg = "<br>IP Range erweitert<br>";
					}else{
						$mesg = "<br>Fehler beim erweitern der IP Range<br>";
					}
				}else{
					echo "IP Bereich <b>$drexp[0] - $drexp[1]</b> konnte nicht an <b>$childau</b> delegiert werden<br>";
				}
			}else{
				echo "falsche IP Syntax<br>";
			}
		}
		else{
			$mesg = "<br>Verschieben (Shiften) der Delegierung nicht moeglich!<br>
			Nur Vergroessern und Verkleinern moeglich!<br>";
		}
	}
	
	$mesg .= "<br><br><a href=$url style='publink'><b>gelesen</b> &nbsp;&nbsp;(<< zur&uuml;ck)</a>";
	echo $mesg;
}

} else {
		$mesg .= "keine &Auml;nderung<br>
			<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
			Falls nicht, klicken Sie hier <a href=$url style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);
}


echo "
</td></tr></table>
</head>
</html>";
?>