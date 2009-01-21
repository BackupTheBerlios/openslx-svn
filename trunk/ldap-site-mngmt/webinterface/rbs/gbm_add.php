<?php
include('../standard_header.inc.php');

$gbmcn = $_POST['gbmcn'];  $gbmcn = htmlentities($gbmcn);
$rbsDN = $_POST['rbsdn'];

$mnr = $_POST['mnr'];
$sbmnr = $_POST['sbmnr'];

$attribs = $_POST['attribs'];
if (count($attribs) != 0){
	foreach (array_keys($attribs) as $key){
		$atts[$key] = htmlentities($attribs[$key]);
	}
}
# print_r($meatts); echo "<br><br>";

$seconds = 2;
$get_gbmcn = str_replace ( " ", "_", $gbmcn );
$url = "gbm.php?gbmcn=".$get_gbmcn."&mnr=".$mnr."&sbmnr=".$sbmnr;

echo " 
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 


if ( $gbmcn != "" && $gbmcn != "Hier_NAME_eintragen" ){

	# Formulareingaben anpassen
	$expgbm = explode(" ",$gbmcn);
	foreach ($expgbm as $word){$expuc[] = ucfirst($word);}
	$gbmcn = implode(" ",$expuc);
	$gbmcn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $gbmcn);

	$gbmDN = "cn=".$gbmcn.",".$rbsDN;
			
	if (add_gbm($gbmDN,$gbmcn,$atts)){			
		$mesg .= "<br>Neuen Generischen Men&uuml; Eintrag erfolgreich angelegt<br>";
		$url = "gbm_overview.php";
		}
	else{
		$mesg .= "<br>Fehler beim anlegen des Generischen Men&uuml; Eintrags!<br>";
	}
}

elseif ( $gbmcn == "" || $gbmcn == "Hier_NAME_eintragen" ){

	$mesg = "Sie haben den Namen des neuen Generischen Men&uuml; Eintrags nicht angegeben. 
				Dies ist aber ein notwendiges Attribut.<br>
				Bitte geben Sie sie an.<br><br>";
	$url = "new_gbm.php?gbmcn=Hier_NAME_eintragen&mnr=".$mnr."&sbmnr=".$sbmnr;
}



$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>