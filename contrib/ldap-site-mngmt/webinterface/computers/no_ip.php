<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "no_ip.dwt";

include("computers_header.inc.php");

###############################################################################

$mnr = 2;
$sbmnr = -1;
$mcnr = -1; 

$mnr = $_GET['mnr'];

# Menuleiste erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###############################################################################

###############################################################################

include("computers_footer.inc.php");

?>
