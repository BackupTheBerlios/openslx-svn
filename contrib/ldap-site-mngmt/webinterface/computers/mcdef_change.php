<?php
include('../standard_header.inc.php');

$mccn = "MC_".$_POST['mccn'];
$mcdesc = $_POST['mcdesc']; $mcdesc = htmlentities($mcdesc);

$mcday = $_POST['mcday']; 
$mcbeg = $_POST['mcbeg']; 
$mcend = $_POST['mcend'];
foreach (array_keys($mcday) as $key){
	$mcday[$key] = htmlentities($mcday[$key]);
}
foreach (array_keys($mcbeg) as $key){
	$mcbeg[$key] = htmlentities($mcbeg[$key]);
}
foreach (array_keys($mcend) as $key){
	$mcend[$key] = htmlentities($mcend[$key]);
}

$deltr = $_POST['deltr'];

$newmcday = $_POST['newmcday']; $newmcday = htmlentities($newmcday);
$newmcbeg = $_POST['newmcbeg']; $newmcbeg = htmlentities($newmcbeg);
$newmcend = $_POST['newmcend']; $newmcend = htmlentities($newmcend); 

$oldmcdesc = $_POST['oldmcdesc']; $oldmcdesc = htmlentities($oldmcdesc);
$oldmcday = $_POST['oldmcday']; 
$oldmcbeg = $_POST['oldmcbeg'];
$oldmcend = $_POST['oldmcend']; 

$crontab = $_POST['crontab'];
$oldcrontab = $_POST['oldcrontab'];
foreach (array_keys($crontab) as $key){
	$crontab[$key] = htmlentities($crontab[$key]);
}

$mcDN = $_POST['mcdn'];
$oldmccn = "MC_".$_POST['oldmccn'];

$nodeDN = $_POST['nodedn'];
$mnr = $_POST['mnr'];
$sbmnr = $_POST['sbmnr'];
$mcnr = $_POST['mcnr'];

# sosntige Attribute
$attribs = $_POST['attribs'];
if (count($attribs) != 0){
	foreach (array_keys($attribs) as $key){
		$atts[$key] = htmlentities($attribs[$key]);
	}
}
#print_r($atts); echo "<br><br>";
$oldattribs = $_POST['oldattribs'];
if (count($oldattribs) != 0){
	foreach (array_keys($oldattribs) as $key){
		$oldatts[$key] = htmlentities($oldattribs[$key]);
	}
}
#print_r($oldatts); echo "<br><br>";


$seconds = 2;
$url = "mcdef.php?dn=".$mcDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;
 
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
# MC CN (DN) 

if ( $oldmccn == $mccn ){
	# $mesg = "keine Aenderung<br>";
}

if ( $oldmccn != "" && $mccn != "" && $oldmccn != $mccn ){
	echo "Machine Config Name aendern<br>";
	# hier noch Syntaxcheck
	# Formulareingaben anpassen
	$expmc = explode(" ",$mccn);
	foreach ($expmc as $word){$expuc[] = ucfirst($word);}
	$mccn = implode(" ",$expuc);
	$mccn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $mccn);
	
	
	$newmcDN = "cn=".$mccn.",".$nodeDN;
	print_r($newmcDN); echo "<br><br>";
	
	if(modify_mc_dn($mcDN, $newmcDN)){
		$mesg = "MC Name erfolgreich ge&auml;ndert<br><br>";
		$mcDN = $newmcDN;
	}else{
		$mesg = "Fehler beim &auml;ndern des MC Name!<br><br>";
	}
	
	
	# newsubmenu holen...
	$url = "mcdef.php?dn=".$newmcDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;
}

