<?php
include('../standard_header.inc.php');

$dn = $_POST['dn'];
$name = $_POST['name'];
$delurl = $_POST['delurl'];
$backurl = $_POST['backurl'];
$successurl = $_POST['successurl'];
$mnr = $_POST['mnr'];

echo "
<html> 
<head>
	<title>AU Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
	<tr>
		<td>
		Wollen Sie das Objekt <b>".$name."</b> wirklich l&ouml;schen?<br><br>
			<form action='".$delurl."' method='post'>
				Falls ja:<br><br>
				<input type='hidden' name='dn' value='".$dn."'>
				<input type='hidden' name='name' value='".$name."'>
				<input type='hidden' name='successurl' value='".$successurl."'>
				<input type='hidden' name='mnr' value='".$mnr."'>
				<input type='Submit' name='apply' value='l&ouml;schen' class='small_loginform_button'><br><br>
			</form>
			<form action='".$backurl."' method='post'>
				Falls, nein:<br><br>
				<input type='Submit' name='apply' value='zur&uuml;ck' class='small_loginform_button'>
			</form>
		</td>
	</tr>
</table>
</body>
</html>";
?>