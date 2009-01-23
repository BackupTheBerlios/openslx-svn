<?php
# Nach dem Logout wird die Session beim Aufruf der index.php zerstört.
if(isset($_POST['Logout']) || $_SESSION['status'] != "in") {
    session_start();
    session_unregister('uid');
    session_unregister('userPassword');
    session_unregister('cn');
    session_unregister('dn');
    session_unregister('rollen');
    session_unregister('all_roles');
    session_unregister('au_dn');
    session_unregister('status');
    session_destroy();
}

###########################################################

#Pfad festlegen wo die Dateien sich befinden
#include('standard_header.inc.php');
include("class.FastTemplate.php");

$titel = "Zentrales Client / IP Management";
$webseite = "start.dwt";

# neues Template-Objekt erstellen
$template = new FastTemplate(".");
# dem erstellten Template-Objekt eine Vorlage zuweisen
$template->define(array("Vorlage" => "index.dwt",
                        "Login" => "login_form.inc.html",
                        "Webseite" => $webseite));
$template->assign(array("SEITENTITEL" => $titel));

############################################################ 

# Daten in die Vorlage parsen
$template->assign(array("PFAD" => $START_PATH));

# $template->parse("MAINMENU", "Mmenu");
# $template->parse("NAVIGATION", "Menu");
$template->parse("LOGIN", "Login");
$template->parse("HAUPTFENSTER", "Webseite");
$template->parse("PAGE", "Vorlage");

# Fertige Seite an den Browser senden
$template->FastPrint("PAGE");

?>
