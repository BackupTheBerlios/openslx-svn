<?php

include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "IP Address Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 2;
$mnr = 1; 
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "no_ip.dwt";

include("../class.FastTemplate.php");

include("ip_header.inc.php");

###############################################################################

$mnr = $_GET['mnr'];

# Menuleiste erstellen
createMainMenu($rollen, $mainnr);
createIPMenu($rollen, $mnr);

include("ip_blocks.inc.php");

###############################################################################

###############################################################################

include("ip_footer.inc.php");

?>
