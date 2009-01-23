<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite

# Welche Action? PDF Print, Client Move, ...
if ( count ($_POST['choice']) > 0 ) {

	if ($_POST["action"] == "pdfprint") {
		include('hosts_pdfprint.php');
	}
	// elseif ($_POST["action"] == "host_move") {
	// 	include('hosts_move.php');
	// }
 
// 	elseif ($_POST["action"] == "generatepdf") {
// 		include('generatePDF.php');
// 	}
	else {
		//zurück zu hostoverview.php
		include("hosts_noaction.php");
	}
}
else{
	include("hosts_noaction.php");
}



###################################################################################

include("computers_footer.inc.php");

?>