<?php

$template->assign(array("PFAD" => $START_PATH));

# Daten in die Vorlage parsen
$template->parse("LOGIN", "Login");
$template->parse("MAINMENU", "Mmenu");
$template->parse("NAVIGATION", "Menu");
$template->parse("IPBLOCKS", "IPBlocks");
$template->parse("HAUPTFENSTER", "Webseite");
$template->parse("PAGE", "Vorlage");

# Fertige Seite an den Browser senden
$template->FastPrint("PAGE");

# Abmelden vom LDAP
ldap_unbind($ds);

?>