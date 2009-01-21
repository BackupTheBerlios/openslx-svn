<?php
include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "DHCP Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 5;
$mnr = 0; 
$sbmnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "no_dhcp.dwt";

include("../class.FastTemplate.php");

include('dhcp_header.inc.php');

###################################################################################

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

include("dhcp_footer.inc.php");

?>