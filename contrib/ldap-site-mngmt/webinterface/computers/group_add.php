<?php
include('../standard_header.inc.php');

$groupcn = $_POST['groupcn'];
$groupdesc = $_POST['groupdesc'];
$addmember = $_POST['addmember'];

$groupcn = htmlentities($groupcn);
$groupdesc = htmlentities($groupdesc);

/*
echo "AU dn:"; print_r($auDN); echo "<br>";
echo "groupcn:"; print_r($groupcn); echo "<br>";
echo "groupdesc:"; print_r($groupdesc); echo "<br>";
echo "members to add:"; print_r($addmember); echo "<br>";
*/

$seconds = 2;
 
echo "
<html>
<head>
	<title>AU Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $groupcn != ""){
	
	# Formulareingaben anpassen
	$expgr = explode(" ",$groupcn);
	foreach ($expgr as $word){$expuc[] = ucfirst($word);}
	$groupcn = implode(" ",$expuc);
	$groupcn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $groupcn);
	
	# Host Objekt anlegen
	$brothers = get_hosts($auDN,array("groupcn"));
	$brother = 0;
	foreach ($brothers as $item){
		if( $item['groupcn'] == $groupcn ){
			$mesg = "Es existiert bereits eine Gruppe mit dem eingegebenen Namen (CN)!<br>
						Bitte geben Sie einen anderen Namen (CN) ein.<br><br>";
			$get_groupdesc = str_replace ( " ", "_", $groupdesc );
			$url = "new_group.php?groupcn=Hier_anderen_CN_eingeben&groupdesc=".$get_groupdesc;
			$brother = 1;
			break;
		}
	}
	if ($brother == 0){
		$groupDN = "cn=".$groupcn.",cn=groups,".$auDN;
		# print_r($groupDN); echo "<br>";
		
		if (add_group($groupDN,$groupcn,$groupdesc,$addmember)){			
			$mesg .= "<br>Neue Rechnergruppe erfolgreich angelegt<br>";
		}
		else{
			$mesg .= "<br>Fehler beim anlegen der Rechnergruppe!<br>";
		}
		
		$url = 'groupoverview.php';
	}
}


elseif ( $groupcn == ""){
	
	$get_groupdesc = str_replace ( " ", "_", $groupdesc );
	$mesg = "Sie haben den CN der neuen Gruppe nicht angegeben. Dieser ist aber ein notwendiges Attribut.<br>
				Bitte geben Sie ihn an.<br><br>";
	$url = "new_group.php?ou=Hier_CN_eingeben&groupdesc=".$get_groupdesc;
}




$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>