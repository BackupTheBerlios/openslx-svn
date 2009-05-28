<?php
include('../standard_header.inc.php');
$syntax = new Syntaxcheck;

$rbscn = $_POST['rbscn']; $rbscn = htmlentities($rbscn);

$nodeDN = "cn=rbs,".$auDN;

$rbsoffer = $auDN;
$tftpserverip = $_POST['tftpserverip'];


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

// $existing_rbs = get_rbservices($auDN,array("cn"));
// $new_mnr = count($existing_rbs) + 1;
// echo "RBS NEW MNR: $new_mnr ";

$get_rbscn = str_replace ( " ", "_", $rbscn );
$seconds = 300;
$url = "new_rbservice.php?&mnr=$mnr";
 
echo "
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>";

if ( $rbscn != "" && $rbscn != "Hier_RBS_NAME_eintragen" ){

	$rbscn = "RBS_".$rbscn;

	# Formulareingaben anpassen
	$exprbs = explode(" ",$rbscn);
	foreach ($exprbs as $word){$expuc[] = ucfirst($word);}
	$rbscn = implode(" ",$expuc);
	$rbscn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $rbscn);
	
	$rbsDN = "cn=".$rbscn.",".$nodeDN;
// 	print_r($rbsDN); echo "<br><br>";
	
	# TFTP Server 
	if ($tftpserverip != ""){
		$tftpserverip = htmlentities($tftpserverip);
		
		if ( $syntax->check_ip_syntax($tftpserverip) ) {
			if ( check_tftpip_in_mipb($tftpserverip) ) {
				$atts ['tftpserverip'] = $tftpserverip;
			}
			else {
				$mesg .= "Gew&auml;hlte TFTP Server IP <b>$tftpserverip</b> nicht aus dem eigenem IP Bereich!<br>Nicht eingetragen!<br><br>";
			}
		}
		else {
			$mesg .= "Falsche IP Syntax!<br>TFTP Server IP <b>$tftpserverip</b> nicht eingetragen!<br>";
		}
	}
	
	if (add_rbs($rbsDN,$rbscn,$rbsoffer,$atts)){
		$mesg .= "<br>Remote Boot Service erfolgreich angelegt<br>";
		$url = "rbservice.php?rbsdn=$rbsDN&mnr=$mnr";
	}else{
		$mesg .= "<br>Fehler beim anlegen des Remote Boot Services!<br>";
	}
}

elseif ( $rbscn == "" || $rbscn == "Hier_RBS_NAME_eintragen" ) {

	$mesg = "Sie haben den Namen des neuen Remote Boot Service nicht angegeben. Dieser ist 
				aber ein notwendiges Attribut.<br><br>";
	$url = "new_rbservice.php?rbscn=Hier_RBS_NAME_eintragen&mnr=1";
}


$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>