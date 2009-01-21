<?php
include('../standard_header.inc.php');

$pxeDN = $_POST['pxedn'];
$oldpxecn = "PXE_".$_POST['oldpxecn'];
$pxecn = "PXE_".$_POST['pxecn'];

$pxeday = $_POST['pxeday']; 
$pxebeg = $_POST['pxebeg']; 
$pxeend = $_POST['pxeend'];
foreach (array_keys($pxeday) as $key){
	$pxeday[$key] = htmlentities($pxeday[$key]);
}
foreach (array_keys($pxebeg) as $key){
	$pxebeg[$key] = htmlentities($pxebeg[$key]);
}
foreach (array_keys($pxeend) as $key){
	$pxeend[$key] = htmlentities($pxeend[$key]);
}

$deltr = $_POST['deltr'];

$newpxeday = $_POST['newpxeday']; $newpxeday = htmlentities($newpxeday);
$newpxebeg = $_POST['newpxebeg']; $newpxebeg = htmlentities($newpxebeg);
$newpxeend = $_POST['newpxeend']; $newpxeend = htmlentities($newpxeend); 
$oldpxeday = $_POST['oldpxeday']; 
$oldpxebeg = $_POST['oldpxebeg'];
$oldpxeend = $_POST['oldpxeend']; 


$rbs = $_POST['rbs'];
$filename = $_POST['filename'];
if (count($filename) != 0){
	foreach (array_keys($filename) as $key){
		$file[$key] = htmlentities($filename[$key]);
	}
}
$oldfilename = $_POST['oldfilename'];
if (count($oldfilename) != 0){
	foreach (array_keys($oldfilename) as $key){
		$oldfile[$key] = htmlentities($oldfilename[$key]);
	}
}
$newfilename = $_POST['newfilename']; $newfilename = htmlentities($newfilename);


$nodeDN = $_POST['nodedn'];
$mnr = $_POST['mnr'];
$sbmnr = $_POST['sbmnr'];
$mcnr = $_POST['mcnr'];


$seconds = 2;
$url = "pxe.php?dn=".$pxeDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;
 
echo "
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

##############################################
# PXE CN (DN) 

if ( $oldpxecn == $pxecn ){
	# $mesg = "keine Aenderung<br>";
}

if ( $oldpxecn != "" && $pxecn != "" && $oldpxecn != $pxecn ){
	echo "PXE Name aendern<br>";
	# hier noch Syntaxcheck
	# Formulareingaben anpassen
	$exppxe = explode(" ",$pxecn);
	foreach ($exppxe as $word){$expuc[] = ucfirst($word);}
	$pxecn = implode(" ",$expuc);
	$pxecn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $pxecn);
	
	
	$newpxeDN = "cn=".$pxecn.",".$nodeDN;
	print_r($newpxeDN); echo "<br><br>";
	
	if(modify_pxe_dn($pxeDN, $newpxeDN)){
		$mesg = "PXE Name erfolgreich ge&auml;ndert<br><br>";
		$pxeDN = $newpxeDN;
	}else{
		$mesg = "Fehler beim &auml;ndern des PXE Namen!<br><br>";
	}
	
	
	# newsubmenu holen...
	$url = "pxe.php?dn=".$newpxeDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;
}

if ( $oldpxecn != "" && $pxecn == "" ){
	echo "PXE Name loeschen!<br> 
			Dieses ist Teil des DN, Sie werden das PXE Boot Men&uuml; komplett l&ouml;schen<br><br>";
	echo "Wollen Sie das PXE Boot Men&uuml; <b>".$oldpxecn."</b> wirklich l&ouml;schen?<br><br>
			<form action='pxe_delete.php' method='post'>
				Falls ja:<br><br>
				<input type='hidden' name='dn' value='".$pxeDN."'>
				<input type='hidden' name='name' value='".$oldpxecn."'>
				<input type='Submit' name='apply' value='l&ouml;schen' class='small_loginform_button'><br><br>
			</form>
			<form action='".$url."' method='post'>
				Falls, nein:<br><br>
				<input type='Submit' name='apply' value='zur&uuml;ck' class='small_loginform_button'>
			</form>";
			$seconds = 600;
}

##########################################
# Remote Boot Dienst

if ($rbs != "none"){
	$exp = explode(',',$rbs);
	$exprbscn = explode('=',$exp[0]);
	$rbscn = $exprbscn[1];
	$exprbsau = explode('=',$exp[2]); 
	$rbsau = $exprbsau[1];
	
	$entryrbs ['rbservicedn'] = $rbs;
	if ($result = ldap_mod_replace($ds,$pxeDN,$entryrbs)){
		$mesg = "Remote Boot Service erfolgreich zu <b>".$rbscn."[Abt.: ".$rbsau."]</b> ge&auml;ndert<br><br>";
	}else{
		$mesg = "Fehler beim &auml;ndern des Remote Boot Services zu <b>".$rbscn."</b>!<br><br>";
	}
}


