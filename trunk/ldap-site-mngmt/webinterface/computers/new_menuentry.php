<?php

include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Computers Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 3;
$mnr = -1; 
$sbmnr = -1;
$mcnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "new_menuentry.dwt";

include("../class.FastTemplate.php");

include('computers_header.inc.php');

###################################################################################

$mnr = $_GET['mnr']; 
$sbmnr = $_GET['sbmnr'];
$mcnr = $_GET['mcnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################

$mecn = str_replace ( "_", " ", $_GET['mecn']);

$pxeDN = $_GET['dn'];
$dnexp = ldap_explode_dn($pxeDN, 1);
$pxecn = $dnexp[0];

# RBS Daten
$pxe = get_node_data($pxeDN,array("rbservicedn"));
$rbsDN = $pxe['rbservicedn'];
$exp = explode(',',$rbsDN);
$exprbsau = explode('=',$exp[2]); $rbsau = $exprbsau[1];
$rbsdata = get_node_data($rbsDN,array("cn","nfsserverip","exportpath","tftpserverip","tftppath"));

# Anzahl Menüeinträge
$menens = get_menuentries($pxeDN,array("dn"));
$maxpos = count($menens)+1;


# Bootmenu Daten
$template->assign(array("MECN" => $mecn,
           			      "LABEL" => "",
           			      "MELABEL" => "",
           			      "MEDEF" => "",
           			      "MEPASSWD" => "",
           			      "MEHIDE" => "",
           			      "VGA" => "",           			      
           		       	"SPLASH" => "",          			      
           		       	"NOLDSC" => "",
           		       	"ELEVATOR" => "", 
           			      "VCI" => "",          			      
           		       	"CCV" => "",          			      
           		       	"APIC" => "",
           		       	"COWLOOP" => "",                   			      
           		       	"UNIONFS" => "",
           		       	"DEBUG" => "",          			      
           		       	"LOCALBOOT" => "",
           		       	"SUBMENULINK" => "",
           		       	"MENPOS" => "",
           		       	"MAXPOS" => $maxpos,
           		       	"PXEDN" => $pxeDN,
           		       	"PXECN" => $pxecn,
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr,
           		       	"MCNR" => $mcnr));
           		       	

# verwendbare GBMs holen
# eigene AU (andere noch über "offer" Attribut in RBS suchen)
$rbsoffers = get_rbsoffers($auDN);
# eigene AU
if (count($rbsoffers) != 0){
	$rbservices = get_rbservices($auDN,array("dn"));
	# wenn eigene RBS anbietet dann diese GBMs als erstes (oben in der Liste) 
 	if (count($rbservices) != 0){
		foreach ($rbservices as $rbs){
			for ($i=0; $i < count($rbsoffers); $i++){
				if ($rbs['dn'] == $rbsoffers[$i]){
					array_splice($rbsoffers, $i, 1);
				}
			}
		}
		# momentan maximal ein RBS in der AU 
		$rbsaudn[] = $rbservices[0]['dn'];
		$rbsoffsorted = array_merge($rbsaudn,$rbsoffers);
	}
	# sonst die GBMs des für diese PXE genutzen RBS
	else{
		for ($i=0; $i < count($rbsoffers); $i++){
			if ($rbsDN == $rbsoffers[$i]){
				array_splice($rbsoffers, $i, 1);
			}
		}
		$rbsaudn[] = $rbsDN;
		$rbsoffsorted = array_merge($rbsaudn,$rbsoffers);
	}
}
#print_r($rbsoffsorted);echo "<br><br>";
# RBS Offers nun in der Reihenfolge erst eigene AU dann Rest ...
$attributes = array("dn","cn","label","kernel","initrd","nfsroot","nbdroot","ipappend");
$template->assign(array("GBMDN" => "",
   	                  "GBMCN" => "Keine generischen Boot Images verf&uuml;gbar",
   	                  "RBSCN" => "",
   	                  "RBSAU" => ""));             
if (count($rbsoffsorted) != 0){
	$template->define_dynamic("Rbs", "Webseite");
	$template->define_dynamic("Gbms", "Webseite");
	
	foreach ($rbsoffsorted as $rbsoff){
		$template->clear_parse("GBMS_LIST");
		#print_r($rbsoff);echo "<br><br>";
		$rbsdnexp = ldap_explode_dn($rbsoff,1);
		$rbsoffcn = $rbsdnexp[0];
		$rbsoffau = $rbsdnexp[2];
		
		$gbm_array = get_menuentries($rbsoff,$attributes);
		if (count($gbm_array) != 0){
		
			foreach ($gbm_array as $item){
				$template->assign(array("GBMDN" => $item['dn'],
		   	                        "GBMCN" => $item['cn']));
		   	$template->parse("GBMS_LIST", ".Gbms");
		   	$template->clear_dynamic("Gbms");
			}
			
		}
		$template->assign(array("RBSCN" => $rbsoffcn,
		   	                  "RBSAU" => $rbsoffau));
		$template->parse("RBS_LIST", ".Rbs");
		$template->clear_dynamic("Rbs");
		
	}
}



###################################################################################

include("computers_footer.inc.php");

?>