if ( $oldmccn != "" && $mccn == "" ){
	echo "Gruppenname loeschen!<br> 
			Dieses ist Teil des DN, Sie werden die MachineConfig komplett l&ouml;schen<br><br>";
	echo "Wollen Sie die MachineConfig <b>".$oldmccn."</b> wirklich l&ouml;schen?<br><br>
			<form action='mcdef_delete.php' method='post'>
				Falls ja:<br><br>
				<input type='hidden' name='dn' value='".$mcDN."'>
				<input type='hidden' name='name' value='".$oldmccn."'>
				<input type='Submit' name='apply' value='l&ouml;schen' class='small_loginform_button'><br><br>
			</form>
			<form action='".$url."' method='post'>
				Falls, nein:<br><br>
				<input type='Submit' name='apply' value='zur&uuml;ck' class='small_loginform_button'>
			</form>";
			$seconds = 600;
}


##########################################
# bereits vorhandene TimeRange(s) bearbeiten

$entrymodtr = array();
$modtr = 0;
# TimeRanges zusammensetzen
# $t = 0; # Laufvariable für $entrymodtr, da nicht jede Timerange ok sein muss
for ($i=0; $i<count($mcday); $i++){

$oldmctimerange = $oldmcday[$i]."_".$oldmcbeg[$i]."_".$oldmcend[$i];

if (  ($mcbeg[$i] <= $mcend[$i]) && ( ($mcday[$i] != $oldmcday[$i] && $mcday[$i] != "") || ($mcbeg[$i] != $oldmcbeg[$i] && $mcbeg[$i] != "") || ($mcend[$i] != $oldmcend[$i] && $mcend[$i] != "")) ){
	
	
	# TimeRange Syntax checken
	$syntax = new Syntaxcheck;
	if ($syntax->check_timerange_syntax($mcday[$i],$mcbeg[$i],$mcend[$i])){
		
		# in Grossbuchstaben
		if (preg_match("/([a-z]+)/",$mcday[$i])){$mcday[$i] = strtoupper($mcday[$i]);}
		if (preg_match("/([a-z]+)/",$mcbeg[$i])){$mcbeg[$i] = strtoupper($mcbeg[$i]);}
		if (preg_match("/([a-z]+)/",$mcend[$i])){$mcend[$i] = strtoupper($mcend[$i]);}
		
		# führende Nullen weg
		$mcbeg[$i] = preg_replace ( '/0([0-9])/', '$1', $mcbeg[$i]);
		$mcend[$i] = preg_replace ( '/0([0-9])/', '$1', $mcend[$i]);
		 
		# TimeRange auf Überschneidung mit vorhandenen checken außer mit eigener alter TR da diese
		# ja geändert werden soll
		if(check_timerange($mcday[$i],$mcbeg[$i],$mcend[$i],$nodeDN,$oldmctimerange)){
		
			$mctimerange = $mcday[$i]."_".$mcbeg[$i]."_".$mcend[$i];
			$entrymodtr ['timerange'][$i] = $mctimerange;
			$modtr = 1;
			
		}
		else{
			$mesg = "Es existiert bereits eine MachineConfig, die sich mit der eingegebenen Time Range
						&uuml;berschneidet!<br>
						Bitte geben Sie eine andere Time Range ein.<br><br>";
			$entrymodtr ['timerange'][$i] = $oldmctimerange;
		}
	}
	else{
		$mesg = "Falsche Syntax in der Timerange-Eingabe!<br>
					Bitte geben Sie die erneut Time Range ein.<br><br>";
		$entrymodtr ['timerange'][$i] = $oldmctimerange;
	}
	
}


elseif (  $mcday[$i] == "" || $mcbeg[$i] == "" || $mcend[$i] == "" || $mcbeg[$i] > $mcend[$i]){

	$mesg = "Sie haben die Time Range <b>Nr.".$i."</b> nicht vollst&auml;ndig angegeben. Diese ist aber ein notwendiges Attribut.<br>
				Diese Time Range wird nicht bearbeitet.<br><br>";
	$entrymodtr ['timerange'][$i] = $oldmctimerange;
}

else{$entrymodtr ['timerange'][$i] = $oldmctimerange;}
} # Ende for-Schleife für jede Timerange
# jetzt noch alle gesammelten Änderungen Durchführen ...
if ($modtr == 1){
	# erst ändern
	echo "&Auml;ndern: "; print_r($entrymodtr); echo "<br>";
	if($result = ldap_mod_replace($ds,$mcDN,$entrymodtr)){
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
	if($result = ldap_mod_del($ds,$mcDN,$entrydeltr)){
		$mesg = "TimeRanges erfolgreich gel&ouml;scht<br><br>";
	}else{
		$mesg = "Fehler beim l&ouml;schen der TimeRanges!<br><br>";
	}
}elseif(count($deltr) != 0 && $modtr == 1){
	echo "Nur &Auml;ndern (gleichzeitig L&ouml;schen und &Auml;ndern geht nicht)";
}

#####################################
# TimeRange hinzufügen

if ( $newmcday != "" && $newmcbeg != "" && $newmcend != "" && $newmcbeg <= $newmcend ){

	# TimeRange Syntax checken
	$syntax = new Syntaxcheck;
	if ($syntax->check_timerange_syntax($newmcday,$newmcbeg,$newmcend)){
		
		# in Grossbuchstaben
		if (preg_match("/([a-z]+)/",$newmcday)){$newmcday = strtoupper($newmcday);}
		if (preg_match("/([a-z]+)/",$newmcbeg)){$newmcbeg = strtoupper($newmcbeg);}
		if (preg_match("/([a-z]+)/",$newmcend)){$newmcend = strtoupper($newmcend);}
		
		# führende Nullen weg
		$newmcbeg = preg_replace ( '/0([0-9])/', '$1', $newmcbeg);
		$newmcend = preg_replace ( '/0([0-9])/', '$1', $newmcend);
		
		# TimeRange auf Überschneidung mit vorhandenen checken
		if(check_timerange($newmcday,$newmcbeg,$newmcend,$nodeDN,"")){
		
			$newmctimerange = $newmcday."_".$newmcbeg."_".$newmcend;
			$entrytr ['timerange'] = $newmctimerange;
			if($result = ldap_mod_add($ds,$mcDN,$entrytr)){
				$mesg = "Zus&auml;tzliche TimeRange erfolgreich eingetragen<br><br>";
			}else{
				$mesg = "Fehler beim eintragen der zus&auml;tzlichen TimeRange!<br><br>";
			}
		}else{
			$mesg = "Es existiert bereits eine MachineConfig, die sich mit der eingegebenen Time Range
						&uuml;berschneidet!<br>
						Bitte geben Sie eine andere Time Range ein.<br><br>";
		}
	}else{
		$mesg = "Falsche Syntax in der Timerange-Eingabe!<br>
					Bitte geben Sie die erneut Time Range ein.<br><br>";
	}
}

#####################################
# MC Description
 
if ( $oldmcdesc == $mcdesc ){
	# $mesg = "keine Aenderung<br>";
}

if ( $oldmcdesc == "" && $mcdesc != "" ){
	echo "MC-Beschreibung neu anlegen<br>";
	# hier noch Syntaxcheck
	$entrymc['description'] = $mcdesc;
	if(ldap_mod_add($ds,$mcDN,$entrymc)){
		$mesg = "MC-Beschreibung erfolgreich eingetragen<br><br>";
	}else{
		$mesg = "Fehler beim eintragen der MC-Beschreibung<br><br>";
	}
}

if ( $oldmcdesc != "" && $mcdesc != "" && $oldmcdesc != $mcdesc ){
	echo "MC-Beschreibung aendern<br>";
	# hier noch Syntaxcheck
	$entrymc['description'] = $mcdesc;
	if(ldap_mod_replace($ds,$mcDN,$entrymc)){
		$mesg = "MC-Beschreibung erfolgreich geaendert<br><br>";
	}else{
		$mesg = "Fehler beim aendern der MC-Beschreibung<br><br>";
	}
}

if ( $oldmcdesc != "" && $mcdesc == "" ){
	echo "Rechner-Beschreibung loeschen<br>";
	# hier noch Syntaxcheck
	$entrymc['description'] = $oldmcdesc;
	if(ldap_mod_del($ds,$mcDN,$entrymc)){
		$mesg = "MC-Beschreibung erfolgreich geloescht<br><br>";
	}else{
		$mesg = "Fehler beim loeschen der MC-Beschreibung<br><br>";
	}
}

#####################################
# Crontab Entries

if (count($crontab) != 0 && (count(array_diff_assoc($crontab,$oldcrontab)) != 0 || count(array_diff_assoc($oldcrontab,$crontab)) != 0)  ){
	
	$crontabentry = array();
	foreach ($crontab as $ct){
		if ($ct != ""){
			$crontabentry ['crontab-entries'][] = $ct;
		}
	}
	$oldcrontabentry = array();
	foreach ($oldcrontab as $oldct){
		if ($oldct != ""){
			$oldcrontabentry ['crontab-entries'][] = $oldct;
		}
	}
	
	if (count($crontabentry) == 0){
		echo "Crontab Eintrag l&ouml;schen<br>";
		ldap_mod_del($ds,$mcDN,$oldcrontabentry);
	}else{
		echo "Crontab Eintrag &auml;ndern<br>";
		print_r($crontabentry);
		ldap_mod_replace($ds,$mcDN,$crontabentry);
	}
}
 
#####################################
# Restliche Attribute

$entryadd = array();
$entrymod = array();
$entrydel = array();

foreach (array_keys($atts) as $key){
	
	if ( $oldatts[$key] == $atts[$key] ){
	
	}
	if ( $oldatts[$key] == "" && $atts[$key] != "" ){
		# hier noch Syntaxcheck
		$entryadd[$key] = $atts[$key];
	}
	if ( $oldatts[$key] != "" && $atts[$key] != "" && $oldatts[$key] != $atts[$key] ){
		# hier noch Syntaxcheck
		$entrymod[$key] = $atts[$key];
	}
	if ( $oldatts[$key] != "" && $atts[$key] == "" ){
		# hier noch Syntaxcheck
		$entrydel[$key] = $oldatts[$key];
	}
}

#print_r($entryadd); echo "<br>";
#print_r($entrymod); echo "<br>";
#print_r($entrydel); echo "<br>";


if (count($entryadd) != 0 ){
	#print_r($entryadd); echo "<br>";
	#echo "neu anlegen<br>"; 
	foreach (array_keys($entryadd) as $key){
		$addatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_add($ds,$mcDN,$entryadd)){
		$mesg = "Attribute ".$addatts." erfolgreich eingetragen<br><br>";
	}else{
		$mesg = "Fehler beim eintragen der Attribute ".$addatts."<br><br>";
	}
}

if (count($entrymod) != 0 ){
	#print_r($entrymod); echo "<br>";
	#echo "&auml;ndern<br>";
	foreach (array_keys($entrymod) as $key){
		$modatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_replace($ds,$mcDN,$entrymod)){
		$mesg = "Attribute ".$modatts." erfolgreich geaendert<br><br>";
	}else{
		$mesg = "Fehler beim aendern der Attribute ".$modatts."<br><br>";
	}
}

if (count($entrydel) != 0 ){
	#print_r($entrydel); echo "<br>";
	#echo "l&ouml;schen<br>";
	foreach (array_keys($entrydel) as $key){
		$delatts .= "<b>".$key."</b>,";
	}
	if(ldap_mod_del($ds,$mcDN,$entrydel)){
		$mesg = "Attribute ".$delatts." erfolgreich geloescht<br><br>";
	}else{
		$mesg = "Fehler beim loeschen der Attribute ".$delatts."<br><br>";
	}
}




$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>