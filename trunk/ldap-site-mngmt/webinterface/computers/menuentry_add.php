<?php
include('../standard_header.inc.php');

$mecn = $_POST['mecn'];  $mecn = htmlentities($mecn);
$gbmDN = $_POST['gbm'];
$menpos = $_POST['menpos'];
$maxpos = $_POST['maxpos'];

$typ = $_POST['typ'];
$pxeDN = $_POST['pxedn'];
$timespan = $_POST['timerange'];
$mnr = $_POST['mnr'];
$sbmnr = $_POST['sbmnr'];
$mcnr = $_POST['mcnr'];

$meattribs = $_POST['attribs'];
if (count($meattribs) != 0){
	foreach (array_keys($meattribs) as $key){
		$meatts[$key] = htmlentities($meattribs[$key]);
	}
}
# print_r($meatts); echo "<br><br>";

# PXE Typ (computers/groups) für Submenulinks
$pxearray = ldap_explode_dn($pxeDN, 1);
$pxetype = $pxearray[2];

$seconds = 2;
$get_mecn = str_replace ( " ", "_", $mecn );
$url = "pxe.php?dn=".$pxeDN."&mecn=".$get_mecn."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;

echo " 
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 
# switch wäre besser ... 
if ($typ == "newme" && $typ != "local" && $typ != "text" && $typ != "leer" && $typ != "submenu" ){

	if ( $mecn != "" && $mecn != "Hier_NAME_eintragen" && $gbmDN != "none" ){
	
		# Formulareingaben anpassen
		$expme = explode(" ",$mecn);
		foreach ($expme as $word){$expuc[] = ucfirst($word);}
		$mecn = implode(" ",$expuc);
		$mecn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $mecn);
		
		if ($menpos != ""){
			# Syntaxcheck Menüposition
			#$syntax = new Syntaxcheck;
			#if (!($syntax->check_menuposition($menpos))){
			#	$menpos = $maxpos;
			#}
		}else{
			$menpos = $maxpos;
		}
		if (strlen($menpos) == 1){
		$menpos = "0".$menpos;
		} 
		# nun doch führende Nullen erzwingen
		# also obsolet: $menpos = preg_replace ( '/0([0-9])/', '$1', $menpos);
	
		$meDN = "cn=".$mecn.",".$pxeDN;
				
		if (add_me($meDN,$mecn,$gbmDN,$menpos,$meatts,$pxeDN)){			
			$mesg .= "<br>Neuen Men&uuml; Eintrag erfolgreich angelegt<br>";
			$url = "pxe.php?dn=".$pxeDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;;
			}
		else{
			$mesg .= "<br>Fehler beim anlegen des Men&uuml; Eintrags!<br>";
		}
	}
	
	elseif ( $mecn == "" || $mecn == "Hier_NAME_eintragen" || $gbmDN == "none" ){
	
		$mesg = "Sie haben den Namen des neuen Men&uuml; Eintrags nicht angegeben oder kein
					Generisches Boot Image ausgew&auml;hlt. Beide sind aber ein notwendige Attribute.<br>
					Bitte geben Sie sie an.<br><br>";
		$url = "new_menuentry.php?mecn=Hier_NAME_eintragen&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;
	}
}

# Localboot Zeile hinzufügen 
elseif ($typ == "local" && $typ != "newme" && $typ != "text" && $typ != "leer" && $typ != "submenu" ){

	# Menu Position
	$menpos = $_POST['localpos'];
	if ($menpos != ""){
		# Syntaxcheck Menüposition
		#$syntax = new Syntaxcheck;
		#if (!($syntax->check_menuposition($menpos))){
		#	$menpos = $maxpos;
		#}
	}else{
		$menpos = $maxpos;
	}
	if (strlen($menpos) == 1){
		$menpos = "0".$menpos;
	} 
	# nun doch führende Nullen erzwingen
	# also obsolet: $menpos = preg_replace ( '/0([0-9])/', '$1', $menpos);
	
	# CN bilden
	$brothers = get_menuentries($pxeDN,array("dn","cn"));
	$i=1;
	$localcn = "localboot".$i;
	if(count($brothers) != 0){
		for ($c=0; $c<count($brothers); $c++){
			foreach ($brothers as $item){
				if ($localcn == strtolower($item['cn'])){
					$i++;
					$localcn = "localboot".$i;
				}
			}
		}
	}
	$meDN = "cn=".$localcn.",".$pxeDN;
	$entry ['objectclass'][0] = "MenuEntry";
	$entry ['objectclass'][1] = "top";
	$entry ['cn'] = $localcn;
	$entry ['menuposition'] = $menpos;
	$entry ['label'] = $localcn;
	$entry ['menulabel'] = $_POST['locallabel'];
	$entry ['menupasswd'] = $_POST['localpasswd'];
	$entry ['localboot'] = "level 0";
	$pos = preg_replace ( '/0([0-9])/', '$1', $menpos);
	increment_menupositions($pxeDN,$pos); # andere jeweils um 1 erhöhen
	if (ldap_add($ds,$meDN,$entry)){
		$mesg .= "Localboot Zeile erfolgeich an Position ".$menpos." eingetragen";
	}else{
		$mesg .= "Fehler beim eintragen der Localboot Zeile!";
	}
	$url = "pxe.php?dn=".$pxeDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;
}


