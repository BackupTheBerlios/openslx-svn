<?php
include('../standard_header.inc.php');

$mecn = $_POST['mecn'];  $mecn = htmlentities($mecn);
$oldmecn = $_POST['oldmecn'];

$menpos = $_POST['menpos'];
if (strlen($menpos) == 1){
	$menpos = "0".$menpos;
} 
$oldmenpos = $_POST['oldmenpos'];
if (strlen($oldmenpos) == 1){
	$oldmenpos = "0".$oldmenpos;
} 

$meDN = $_POST['medn'];
$pxeDN = $_POST['pxedn'];
$mnr = $_POST['mnr'];
$sbmnr = $_POST['sbmnr'];
$mcnr = $_POST['mcnr'];

$attribs = $_POST['attribs'];
if (count($attribs) != 0){
	foreach (array_keys($attribs) as $key){
		$atts[$key] = htmlentities($attribs[$key]);
	}
}
# print_r($meatts); echo "<br><br>";
$oldattribs = $_POST['oldattribs'];
if (count($oldattribs) != 0){
	foreach (array_keys($oldattribs) as $key){
		$oldatts[$key] = htmlentities($oldattribs[$key]);
	}
}
#print_r($oldatts); echo "<br><br>";



$seconds = 2;
$get_mecn = str_replace ( " ", "_", $mecn );
$url = "menuentry.php?dn=".$meDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;

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
# ME CN (DN) 

if ( $oldmecn == $mecn ){
	# $mesg = "keine Aenderung<br>";
}

if ( $oldmecn != "" && $mecn != "" && $oldmecn != $mecn ){
	echo "Men&uuml; Eintrag Name aendern<br>";
	# hier noch Syntaxcheck
	# Formulareingaben anpassen
	$expme = explode(" ",$mecn);
	foreach ($expme as $word){$expuc[] = ucfirst($word);}
	$mecn = implode(" ",$expuc);
	$mecn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $mecn);
	
	
	$newmeDN = "cn=".$mecn.",".$pxeDN;
	print_r($newmeDN); echo "<br><br>";
	
	if(modify_me_dn($meDN, $newmeDN)){
		$mesg = "Men&uuml; Eintrag Name erfolgreich ge&auml;ndert<br><br>";
		$meDN = $newmeDN;
	}else{
		$mesg = "Fehler beim &auml;ndern des PMen&uuml; Eintrag Namen!<br><br>";
	}
	
	
	# newsubmenu holen...
	$url = "menuentry.php?dn=".$newmeDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;
}

if ( $oldmecn != "" && $mecn == "" ){
	echo "Men&uuml; Eintrag Name loeschen!<br> 
			Dieses ist Teil des DN, Sie werden den Men&uuml; Eintrag komplett l&ouml;schen<br><br>";
	echo "Wollen Sie den Men&uuml; Eintrag <b>".$oldmecn."</b> wirklich l&ouml;schen?<br><br>
			<form action='menuentry_delete.php' method='post'>
				Falls ja:<br><br>
				<input type='hidden' name='dn' value='".$meDN."'>
				<input type='hidden' name='name' value='".$oldmecn."'>
				<input type='Submit' name='apply' value='l&ouml;schen' class='small_loginform_button'><br><br>
			</form>
			<form action='".$url."' method='post'>
				Falls, nein:<br><br>
				<input type='Submit' name='apply' value='zur&uuml;ck' class='small_loginform_button'>
			</form>";
			$seconds = 600;
}


###################################
# Menu Position

if ( $menpos == $oldmenpos || $menpos == "" ){
	# keine Änderung
}

if ( $menpos != "" && $oldmenpos != $menpos ){
	echo "Men&uuml; Position &auml;ndern<br><br>";
	# Syntax Check fehlt noch 
	
	# switch partner finden 
	$secmeDN = get_dn_menuposition($pxeDN,$menpos);
	$entrysec ['menuposition'] = $oldmenpos;
	if (ldap_mod_replace($ds,$secmeDN,$entrysec)){
		$entry ['menuposition'] = $menpos;
		if (ldap_mod_replace($ds,$meDN,$entry)){
			#cleanup_menupositions($pxeDN);
			$mesg .= "Men&uuml; Position erfolgeich nach <b>".$menpos."</b> ge&auml;ndert";
		}else{
			$mesg .= "Fehler beim &auml;ndern der Men&uuml; Position!";
		}
	}else{
		$mesg .= "Fehler beim &auml;ndern der Men&uuml; Position!";
	}
}

###################################
# restliche Attribute

$entryadd = array();
$entrymod = array();
$entrydel = array();

foreach (array_keys($atts) as $key){
	
	if ( $oldatts[$key] == $atts[$key] ){
		# nix 
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
	if(ldap_mod_add($ds,$meDN,$entryadd)){
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
	if(ldap_mod_replace($ds,$meDN,$entrymod)){
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
	if(ldap_mod_del($ds,$meDN,$entrydel)){
		$mesg = "Attribute ".$delatts." erfolgreich geloescht<br><br>";
	}else{
		$mesg = "Fehler beim loeschen der Attribute ".$delatts."<br><br>";
	}
}

###################################
# Ende, noch Redirect


$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>