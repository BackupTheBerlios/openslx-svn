<?php

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "DHCP Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 2;


$template = new FastTemplate(".");
# dem erstellten Template-Objekt eine Vorlage zuweisen
$definedTemplates = array("Vorlage" => "dhcp.dwt",
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
$template->assign(array("SEITENTITEL" => $titel, "ROLLE" => "mainadmin", "AU" => $au_ou, "DOMAIN" => $assocdom, "USERCN" => $usercn));


include("dhcp_menu.php");
include("../common/ip_blocks.inc.php");

?>