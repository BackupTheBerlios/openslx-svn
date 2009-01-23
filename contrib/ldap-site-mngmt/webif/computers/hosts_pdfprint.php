<?php

# Dateiname und evtl. Pfad des Templates für die Webseite

$webseite = "hosts_pdfprint.dwt";

include('computers_header.inc.php');

$mnr = 0;
$sbmnr = -1;
$mcnr = -1;

###################################################################################

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################

session_unregister( 'entries' );


$template->assign(array
					("HOSTNAME" => "",
					"DOMAINNAME" => "",
					"HWADDRESS" => "",
					"IPADDRESS" => "",
					"DSC" => "")
				);
$template->define_dynamic("Clientauswahl", "Webseite");


foreach ($_POST["choice"] as $key=>$val) {
    if( $val == "on" ) {
// 		echo "$key -- $val";
//         echo $_SESSION['hosts_array'][$key]['hostname']."<br>";
        $tmp = explode('_', $_SESSION['hosts_array'][$key]['ipaddress']);
        //if ($tmp[0] != $tmp[1])
            //do something...
        $_SESSION['entries'][] = array($_SESSION['hosts_array'][$key]['hostname'], $_SESSION['hosts_array'][$key]['domainname'],
        $tmp[0], $_SESSION['hosts_array'][$key]['hwaddress'], $_SESSION['hosts_array'][$key]['description']);

		$template->assign(array
					("HOSTNAME" => $_SESSION['hosts_array'][$key]['hostname'],
					"DOMAINNAME" => $_SESSION['hosts_array'][$key]['domainname'],
					"HWADDRESS" => $_SESSION['hosts_array'][$key]['hwaddress'],
					"IPADDRESS" => $tmp[0],
					"DSC" => $_SESSION['hosts_array'][$key]['description'])
				);
		$template->parse("CLIENTAUSWAHL_LIST", ".Clientauswahl");

    }
}

// echo "<pre>";
// // var_dump($_SESSION['hosts_array']);
// // var_dump($_POST["choice"]);
// // var_dump($_POST["ip"]);
// // var_dump($_POST["host"]);
// //var_dump($_POST["action"]);
// var_dump($_SESSION['entries']);
// echo "</pre>";



?>