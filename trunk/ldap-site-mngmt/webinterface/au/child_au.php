<?php

include('../standard_header.inc.php');

# Filename of Template
$webseite = "child_au.dwt";

include('au_header.inc.php');

###############################################################################
# Menus

$mnr = 2;
$sbmnr = -1;

#$sbmnr = $_GET['sbmnr'];

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
					         "RANGE1" => "",
            		      "RANGE2" => "",
								"AUDN" => $auDN,
								"SBMNR" => $sbmnr));

# MaxIPBlocks
$mipb = $childau[0]['maxipblock'];

# IP Delegs
$template->define_dynamic("Delegs", "Webseite");
#print_r($mipb);
if (count($mipb) > 1){
	foreach ($mipb as $block){
		$exp = explode('_',$block);
		$template->assign(array("RANGE1" => $exp[0],
         		               "RANGE2" => $exp[1]));
  		$template->parse("DELEGS_LIST", ".Delegs");
	}
	$template->clear_dynamic("Delegs");
}elseif(count($mipb) == 1){
	$exp = explode('_',$mipb);
	$template->assign(array("RANGE1" => $exp[0],
      		               "RANGE2" => $exp[1]));
  	$template->parse("DELEGS_LIST", ".Delegs");
  	$template->clear_dynamic("Delegs");
}
$template->assign(array("RANGE1" => "",
         		         "RANGE2" => ""));
$template->parse("DELEGS_LIST", ".Delegs");
#$template->clear_dynamic("Delegs");


###############################################################################
# Footer

include("au_footer.inc.php");

?>