<?php

include('../standard_header.inc.php');

$auDN = $_POST['audn'];
$dhcpDN = $_POST['dhcpdn'];
$oldrange1 = $_POST['oldrange1'];
$oldrange2 = $_POST['oldrange2'];
$newrange1 = $_POST['range1'];
$newrange2 = $_POST['range2'];

/* 
print_r($oldrange1);echo "<br>";
print_r($newrange1);echo "<br><br>";
print_r($oldrange2);echo "<br>";
print_r($newrange2);echo "<br>";
*/

$syntax = new Syntaxcheck;
$url = "ip_dhcp.php";

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
# print_r($tochange);echo "<br><br>"; 


foreach ($tochange as $i){

	if ( $oldrange1[$i] == "" && $oldrange2[$i] == "" && $newrange1[$i] != "" && $newrange2[$i] != "" ){
		echo "neue IP Range";echo "<br>";echo "<br>";
		print_r($auDN[$i]);echo "<br>";
		print_r($dhcpDN[$i]);echo "<br>";
		echo "<br>";
		echo "alte IP Range: ";print_r($oldrange1[$i]);echo " - ";print_r($oldrange2[$i]);echo "<br>";
		echo "neue IP Range: ";print_r($newrange1[$i]);echo " - ";print_r($newrange2[$i]);echo "<br>";
		
		if ($syntax->check_ip_syntax($newrange1[$i]) && $syntax->check_ip_syntax($newrange2[$i])){
			echo "korrekte IP Syntax<br>";
			$newrange1[$i] = htmlentities($newrange1[$i]);
			$newrange2[$i] = htmlentities($newrange2[$i]);
			$newrange_array = array($newrange1[$i],$newrange2[$i]);
			print_r($newrange_array);
			$newrange = implode('_',$newrange_array);
			print_r($newrange);
			# $oldip[$i] = htmlentities($oldip[$i]);
			if (new_ip_dhcprange($newrange,$dhcpDN[$i],$auDN[$i])){
			 	$mesg = "Neue IP Range eingetragen<br>";
			}else{
				$mesg = "Fehler beim eintragen der neuen IP Range<br>";
			}
		}else{echo "falsche IP Syntax<br>";}
		
		$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
				Falls nicht, klicken Sie hier <a href='ip_dhcp.php' style='publink'>back</a>";
		redirect(4, $url, $mesg, $addSessionId = TRUE);
	} 
	
	elseif ( $oldrange1[$i] != "" && $oldrange2[$i] != "" && $newrange1[$i] == "" && $newrange2[$i] == "" ){
		echo "loeschen IP Range";echo "<br>";echo "<br>";
		print_r($auDN[$i]);echo "<br>";
		print_r($dhcpDN[$i]);echo "<br>";
		echo "<br>";
		echo "alte IP Range: ";print_r($oldrange1[$i]);echo " - ";print_r($oldrange2[$i]);echo "<br>";
		echo "neue IP Range: ";print_r($newrange1[$i]);echo " - ";print_r($newrange2[$i]);echo "<br>";
		
		$newrange1[$i] = htmlentities($newrange1[$i]);
		$newrange2[$i] = htmlentities($newrange2[$i]);
		if (delete_ip_dhcprange($dhcpDN[$i],$auDN[$i])){
			$mesg = "IP Range geloescht<br>";
		}else{
			$mesg = "Fehler beim loeschen der IP Range<br>";
		}
		
		$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
				Falls nicht, klicken Sie hier <a href='ip_dhcp.php' style='publink'>back</a>";
		redirect(4, $url, $mesg, $addSessionId = TRUE);
	}
	
	elseif ( $oldrange1[$i] != "" && $oldrange2[$i] != "" && $newrange1[$i] != "" && $newrange2[$i] != "" ){
		echo "aendern IP Range";echo "<br>";echo "<br>"; 
		print_r($auDN[$i]);echo "<br>";
		print_r($dhcpDN[$i]);echo "<br>";
		echo "<br>";
		echo "alte IP Range: ";print_r($oldrange1[$i]);echo " - ";print_r($oldrange2[$i]);echo "<br>";
		echo "neue IP Range: ";print_r($newrange1[$i]);echo " - ";print_r($newrange2[$i]);echo "<br>";
		
		if ($syntax->check_ip_syntax($newrange1[$i]) && $syntax->check_ip_syntax($newrange2[$i])){
			echo "korrekte IP Syntax<br>";
			$newrange1[$i] = htmlentities($newrange1[$i]);
			$newrange2[$i] = htmlentities($newrange2[$i]);
			$newrange_array = array($newrange1[$i],$newrange2[$i]);
			$newrange = implode('_',$newrange_array);
			print_r($newrange);
			$oldrange1[$i] = htmlentities($oldrange1[$i]);
			$oldrange2[$i] = htmlentities($oldrange2[$i]);
			$oldrange_array = array($oldrange1[$i],$oldrange2[$i]); 
			$oldrange = implode('_',$oldrange_array);
			if (modify_ip_dhcprange($newrange,$dhcpDN[$i],$auDN[$i])){
				$mesg = "IP Range geaendert<br>";
			}else{
				$mesg = "Fehler beim aendern der IP Range<br>";
				# alte Range wiederherstellen 
				new_ip_dhcprange($oldrange,$dhcpDN[$i],$auDN[$i]);
			}
		}else{echo "falsche IP Syntax<br>";}
		
		$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
				Falls nicht, klicken Sie hier <a href='ip_dhcp.php' style='publink'>back</a>";
		redirect(4, $url, $mesg, $addSessionId = TRUE);	
	}
	
	else{
		$mesg = "keine Aenderung<br>";
		$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
				Falls nicht, klicken Sie hier <a href='ip_dhcp.php' style='publink'>back</a>";
		redirect(4, $url, $mesg, $addSessionId = TRUE);
	}

}

echo "
</td></tr></table>
</head>
</html>";
?>