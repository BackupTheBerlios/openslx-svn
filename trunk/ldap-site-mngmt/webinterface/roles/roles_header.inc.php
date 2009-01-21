<?php
include("roles_menu.php");

$template = new FastTemplate(".");
# dem erstellten Template-Objekt eine Vorlage zuweisen
$definedTemplates = array("Vorlage" => "roles.dwt",
								  "Login" => "../logout_form.inc.dwt",
								  "Mmenu" => "../hauptmenue.dwt",
                          "Menu" => "menu.dwt",
                          "Webseite" => $webseite);
if (isset($additionalTemplates)) {
    foreach ($additionalTemplates as $templateKey => $templateFile) {
        $definedTemplates[$templateKey] = $templateFile;
    }
}
$template->define($definedTemplates);
$template->assign(array("SEITENTITEL" => $titel, "AU" => $au_ou, "DOMAIN" => $assocdom, "USERCN" => $usercn));

?>