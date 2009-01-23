<?php
include('../standard_header.inc.php');

$meDN = $_GET['dn'];
$oldpos = $_GET['pos'];

$pxeDN = $_GET['pxedn'];
$mnr = $_GET['mnr'];
$sbmnr = $_GET['sbmnr'];

$oldpos = preg_replace ( '/0([0-9])/', '$1', $oldpos);
if ($oldpos != 1){
	
	$newpos = $oldpos-1;
	if (strlen($newpos) == 1){
		$newpos = "0".$newpos;
	}
	if (strlen($oldpos) == 1){
		$oldpos = "0".$oldpos;
	}
	
	if ($secmeDN = get_dn_menuposition($pxeDN,$newpos)){
		#echo "other meDN:"; print_r($secmeDN); echo "<br>";
		$entrysec ['menuposition'] = $oldpos;
		if ($result = ldap_mod_replace($ds,$secmeDN,$entrysec)){
			$entrymenu ['menuposition'] = $newpos;
			$result = ldap_mod_replace($ds,$meDN,$entrymenu);
		}
		
	}
}
$seconds = 0;
$url = "pxe.php?dn=".$pxeDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&#menu";
$mesg = "";
#$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
#			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

?>