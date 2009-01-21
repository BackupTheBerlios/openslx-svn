<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "no_ip.dwt";

include("ip_header.inc.php");

###############################################################################

$mnr = 1; 

$mnr = $_GET['mnr'];

# Menuleiste erstellen
createMainMenu($rollen, $mainnr);
createIPMenu($rollen, $mnr);

###############################################################################

###############################################################################

include("ip_footer.inc.php");

?>
