<?php

#################

# 1. Title
$titel = "Administrative Unit Management";
# 2. Mainmenu Number (starting with 0)
$mainnr = 0;


$template = new FastTemplate(".");
# dem erstellten Template-Objekt eine Vorlage zuweisen
$definedTemplates = array("Vorlage" => "au.dwt",
	"Login" => "../logout_form.inc.dwt",
	"Mmenu" => "../hauptmenue.dwt",
	"Menu" => "menu.dwt",
   "IPBlocks" => "../common/ipblocks.dwt",
	"Webseite" => $webseite);

if (isset($additionalTemplates)) {
	foreach ($additionalTemplates as $templateKey => $templateFile) {
		$definedTemplates[$templateKey] = $templateFile;
	}
}

$template->define($definedTemplates);
$template->assign(array("SEITENTITEL" => $titel,
	"ROLLE" => "mainadmin",
	"AU" => $au_ou,
	"DOMAIN" => $assocdom,
	"USERCN" => $usercn));


include("au_menu.php");
include("../common/ip_blocks.inc.php");


?>