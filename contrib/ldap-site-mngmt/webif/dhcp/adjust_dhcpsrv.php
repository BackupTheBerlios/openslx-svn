<?php
include('../standard_header.inc.php');

#$dhcpdn = $_POST['dhcpdn'];
$dhcpdn = $DHCP_SERVICE;
#$dhcpdn = "cn=DHCP_RZ,cn=dhcp,ou=Rechenzentrum,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de";

$seconds = 200;
$url = "dhcpservice.php?dn=".$dhcpdn;
 
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
# DHCP Service CN (DN) 

$filter = "(&(|(objectClass=dhcpSubnet)(objectclass=dhcpHost))(dhcphlpcont=*))";
if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, $filter, array("dn"), "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
}
$result = ldapArraySauber($result);
$modentry ['dhcphlpcont'] = $dhcpdn;
$number = count($result);
echo "Number of DHCP Entries: $number<br><br>";
foreach ($result as $item){
	$modres = ldap_mod_replace($ds, $item['dn'], $modentry);
	if ( $modres ){
		echo "changed $item[dn]<br>";
	}else{
		echo "<b>ERROR</b> changing $item[dn]<br>";
	}
}

/*
# alle hosts ohne hwaddress in dhcpservice (alle host die nicht in dhcp sein dürften ...)
$filter = "(&(objectClass=Host)(dhcphlpcont=*)(!(hwaddress=*)))";
if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, $filter, array("dn"), "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
}
$result = ldapArraySauber($result);
$modentry ['dhcphlpcont'] = array();
$number = count($result);
echo "Number of DHCP Entries: $number<br><br>";
foreach ($result as $item){
	$modres = ldap_mod_del($ds, $item['dn'], $modentry);
	if ( $modres ){
		echo "deleted $item[dn]<br>";
	}else{
		echo "<b>ERROR</b> changing $item[dn]<br>";
	}
}
*/



$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>