##########################################
# bereits vorhandene TimeRange(s) bearbeiten

$entrymodtr = array();
$modtr = 0;
# TimeRanges zusammensetzen
# $t = 0; # Laufvariable für $entrymodtr, da nicht jede Timerange ok sein muss
for ($i=0; $i<count($pxeday); $i++){

$oldpxetimerange = $oldpxeday[$i]."_".$oldpxebeg[$i]."_".$oldpxeend[$i];

if (  ($pxebeg[$i] <= $pxeend[$i]) && ( ($pxeday[$i] != $oldpxeday[$i] && $pxeday[$i] != "") || ($pxebeg[$i] != $oldpxebeg[$i] && $pxebeg[$i] != "") || ($pxeend[$i] != $oldpxeend[$i] && $pxeend[$i] != "")) ){
	
	
	# TimeRange Syntax checken
	$syntax = new Syntaxcheck;
	if ($syntax->check_timerange_syntax($pxeday[$i],$pxebeg[$i],$pxeend[$i])){
		
		# in Grossbuchstaben
		if (preg_match("/([a-z]+)/",$pxeday[$i])){$pxeday[$i] = strtoupper($pxeday[$i]);}
		if (preg_match("/([a-z]+)/",$pxebeg[$i])){$pxebeg[$i] = strtoupper($pxebeg[$i]);}
		if (preg_match("/([a-z]+)/",$pxeend[$i])){$pxeend[$i] = strtoupper($pxeend[$i]);}
		
		# führende Nullen weg
		$pxebeg[$i] = preg_replace ( '/0([0-9])/', '$1', $pxebeg[$i]);
		$pxeend[$i] = preg_replace ( '/0([0-9])/', '$1', $pxeend[$i]);
		 
		# TimeRange auf Überschneidung mit vorhandenen checken außer mit eigener alter TR da diese
		# ja geändert werden soll
		if(check_timerange_pxe($pxeday[$i],$pxebeg[$i],$pxeend[$i],$nodeDN,$oldpxetimerange)){
		
			$pxetimerange = $pxeday[$i]."_".$pxebeg[$i]."_".$pxeend[$i];
			$entrymodtr ['timerange'][$i] = $pxetimerange;
			$modtr = 1;
			
		}
		else{
			$mesg = "Es existiert bereits ein PXE Boot Men&uuml;, das sich mit der eingegebenen Time Range
						&uuml;berschneidet!<br>
						Bitte geben Sie eine andere Time Range ein.<br><br>";
			$entrymodtr ['timerange'][$i] = $oldpxetimerange;
		}
	}
	else{
		$mesg = "Falsche Syntax in der Timerange-Eingabe!<br>
					Bitte geben Sie die erneut Time Range ein.<br><br>";
		$entrymodtr ['timerange'][$i] = $oldpxetimerange;
	}
	
}


elseif (  $pxeday[$i] == "" || $pxebeg[$i] == "" || $pxeend[$i] == "" || $pxebeg[$i] > $pxeend[$i]){

	$mesg = "Sie haben die Time Range <b>Nr.".$i."</b> nicht vollst&auml;ndig angegeben. Diese ist aber ein notwendiges Attribut.<br>
				Diese Time Range wird nicht bearbeitet.<br><br>";
	$entrymodtr ['timerange'][$i] = $oldpxetimerange;
}

else{$entrymodtr ['timerange'][$i] = $oldpxetimerange;}
} # Ende for-Schleife für jede Timerange
# jetzt noch alle gesammelten Änderungen Durchführen ...
if ($modtr == 1){
	# erst ändern
	echo "&Auml;ndern: "; print_r($entrymodtr); echo "<br>";
	if($result = ldap_mod_replace($ds,$pxeDN,$entrymodtr)){
		$mesg = "TimeRanges erfolgreich ge&auml;ndert<br><br>";
	}else{
		$mesg = "Fehler beim &auml;ndern der TimeRanges!<br><br>";
	}
}


if ( count($deltr) != 0 && $modtr == 0 ){
	# Time Range löschen 
	$j = 0;
	foreach ($deltr as $delrange){
		$entrydeltr ['timerange'][$j] = $delrange;
		$j++;
	}
	# dann löschen
	echo "L&ouml;schen: "; print_r($entrydeltr); echo "<br>";
	if($result = ldap_mod_del($ds,$pxeDN,$entrydeltr)){
		$mesg = "TimeRanges erfolgreich gel&ouml;scht<br><br>";
	}else{
		$mesg = "Fehler beim l&ouml;schen der TimeRanges!<br><br>";
	}
}elseif(count($deltr) != 0 && $modtr == 1){
	echo "Nur &Auml;ndern (gleichzeitig L&ouml;schen und &Auml;ndern geht nicht)";
}

#####################################
# TimeRange hinzufügen

