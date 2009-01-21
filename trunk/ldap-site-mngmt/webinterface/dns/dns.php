<?php
include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "DNS Zone Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mnr = 0; 
$mainnr = 6;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dns_start.dwt";

include("../class.FastTemplate.php");

include('dns_header.inc.php');

###################################################################################

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDNSMenu($rollen, $mnr);

###################################################################################

include("dns_footer.inc.php");

?>