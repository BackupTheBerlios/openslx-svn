<?php
include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Roles Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 1;
$mnr = 0; 
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "roles_start.dwt";

include("../class.FastTemplate.php");

#include("roles_header.inc.php");
include("au_header.inc.php");

###################################################################################

$mnr = 3;
$sbmnr = -1;

# Menuleiste erstellen
createMainMenu($rollen, $mainnr);
createAUMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

include("au_footer.inc.php");

?>