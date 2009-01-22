<?php
include('../standard_header.inc.php');

$mnr = 0; 
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "roles_start.dwt";

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