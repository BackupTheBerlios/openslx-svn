<?php

#Pfad festlegen wo die Dateien sich befinden
include('standard_header.inc.php');

$titel = "Rechner und IP Management Startseite";
$webseite = "home.dwt";
# Einbinden der Template-Funktionen

include("class.FastTemplate.php");

# neues Template-Objekt erstellen
$template = new FastTemplate(".");
# dem erstellten Template-Objekt eine Vorlage zuweisen
$template->define(array("Vorlage" => "index.dwt",
                        "Login" => "logout_form.inc.dwt",
                        "Webseite" => $webseite));

$template->assign(array("SEITENTITEL" => $titel,"USERCN" => $usercn));

############################################################ 

$template->define_dynamic("Aus", "Webseite");
#$template->define_dynamic("Roles", "Webseite");

$roles = getRoles($ds, $userDN);
#print_r($roles); echo "<br><br>"; 
foreach ($roles as $item){
	
	$auDN = $item['au'];
	$expDN = explode(',',$auDN);
	$expOU = explode('=',$expDN[0]);
	$au = $expOU[1];
	
	$template->assign(array( "MA" => "", "HA" => "", "DA" => "", "ZA" => ""));
	$template->assign(array( "AU" => $au, "AUDN" => $auDN, "ROLLEN" => implode('_',$item['role'])));
	
	foreach ($item['role'] as $role){
		if ($role == MainAdmin){
			$template->assign(array( "MA" => $role));
		}
		if ($role == HostAdmin){
			$template->assign(array( "HA" => $role));
		}
		if ($role == DhcpAdmin){
			$template->assign(array( "DA" => $role));
		}
		if ($role == ZoneAdmin){
			$template->assign(array( "ZA" => $role));
		}
	}
	$template->parse("AUS_LIST", ".Aus");
	$template->clear_dynamic("Aus");
}


############################################################# 

# Daten in die Vorlage parsen
$template->assign(array("PFAD" => $START_PATH));

$template->parse("LOGIN", "Login");
$template->parse("HAUPTFENSTER", "Webseite");
$template->parse("PAGE", "Vorlage");

# Fertige Seite an den Browser senden
$template->FastPrint("PAGE");
?>
