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
include('lib/dns_management_functions.php');
include('lib/rbs_management_functions.php');
include("class.FastTemplate.php");

//print_r($_SESSION['status']);
if ( !isset($_SESSION['status']) ){
	redirect(0, $START_PATH."index.php","",$addSessionId = FALSE);
	exit;
}
if ( $_SESSION['status'] != "in" ){
	//$_SESSION['status'] != "out";
	redirect(0, $START_PATH."index.php","",$addSessionId = FALSE);
	exit;
}

#print_r($_SERVER['REMOTE_ADDR']);

 // Fehlerausgabe im Browser anschalten
ini_set('display_errors', 0);
// nur Laufzeitfehler ausgeben
error_reporting(E_ALL ^ E_NOTICE | E_STRICT);

$uid = $_SESSION['uid'];
$userPassword = $_SESSION['userPassword'];
$userDN = $_SESSION['dn'];
$usercn = $_SESSION['cn'];
$auDN = $_SESSION['audn'];
#echo "auDN: "; print_r($auDN); echo "<br>";

$all_roles = $_SESSION['all_roles'];
#echo "all roles: "; print_r($all_roles); echo "<br>";
$rollen = $all_roles[$auDN][roles];
#echo "rollen: "; print_r($rollen); echo "<br>";
if (!$rollen) {
	redirect(0, $START_PATH."start.php","",$addSessionId = FALSE);
	exit;
}

if (!($ds = uniLdapConnect($uid,$userPassword))){
	echo "<html>
			<head>
				<title>Zentrales Rechner / IP Management</title>
				<link rel='stylesheet' href='../styles.css' type='text/css'>
			</head>
			<body>
			<table border='0' cellpadding='30' cellspacing='0'> 
			<tr valign='middle'><td align='center'>
			<h3>Es konnte keine Verbindung zum LDAP Server hergestellt werden!</h3>
			</td></tr></table></body>
			</html>
			";
	die;
}

if ($auDN != ""){

   # AU Daten holen
   $attributes = array("ou","associateddomain","maxipblock","freeipblock","cn","description");
   $au_data = get_au_data($auDN,$attributes);
   $assocdom = $au_data[0]['associateddomain'];
   $au_ou = $au_data[0]['ou'];
   $au_cn = $au_data[0]['cn'];
   $au_desc = $au_data[0]['description'];
   $au_mipb = $au_data[0]['maxipblock'];
   #print_r($au_mipb);echo "<br>";
   natsort($au_mipb);
   #print_r($au_mipb);echo "<br>";
   $au_fipb = $au_data[0]['freeipblock'];
   
   # AU Domain Daten holen
   $domain_data = get_domain_data($auDN,array("dn"));
   
   $expAuDn = explode(",",$auDN);
   if ($expAuDn[1] == "ou=RIPM"){
   	$domDN = "ou=DNS,".$suffix;
   }
   else{$domDN = $domain_data[0]['dn']; }
   
   $domprefix = str_replace('.'.$domsuffix,'',$assocdom);
   # print_r($domprefix);

}

?>
