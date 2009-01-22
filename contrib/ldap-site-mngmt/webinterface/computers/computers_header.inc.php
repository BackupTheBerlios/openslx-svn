<?php

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Computers Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 1;


$template = new FastTemplate(".");
# dem erstellten Template-Objekt eine Vorlage zuweisen
$definedTemplates = array("Vorlage" => "computers.dwt",
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
$template->assign(array("SEITENTITEL" => $titel, "AU" => $au_ou, "DOMAIN" => $assocdom, "USERCN" => $usercn));


include("computers_menu.php");
include("../common/ip_blocks.inc.php");

?>