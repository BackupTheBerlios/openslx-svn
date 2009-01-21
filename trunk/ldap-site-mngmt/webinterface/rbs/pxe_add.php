<?php
include('../standard_header.inc.php');

$pxecn = $_POST['pxecn'];  $pxecn = htmlentities($pxecn);
$rbsDN = $_POST['rbsdn'];
#print_r($rbsDN);
$pxeday = $_POST['pxeday']; $pxeday = htmlentities($pxeday);
$pxebeg = $_POST['pxebeg']; $pxebeg = htmlentities($pxebeg);
$pxeend = $_POST['pxeend']; $pxeend = htmlentities($pxeend); 

$conffile = $_POST['conffile'];  $conffile = htmlentities($conffile);

$pxeattribs = $_POST['pxeattribs'];
if (count($pxeattribs) != 0){
	foreach (array_keys($pxeattribs) as $key){
		$pxeatts[$key] = htmlentities($pxeattribs[$key]);
	}
}
# print_r($pxeatts); echo "<br><br>";
$mnr = $_POST['mnr'];
$sbmnr = $_POST['sbmnr'];
$mcnr = $_POST['mcnr'];


$seconds = 2;
$get_pxecn = str_replace ( " ", "_", $pxecn );
$get_pxeday = str_replace ( " ", "_", $pxeday );
$get_pxebeg = str_replace ( " ", "_", $pxebeg );
$get_pxeend = str_replace ( " ", "_", $pxeend );
$url = "new_pxe.php?pxecn=".$get_pxecn."&pxeday=".$get_pxeday."&pxebeg=".$get_pxebeg."&pxeend=".$get_pxeend."&mnr=".$mnr."&sbmnr=".$sbmnr;

echo " 
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $pxecn != "" && $pxecn != "Hier_PXE_NAME_eintragen" && $rbsDN != "none" ){

	$pxecn = "PXE_".$pxecn;
	# Formulareingaben anpassen
	$exppxe = explode(" ",$pxecn);
	foreach ($exppxe as $word){$expuc[] = ucfirst($word);}
	$pxecn = implode(" ",$expuc);
	$pxecn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $pxecn);
	
	$pxetimerange = "";
	
	if ( $pxeday != "" && $pxebeg != "" && $pxeend != "" && $pxebeg <= $pxeend ){
	
		# TimeRange Syntax checken
		$syntax = new Syntaxcheck;
		if ($syntax->check_timerange_syntax($pxeday,$pxebeg,$pxeend)){
			
			# in Grossbuchstaben
			if (preg_match("/([a-z]+)/",$pxeday)){$pxeday = strtoupper($pxeday);}
			if (preg_match("/([a-z]+)/",$pxebeg)){$pxebeg = strtoupper($pxebeg);}
			if (preg_match("/([a-z]+)/",$pxeend)){$pxeend = strtoupper($pxeend);}
		
			# führende Nullen weg
			$pxebeg = preg_replace ( '/0([0-9])/', '$1', $pxebeg);
			$pxeend = preg_replace ( '/0([0-9])/', '$1', $pxeend);
			
			# TimeRange auf Überschneidung mit vorhandenen checken
			if(check_timerange_pxe($pxeday,$pxebeg,$pxeend,$rbsDN,"")){
				$pxetimerange = $pxeday."_".$pxebeg."_".$pxeend;
			}
			else{
				$mesg = "Es existiert bereits ein PXE Boot Men&uuml;, das sich mit der eingegebenen Time Range
							&uuml;berschneidet!<br>
							Das neue PXE Boot Men&uuml; wird ohne Time Range angelegt.<br>
							Bitte geben Sie diese anschließend ein.<br><br>";
			}
		}
		else{
			$mesg = "Falsche Syntax in der Time-Range-Eingabe! Das neue PXE Boot Men&uuml; wird ohne Time Range angelegt.<br>
						Bitte geben Sie diese anschließend ein.<br><br>";
		}
	}
	else{
		$mesg = "Keine vollst&auml;ndige Time-Range-Eingabe! Das neue PXE Boot Men&uuml; wird ohne Time Range angelegt.<br>
					Bitte geben Sie diese anschließend ein.<br><br>";
	}

	$pxeDN = "cn=".$pxecn.",".$rbsDN;
	$filename = array("default");
	#$ldapuri = LDAP_HOST."/dn=cn=computers,".$auDN;
			
	if (add_pxe($pxeDN,$pxecn,$rbsDN,$pxetimerange,$pxeattribs,$filename,$conffile)){			
		$mesg .= "<br>Neues PXE Boot Men&uuml; erfolgreich angelegt<br>";
		$url = "pxe.php?dn=".$pxeDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;
		}
	else{
		$mesg .= "<br>Fehler beim anlegen des PXE Boot Men&uuml;s!<br>";
	}
}

elseif ( $pxecn == "" || $pxecn == "Hier_PXE_NAME_eintragen" || $rbsDN == "none" ){

	$mesg = "Sie haben den Namen des neuen PXE Boot Men&uuml;s nicht angegeben oder den
				Remote Boot Dienst nicht ausgew&auml;hlt. Beide sind aber ein notwendige Attribute.<br>
				Bitte geben Sie sie an.<br><br>";
	$url = "new_pxe.php?pxecn=Hier_PXE_NAME_eintragen&pxeday=".$get_pxeday."&pxebeg=".$get_pxebeg."&pxeend=".$get_pxeend."&mnr=".$mnr."&sbmnr=".$sbmnr;
}



$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>