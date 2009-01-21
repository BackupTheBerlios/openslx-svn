<?php
session_cache_expire(30);
session_start();

include('lib/config.inc.php');
include('lib/ldap.inc.php');
include('lib/ldap2.inc.php');
include('lib/commonlib.inc.php');
include('syntax_check.php');
include('lib/au_management_functions.php');
include('lib/ip_management_functions.php');
include('lib/host_management_functions.php');
include('lib/dhcp_management_functions.php');
include('lib/rbs_management_functions.php');


$uid = $_SESSION['uid'];
$userPassword = $_SESSION['userPassword'];
$userDN = $_SESSION['dn'];
$usercn = $_SESSION['cn'];
$auDN = $_SESSION['audn'];
#echo "auDN: "; print_r($auDN); echo "<br>";
$rollen = $_SESSION['rollen'];
#echo "rollen: "; print_r($rollen); echo "<br>"; 


if (!($ds = uniLdapConnect($uid,$userPassword))){
	echo "<html>
			<head>
				<title>Rechner und IP Management</title>
				<link rel='stylesheet' href='../styles.css' type='text/css'>
			</head>
			<body>
			<table border='0' cellpadding='30' cellspacing='0'> 
			<tr><td>	
			Es konnte keine Verbindung zum LDAP Server hergestellt werden!
			</td></tr></table></body>
			</html>
			";
	die;
} 

# AU Daten holen
$attributes = array("ou","associateddomain","maxipblock","freeipblock","cn","description");
$au_data = get_au_data($auDN,$attributes);
$assocdom = $au_data[0]['associateddomain'];
$au_ou = $au_data[0]['ou'];
$au_cn = $au_data[0]['cn'];
$au_desc = $au_data[0]['description'];
$au_mipb = $au_data[0]['maxipblock'];
$au_fipb = $au_data[0]['freeipblock'];

# AU Domain Daten holen
$domain_data = get_domain_data($auDN,array("dn"));

$expAuDn = explode(",",$auDN);
if ($expAuDn[1] == "ou=RIPM"){
	$domDN = "ou=DNS,".$suffix;
}
else{$domDN = $domain_data[0]['dn']; echo "<br>";}

$domprefix = str_replace('.'.$domsuffix,'',$assocdom);
# print_r($domprefix);

?>