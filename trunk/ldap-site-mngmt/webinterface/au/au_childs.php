<?php

include('../standard_header.inc.php');
include("../class.FastTemplate.php");

# Filename of Template
$webseite = "au_childs.dwt";

include('au_header.inc.php');


###############################################################################
# Menus

$mnr = 2;
$sbmnr = -1;

createMainMenu($rollen, $mainnr);
createAUMenu($rollen, $mnr, $auDN, $sbmnr);


###############################################################################
# Mainpage Data

$template->assign(array("CHILDOU" => "Noch keine untergordnete AU angelegt",
	"CHILDCN" => "",
	"CHILDDN" => "",
	"CHILDDOMAIN" => "",
	"CHILDDESC" => ""));

$childau_array = get_childau($auDN,array("dn","cn","ou","associateddomain","description","maxipblock"));

$template->define_dynamic("Childaus", "Webseite");

foreach ($childau_array as $childau){
	$template->assign(array("CHILDOU" => $childau['ou'],
		"CHILDCN" => $childau['cn'],
		"CHILDDN" => $childau['dn'],
		"CHILDDOMAIN" => $childau['associateddomain'],
		"CHILDDESC" => $childau['description'],
		"AUDN" => $auDN));
	$template->parse("CHILDAUS_LIST", ".Childaus");
}


###################################################################################
# Footer

include("au_footer.inc.php");

?>