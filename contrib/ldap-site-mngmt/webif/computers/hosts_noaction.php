<?php

# Dateiname und evtl. Pfad des Templates für die Webseite

$webseite = "hosts_noaction.dwt";

include('computers_header.inc.php');

$mnr = 0;
$sbmnr = -1;
$mcnr = -1;

###################################################################################

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################
$url = "hostoverview.php";
$mesg .= "<a href=".$url." style='publink'><< Zur&uuml;ck zur Client &Uuml;bersicht</a>";

$template->assign(array("TEXT" => $mesg))

// redirect(4, $url, " ", $addSessionId = TRUE);

?>