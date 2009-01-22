<?php
include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dns_inwork.dwt";

include('dns_header.inc.php');

###################################################################################

$mnr = 0; 

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDNSMenu($rollen, $mnr);

###################################################################################

include("dns_footer.inc.php");

?>