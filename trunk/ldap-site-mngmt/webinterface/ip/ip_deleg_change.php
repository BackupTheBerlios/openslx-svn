<?php

include('../standard_header.inc.php');

$auDN = $_POST['audn'];
$childauDN = $_POST['childaudn'];
$oldrange1 = $_POST['oldrange1'];
$oldrange2 = $_POST['oldrange2'];
$newrange1 = $_POST['range1'];
$newrange2 = $_POST['range2'];

/* 
print_r($oldrange1);echo "<br>";
print_r($newrange1);echo "<br><br>";
print_r($oldrange2);echo "<br>";
print_r($newrange2);echo "<br>";
print_r($childauDN);echo "<br>";
print_r($auDN);echo "<br><br>";
*/

$syntax = new Syntaxcheck;
$url = "ip_deleg.php";
$seconds = 200;

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


foreach ($tochange as $i){

	$childaudnexp = ldap_explode_dn($childauDN[$i], 1);
	$childau = $childaudnexp[0];
	#print_r($childau);

	if ( $oldrange1[$i] == "" && $oldrange2[$i] == "" && $newrange1[$i] != "" && $newrange2[$i] != "" ){
		
		echo "Neuen IP Bereich an <b>$childau</b> delegieren:";echo "<br>";echo "<br>";
		echo "neue IP Range: ";print_r($newrange1[$i]);echo " - ";print_r($newrange2[$i]);echo "<br>";
		
		if ($syntax->check_ip_syntax($newrange1[$i]) && $syntax->check_ip_syntax($newrange2[$i])){
			#echo "korrekte IP Syntax<br>";
			$newrange1[$i] = htmlentities($newrange1[$i]);
			$newrange2[$i] = htmlentities($newrange2[$i]);
			$newrange_array = array($newrange1[$i],$newrange2[$i]);
			#print_r($newrange_array);
			$newrange = implode('_',$newrange_array);
			#print_r($newrange);
			# $oldip[$i] = htmlentities($oldip[$i]);
			if (new_ip_delegation($newrange,$childauDN[$i],$auDN[$i])){
			 	echo "<br>Neuer IP Bereich erfolgreich delegiert<br>";
			}else{echo "<br>Fehler beim delegieren des neuen IP Bereichs<br>";}
		}else{echo "falsche IP Syntax<br>";}
		
		$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
				Falls nicht, klicken Sie hier <a href='ip_deleg.php' style='publink'>back</a>";
		redirect($seconds, $url, $mesg, $addSessionId = TRUE);
	} 
	
	elseif ( $oldrange1[$i] != "" && $oldrange2[$i] != "" && $newrange1[$i] == "" && $newrange2[$i] == "" ){
		
		echo "IP Delegierung von <b>$childau</b> l&ouml;schen:";echo "<br>";echo "<br>";
		echo "zu l&ouml;schende IP Range: ";print_r($oldrange1[$i]);echo " - ";print_r($oldrange2[$i]);echo "<br>";
		
		$oldrange1[$i] = htmlentities($oldrange1[$i]);
		$oldrange2[$i] = htmlentities($oldrange2[$i]);
		$oldip_array = array($oldrange1[$i],$oldrange2[$i]); 
		$oldrange = implode('_',$oldip_array);
		if (delete_ip_delegation($oldrange,$childauDN[$i],$auDN[$i])){
			$mesg = "<br>IP Delegierung geloescht<br>";
		}else{
			$mesg = "<br>Fehler beim loeschen der IP Delegierung<br>";
		}
		
		$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
				Falls nicht, klicken Sie hier <a href='ip_deleg.php' style='publink'>back</a>";
		redirect($seconds, $url, $mesg, $addSessionId = TRUE);
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
			
				if (reduce_ip_delegation($oldrange,$newrange,$childauDN[$i],$auDN[$i])){
					$mesg = "<br>IP Range verkleinert<br>";
				}else{
					$mesg = "<br>Fehler beim verkleinern der IP Range<br>";
				}
			}else{echo "falsche IP Syntax<br>";}
				
			$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
						Falls nicht, klicken Sie hier <a href='ip_deleg.php' style='publink'>back</a>";
			redirect($seconds, $url, $mesg, $addSessionId = TRUE);
			
		
		}elseif( ($nr1 < $or1 || $nr2 > $or2) && !($nr1 > $or1 || $nr2 < $or2) ){
				
			echo "IP Delegierung von <b>$childau</b> erweitern:";echo "<br>";echo "<br>";
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
				
				if (expand_ip_delegation($oldrange,$newrange,$childauDN[$i],$auDN[$i])){
					$mesg = "<br>IP Range erweitert<br>";
				}else{
					$mesg = "<br>Fehler beim erweitern der IP Range<br>";
				}
			}else{
				echo "falsche IP Syntax<br>";
			}
			$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
						Falls nicht, klicken Sie hier <a href='ip_deleg.php' style='publink'>back</a>";
			redirect($seconds, $url, $mesg, $addSessionId = TRUE);	
		}
		else{
			$mesg = "<br>Verschieben (Shiften) der Delegierung nicht moeglich!<br>
			Nur Vergroessern und Verkleinern moeglich!<br>";
			$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
						Falls nicht, klicken Sie hier <a href='ip_deleg.php' style='publink'>back</a>";
			redirect($seconds, $url, $mesg, $addSessionId = TRUE);
		}
	}
	else{
		$mesg = "keine Aenderung<br>";
		$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
					Falls nicht, klicken Sie hier <a href='ip_deleg.php' style='publink'>back</a>";
		redirect($seconds, $url, $mesg, $addSessionId = TRUE);
	}
	
	echo "<br><br>";
}

echo "
</td></tr></table>
</head>
</html>";
?>