if ( $newpxeday != "" && $newpxebeg != "" && $newpxeend != "" && $newpxebeg <= $newpxeend ){

	# TimeRange Syntax checken
	$syntax = new Syntaxcheck;
	if ($syntax->check_timerange_syntax($newpxeday,$newpxebeg,$newpxeend)){
		
		# in Grossbuchstaben
		if (preg_match("/([a-z]+)/",$newpxeday)){$newpxeday = strtoupper($newpxeday);}
		if (preg_match("/([a-z]+)/",$newpxebeg)){$newpxebeg = strtoupper($newpxebeg);}
		if (preg_match("/([a-z]+)/",$newpxeend)){$newpxeend = strtoupper($newpxeend);}
		
		# führende Nullen weg
		$newpxebeg = preg_replace ( '/0([0-9])/', '$1', $newpxebeg);
		$newpxeend = preg_replace ( '/0([0-9])/', '$1', $newpxeend);
		
		# TimeRange auf Überschneidung mit vorhandenen checken
		if(check_timerange_pxe($newpxeday,$newpxebeg,$newpxeend,$nodeDN,"")){
		
			$newpxetimerange = $newpxeday."_".$newpxebeg."_".$newpxeend;
			$entrytr ['timerange'] = $newpxetimerange;
			if($result = ldap_mod_add($ds,$pxeDN,$entrytr)){
				$mesg = "Zus&auml;tzliche TimeRange erfolgreich eingetragen<br><br>";
			}else{
				$mesg = "Fehler beim eintragen der zus&auml;tzlichen TimeRange!<br><br>";
			}
		}else{
			$mesg = "Es existiert bereits ein PXE Boot Men&uuml;, das sich mit der eingegebenen Time Range
						&uuml;berschneidet!<br>
						Bitte geben Sie eine andere Time Range ein.<br><br>";
		}
	}else{
		$mesg = "Falsche Syntax in der Timerange-Eingabe!<br>
					Bitte geben Sie die erneut Time Range ein.<br><br>";
	}
}


 
#####################################
# PXE Filename(s)

$filemod = array();
$modfi = 0;
$filedel = array();
$delfi = 0;
$j = 0;

if (count($file) != 0){

for ($i=0; $i<count($file); $i++){

	if ( $oldfile[$i] == $file[$i] ){
		$filemod ['filename'][$i] = $oldfile[$i];
		# $mesg = "keine Aenderung<br>";
	}
	
	if ( $oldfile[$i] != "" && $file[$i] != "" && $oldfile[$i] != $file[$i] ){
		echo "PXE Dateinamen aendern<br>
				Vorsicht dies kann eine nicht verwendbare PXE Datei zur Folge haben!<br><br>";
		# hier noch Syntaxcheck
		$filemod ['filename'][$i]  = $file[$i];
		$modfi = 1;
	}
	
	if ( $oldfile[$i] != "" && $file[$i] == "" ){
		echo "PXE Dateinamen loeschen!<br> 
				Achtung: aus ihren PXE Daten wird keine PXE Datei mehr generiert.<br>
				Sie sind solange nicht mehr f&uuml;r den PXE Bootvorgang verwendbar bis Sie einen neuen Dateinamen anlegen!<br><br>";
		$filemod ['filename'][$i] = $oldfile[$i];
		$filedel ['filename'][$j] = $oldfile[$i];
		$j++;
		$delfi = 1;
		$seconds = 4;
	}
}
#erst ändern
if ($modfi == 1){
	echo "&Auml;ndern: "; print_r($filemod); echo "<br>";
	if(ldap_mod_replace($ds,$pxeDN,$filemod)){
		$mesg = "PXE Dateiname(n) erfolgreich ge&auml;ndert<br><br>";
	}else{
		$mesg = "Fehler beim &auml;ndern des(r) PXE Dateinamens!<br><br>";
	}
	$modfi = 0;
}
# dann löschen
if ($delfi == 1){
	echo "L&ouml;schen: "; print_r($filedel); echo "<br>";
	if(ldap_mod_del($ds,$pxeDN,$filedel)){
		$mesg = "PXE Dateiname(n) erfolgreich gel&ouml;scht<br><br>";
	}else{
		$mesg = "Fehler beim l&ouml;schen des PXE Dateinamens !<br><br>";
	}
	$delfi = 0;
}

}

# PXE Dateiname neu anlegen
if ($newfilename == ""){
}
if ($newfilename != ""){
	echo "PXE Dateiname hinzuf&uuml;gen";
	$fileadd ['filename'] = $newfilename;
	if(ldap_mod_add($ds,$pxeDN,$fileadd)){
		$mesg = "PXE Dateiname <b>".$newfilename."</b> erfolgreich angelegt<br><br>";
	}else{
		$mesg = "Fehler beim anlegen des PXE Dateinamens ".$newfilename." !<br><br>";
	}
}


######################### 

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>