<?php

include('../standard_header.inc.php');


$adduser = $_POST['adduser'];
$role = $_POST['role'];
$menr = $_POST['menr']; 

$exp = explode('_',$adduser);
$adduserDN = $exp[0];
$adduserUID = $exp[1];
 
echo "
<html>
<head>
	<title>Administrative Unit Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

# print_r($adduser);echo "<br>";
# print_r($adduserDN);echo "<br>";
# print_r($adduserUID);echo "<br>";
# print_r($role);echo "<br>";
# print_r($menr);echo "<br><br>";

$url = 'role_show.php?role='.$role.'&sbmnr='.$menr;

if ($adduser != 'none'){
	$res = new_role_member($adduserDN,$role,$auDN,$domDN);
	if ($res == 1){
		$mesg = "Der Benutzer <b>".$adduserUID."</b> wurde erfolgreich als neuer <b>".$role."</b> aufgenommen.<br><br>";
	}else{
		$mesg = "Fehler! Der Benutzer <b>".$adduserUID."</b> konnte nicht aufgenommen werden<br><br>";
	}
	$mesg .= "Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
				Falls nicht, klicken Sie hier <a href='role_show.php?role=$role&sbmnr=$menr' style='publink'>back</a>";
	redirect(3, $url, $mesg, $addSessionId = TRUE);
}

else {
	$mesg = "Sie haben keinen Benutzer ausgew&auml;hlt<br><br>
				Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>
				Falls nicht, klicken Sie hier <a href='role_show.php?role=$role&sbmnr=$menr' style='publink'>back</a>";
	redirect(3, $url, $mesg, $addSessionId = TRUE);
}

echo "</td></tr></table></body>
</html>";
?>