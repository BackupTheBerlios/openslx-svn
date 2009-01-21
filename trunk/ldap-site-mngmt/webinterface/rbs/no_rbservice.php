<?php
include('../standard_header.inc.php');

# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "no_rbservice.dwt";

include('rbs_header.inc.php');

###################################################################################

$mnr = 1; 
$sbmnr = -1;

$mnr = $_GET['mnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createRBSMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################


###################################################################################

include("rbs_footer.inc.php");

?>