# Text Zeile hinzufügen 
elseif ($typ == "text" && $typ != "newme" && $typ != "local" && $typ != "leer" && $typ != "submenu" ){

	# Menu Position
	$menpos = $_POST['textpos'];
	if ($menpos != ""){
		# Syntaxcheck Menüposition
		#$syntax = new Syntaxcheck;
		#if (!($syntax->check_menuposition($menpos))){
		#	$menpos = $maxpos;
		#}
	}else{
		$menpos = $maxpos;
	}
	if (strlen($menpos) == 1){
		$menpos = "0".$menpos;
	} 
	# nun doch führende Nullen erzwingen
	# also obsolet: $menpos = preg_replace ( '/0([0-9])/', '$1', $menpos);
	
	$text = $_POST['text'];
	if($text != "" && $text != "TEXT"){
		$brothers = get_menuentries($pxeDN,array("dn","cn"));
		$i=1;
		$textcn = "textzeile".$i;
		if(count($brothers) != 0){
			for ($c=0; $c<count($brothers); $c++){
				foreach ($brothers as $item){
					if ($textcn == strtolower($item['cn'])){
						$i++;
						$textcn = "textzeile".$i;
					}
				}
			}
		}
		$meDN = "cn=".$textcn.",".$pxeDN;
		$entry ['objectclass'][0] = "MenuEntry";
		$entry ['objectclass'][1] = "top";
		$entry ['cn'] = $textcn;
		$entry ['menuposition'] = $menpos;
		$entry ['label'] = $text;
		$entry ['kernel'] = "menu.c32";
		# Submenulink auf sich selbst
		$pxedata = get_node_data($pxeDN,array("filename"));
		$entry ['submenulink'] = "self";
		
		$pos = preg_replace ( '/0([0-9])/', '$1', $menpos);
		increment_menupositions($pxeDN,$pos); # andere jeweils um 1 erhöhen
		if (ldap_add($ds,$meDN,$entry)){
			$mesg .= "Textzeile erfolgeich an Position ".$menpos." eingetragen";
		}else{
			$mesg .= "Fehler beim eintragen der Textzeile!";
		}
		$url = "pxe.php?dn=".$pxeDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;
	}
}


elseif ($typ == "leer" && $typ != "newme" && $typ != "local" && $typ != "text" && $typ != "submenu" ){
	
	# Menu Position
	$menpos = $_POST['leerpos'];
	if ($menpos != ""){
		# Syntaxcheck Menüposition
		#$syntax = new Syntaxcheck;
		#if (!($syntax->check_menuposition($menpos))){
		#	$menpos = $maxpos;
		#}
	}else{
		$menpos = $maxpos;
	}
	if (strlen($menpos) == 1){
		$menpos = "0".$menpos;
	} 
	# nun doch führende Nullen erzwingen
	# also obsolet: $menpos = preg_replace ( '/0([0-9])/', '$1', $menpos);
	
	# CN bilden
	$brothers = get_menuentries($pxeDN,array("dn","cn"));
	$i=1;
	$leercn = "leerzeile".$i;
	if(count($brothers) != 0){
		for ($c=0; $c<count($brothers); $c++){
			foreach ($brothers as $item){
				if ($leercn == strtolower($item['cn'])){
					$i++;
					$leercn = "leerzeile".$i;
				}
			}
		}
	}
	$meDN = "cn=".$leercn.",".$pxeDN;
	$entry ['objectclass'][0] = "MenuEntry";
	$entry ['objectclass'][1] = "top";
	$entry ['cn'] = $leercn;
	$entry ['menuposition'] = $menpos;
	$entry ['kernel'] = "menu.c32";
	# Submenulink auf sich selbst
	$pxedata = get_node_data($pxeDN,array("filename"));
	$entry ['submenulink'] = "self";
	
	# wieder führende Nullen weg für increment_menpos 
	$pos = preg_replace ( '/0([0-9])/', '$1', $menpos);
	increment_menupositions($pxeDN,$pos); # andere jeweils um 1 erhöhen
	if (ldap_add($ds,$meDN,$entry)){
		$mesg .= "Leerzeile erfolgeich an Position ".$menpos." eingetragen";
	}else{
		$mesg .= "Fehler beim eintragen der Leerzeile!";
	}
	$url = "pxe.php?dn=".$pxeDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;
}


elseif ($typ == "submenu" && $typ != "newme" && $typ != "local" && $typ != "text" && $typ != "leer" ){
}

$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>