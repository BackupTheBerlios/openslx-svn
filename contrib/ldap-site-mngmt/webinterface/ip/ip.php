<?php

include('../standard_header.inc.php');
 
# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "ip_start.dwt";

include("ip_header.inc.php");

###################################################################################

$mnr = 0;

# Menuleiste erstellen
createMainMenu($rollen, $mainnr);
createIPMenu($rollen, $mnr);

###################################################################################

include("ip_footer.inc.php");

?>