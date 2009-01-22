<?php

include('../standard_header.inc.php');
# Filename of Template
$webseite = "au_show.dwt";

include('au_header.inc.php');

###############################################################################
# Menus

$mnr = 1; 
$sbmnr = -1; 

createMainMenu($rollen, $mainnr);
createAUMenu($rollen, $mnr, $auDN, $sbmnr);

###############################################################################
# MainpageData

# Parent AU, Email MainAdmin
$exp = explode(',',$auDN);
$parentau = array_slice($exp, 1, 1);
$parentau = substr($parentau[0],3);

if ( $parentau != "RIPM"){
   $length = count($exp);
   $out = array_slice($exp, 1, $length -1);
   $parentauDN = implode(',',$out);
   $rol = get_roles($parentauDN);
   $mainadminDN = $rol['MainAdmin'][0];
   $emailMA = get_user_data($mainadminDN, array("mail"));
   $emailCODE = "<a href'mailto:".$emailMA['mail']."' class='maillink' 	style='text-decoration:none'>".$emailMA['mail']."</a>";
}

$template->assign(array("OU" => $au_ou,
	"CN" => $au_cn,
	"DSC" => $au_desc,
	"AUDN" => $auDN,
	"PARENTAU" => $parentau,
	"EMAILMA" => $emailCODE));

# MaxIPBlocks
$mipb = $au_mipb;
$mipbs = "";
if (count($mipb) > 1) {
	for ($i=0; $i < count($mipb) - 1; $i++) {
		$exp = explode('_',$mipb[$i]);
		$mipbs .= "$exp[0]&nbsp; - &nbsp;$exp[1]<br>";
	}
	$exp = explode('_',$mipb[$i]);
	$mipbs .= "$exp[0]&nbsp; - &nbsp;$exp[1]";
	$template->assign(array("MIPBS" => $mipbs));
}
elseif (count($mipb) == 1) {
	$exp = explode('_',$mipb);
	$mipbs .= "$exp[0]&nbsp; - &nbsp;$exp[1]";
	$template->assign(array("MIPBS" => $mipbs));
}
else {
	$template->assign(array("MIPBS" => $mipbs));
}


###############################################################################
# Footer

include("au_footer.inc.php");

?>