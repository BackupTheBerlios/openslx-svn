<?php

include('../standard_header.inc.php');

# Filename of Template
$webseite = "au_start.dwt";

include('au_header.inc.php');

###############################################################################
# Menus

$mnr = 0;
$sbmnr = -1;

$childauDN = $_GET['dn'];

createMainMenu($rollen, $mainnr);
createAUMenu($rollen, $mnr, $auDN, $sbmnr);

###############################################################################
# Footer

include("au_footer.inc.php");

?>