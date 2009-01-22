<?php
include('../standard_header.inc.php');

$dn = $_POST['dn'];
$name = $_POST['name'];
$delurl = $_POST['delurl'];
$backurl = $_POST['backurl'];
$successurl = $_POST['successurl'];

$type = $_POST['type'];
$pxedn = $_POST['pxedn'];

echo "
<html>  
<head>
	<title>AU Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
	<tr>
		<td>";


if($type == "gbm"){
	$gbmDN = $dn;
	$attribs = array("dn");
	if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(&(objectclass=MenuEntry)(genericmenuentrydn=$gbmDN))", $attribs, "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	else{
		$result = ldapArraySauber($result);
		if (count($result) > 0){
			echo "Folgende Men&uuml; Eintr&auml;ge sind davon betroffen: <br><br>";
			foreach ($result as $item){
				$exp = ldap_explode_dn($item['dn'], 1);
				echo "Men&uuml; Eintrag <b>".$exp[0]."</b> in PXE Bootmen&uuml; <b>".$exp[1]."</b> &nbsp;&nbsp;[ Abteilung: ".$exp[4]." ]<br>";
			}
		}
		else{
			echo "Keine Men&uuml; Eintr&auml;ge davon betroffen!<br>";
		}
	}	
}

if($type == "rbs"){
	$rbsDN = $dn;
	$attribs = array("dn");
	if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(&(objectclass=PXEConfig)(rbservicedn=$rbsDN))", $attribs, "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	else{
		$result = ldapArraySauber($result);
		if (count($result) > 0){
			echo "Folgende PXE Boot Men&uuml;s sind davon betroffen: <br><br>";
			foreach ($result as $item){
				$exp = ldap_explode_dn($item['dn'], 1);
				echo "PXE Boot Men&uuml; <b>".$exp[0]."</b> an Objekt <b>".$exp[1]."</b> &nbsp;&nbsp;[ Abteilung: ".$exp[3]." ]<br>";
			}
		}
		else{
			echo "Keine PXE Boot Men&uuml;s davon betroffen!<br>";
		}
	}	
}

		echo "<br><br>
		Wollen Sie das Objekt <b>".$name."</b> wirklich l&ouml;schen?<br><br>
			<form action='".$delurl."' method='post'>
				Falls ja:<br><br>
				<input type='hidden' name='dn' value='".$dn."'>
				<input type='hidden' name='name' value='".$name."'>
				<input type='hidden' name='successurl' value='".$successurl."'>
				<input type='hidden' name='pxedn' value='".$pxedn."'>
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