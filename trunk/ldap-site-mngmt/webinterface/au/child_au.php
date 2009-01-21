<?php

include('../standard_header.inc.php');
include("../class.FastTemplate.php");

# Filename of Template
$webseite = "child_au.dwt";

include('au_header.inc.php');


###############################################################################
# Menus

$mnr = 2;
$sbmnr = -1;

$sbmnr = $_GET['sbmnr'];

createMainMenu($rollen, $mainnr);
createAUMenu($rollen, $mnr, $auDN, $sbmnr);


###############################################################################
# MainPage Data

$childauDN = $_GET['dn'];

$childau = get_au_data($childauDN,array("dn","cn","ou","associateddomain","description","maxipblock"));
#print_r($childau);

$domprefix = str_replace('.uni-freiburg.de','',$childau[0]['associateddomain']);
#print_r($domprefix);

$template->assign(array("CHILDOU" => $childau[0]['ou'],
	"CHILDCN" => $childau[0]['cn'],
	"CHILDDN" => $childauDN,
	"CHILDDOMAIN" => $domprefix,
	"CHILDDESC" => $childau[0]['description'],
	"AUDN" => $auDN,
	"SBMNR" => $sbmnr));

# MaxIPBlocks
$mipb = $childau[0]['maxipblock'];
$mipbs = "";
if (count($mipb) > 1){
	for ($i=0; $i < count($mipb) - 1; $i++){
		$exp = explode('_',$mipb[$i]);
		$mipbs .= "$exp[0]&nbsp; - &nbsp;$exp[1]<br>";
	}
	$exp = explode('_',$mipb[$i]);
	$mipbs .= "$exp[0]&nbsp; - &nbsp;$exp[1]";
	$template->assign(array("MIPBS" => $mipbs));
}
elseif(count($mipb) == 1){
	$exp = explode('_',$mipb);
	$mipbs .= "$exp[0]&nbsp; - &nbsp;$exp[1]";
	$template->assign(array("MIPBS" => $mipbs));
}
else{
	$template->assign(array("MIPBS" => $mipbs));
}


###############################################################################
# Footer

include("au_footer.inc.php");

?>