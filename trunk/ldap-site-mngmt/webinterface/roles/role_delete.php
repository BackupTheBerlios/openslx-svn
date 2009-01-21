<?php

include('../standard_header.inc.php');


$deluser = $_POST['deluser'];
$role = $_POST['role'];
$menr = $_POST['menr'];

echo "
<html>
<head>
	<title>Roles Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>";

if (isset($_POST['deluser'])){

	# print_r($deluser);echo "<br>";
	# print_r($role);echo "<br>";
	# print_r($menr);echo "<br>";
	
	$url = 'role_show.php?role='.$role.'&sbmnr='.$menr;
	$mesg = "";

	foreach ($deluser as $item){
		$exp = explode('_',$item);
		$deluserDN = $exp[0];
		$deluserUID = $exp[1];
		# print_r($deluserDN);echo "<br>";
		# print_r($deluserUID);echo "<br>";
		$res = delete_role_member($deluserDN,$role,$auDN,$domDN);
		 if ($res == 1){
			$mesg .= "Der Benutzer <b>".$deluserUID."</b> wurde erfolgreich aus der Rolle <b>".$role."</b> entfernt.<br>";
		}else{
		  	$mesg .= "<br><b>Fehler!</b> Der Benutzer <b>".$deluserUID."</b> konnte nicht entfernt werden<br>";
		}
	}
	$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
				Falls nicht, klicken Sie hier <a href='role_show.php?role=$role&sbmnr=$menr' style='publink'>back</a><br><br>";
	redirect(3, $url, $mesg, $addSessionId = TRUE);
	
}

else {
	$mesg .= "<br>Sie haben keinen Benutzer ausgew&auml;hlt<br><br>
				Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
				Falls nicht, klicken Sie hier <a href='role_show.php?role=$role&sbmnr=$menr' style='publink'>back</a>";
	redirect(3, $url, $mesg, $addSessionId = TRUE);
}

echo "</td></tr></table></body>
</html>";
?>