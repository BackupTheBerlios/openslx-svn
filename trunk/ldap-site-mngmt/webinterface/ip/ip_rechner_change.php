<?php

include('../standard_header.inc.php');

$auDN = $_POST['audn'];
$hostDN = $_POST['hostdn'];
$oldip = $_POST['oldip'];
$newip = $_POST['newip'];
# print_r($newip);echo "<br>";
# print_r($oldip);echo "<br>";

$syntax = new Syntaxcheck;
$url = "ip_rechner.php";

echo "
<html>
<head>
	<title>IP Address Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>";


$diff1 = array_keys(array_diff_assoc($oldip,$newip)); 
$diff2 = array_keys(array_diff_assoc($newip,$oldip));
$tochange = array_unique(array_merge($diff1,$diff2));
# print_r($diff1);echo "<br>";
# print_r($diff2);echo "<br>";
# print_r($tochange);echo "<br><br>";

foreach ($tochange as $i){

	if ( $oldip[$i] == "" && $newip[$i] != "" ){
		echo "neue IP";echo "<br>";echo "<br>";
		#print_r($auDN[$i]);echo "<br>";
		#print_r($hostDN[$i]);echo "<br>";
		echo "<br>";
		echo "alte IP: ";print_r($oldip[$i]);echo "<br>";
		echo "neue IP: ";print_r($newip[$i]);echo "<br>";
		
		if ($syntax->check_ip_syntax($newip[$i])){
			echo "korrekte IP Syntax";
			$newip[$i] = htmlentities($newip[$i]);
			$newip_array = array($newip[$i],$newip[$i]);
			#print_r($newip_array);
			$newipp = implode('_',$newip_array);
			#print_r($newipp);
			$oldip[$i] = htmlentities($oldip[$i]);
			if (new_ip_host($newipp,$hostDN[$i],$auDN[$i])){
			 	$mesg = "Neue IP Adresse eingetragen<br>";
			}else{$mesg = "Fehler beim eintragen der neuen IP Adresse<br>";}
		}else{echo "falsche IP Syntax";}
		
		$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
				Falls nicht, klicken Sie hier <a href='ip_rechner.php' style='publink'>back</a>";
		redirect(4, $url, $mesg, $addSessionId = TRUE);
	}
	
	elseif ( $oldip[$i] != "" && $newip[$i] != "" ){
		echo "aendern IP";echo "<br>";echo "<br>";
		#print_r($auDN[$i]);echo "<br>";
		#print_r($hostDN[$i]);echo "<br>";
		echo "<br>";
		echo "alte IP: ";print_r($oldip[$i]);echo "<br>";
		echo "neue IP: ";print_r($newip[$i]);echo "<br>";
		
		if ($syntax->check_ip_syntax($newip[$i])){
			echo "korrekte IP Syntax";
			$newip[$i] = htmlentities($newip[$i]);
			$newip_array = array($newip[$i],$newip[$i]);
			#print_r($newip_array);
			$newipp = implode('_',$newip_array);
			#print_r($newipp);
			$oldip[$i] = htmlentities($oldip[$i]);
			$oldip_array = array($oldip[$i],$oldip[$i]); 
			$oldipp = implode('_',$oldip_array);
			if (modify_ip_host($newipp,$hostDN[$i],$auDN[$i])){
				$mesg = "IP Adresse geaendert<br>";
			}else{
				$mesg = "Fehler beim aendern der IP Adresse<br>";
				# oldip die schon gelöscht wurde wieder einfügen
				new_ip_host($oldipp,$hostDN[$i],$auDN[$i]);}
		}else{echo "falsche IP Syntax";}
		
		$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
				Falls nicht, klicken Sie hier <a href='ip_rechner.php' style='publink'>back</a>";
		redirect(4, $url, $mesg, $addSessionId = TRUE);
	}

	elseif ( $oldip[$i] != "" && $newip[$i] == "" ){
		echo "loeschen IP";echo "<br>";echo "<br>";
		#print_r($auDN[$i]);echo "<br>";
		#print_r($hostDN[$i]);echo "<br>";
		echo "<br>";
		echo "alte IP: ";print_r($oldip[$i]);echo "<br>";
		echo "neue IP: ";print_r($newip[$i]);echo "<br>";
		
		echo "korrekte IP Syntax";
		$newip[$i] = htmlentities($newip[$i]);
		$oldip[$i] = htmlentities($oldip[$i]);
		if (delete_ip_host($hostDN[$i],$auDN[$i])){
			$mesg = "IP Adresse geloescht<br>";
		}else{$mesg = "Fehler beim loeschen der IP Adresse<br>";}
		
		$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
				Falls nicht, klicken Sie hier <a href='ip_rechner.php' style='publink'>back</a>";
		redirect(4, $url, $mesg, $addSessionId = TRUE);
	}
	
	else{
		$mesg = "keine Aenderung<br>";
		$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
				Falls nicht, klicken Sie hier <a href='ip_rechner.php' style='publink'>back</a>";
		redirect(3, $url, $mesg, $addSessionId = TRUE);
	}

}

echo "
</td></tr></table>
</head>
</html>";
?>
