<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "no_dhcp.dwt";

include('dhcp_header.inc.php');

$mnr = 0; 
$sbmnr = -1;

###################################################################################

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

include("dhcp_footer.inc.php");

?>