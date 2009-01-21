<?php

include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "IP Address Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 2;
$mnr = 2; 
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "ip_deleg.dwt";

include("../class.FastTemplate.php");

include("ip_header.inc.php");

#############################################################################

# Menuleiste erstellen
createMainMenu($rollen, $mainnr);
createIPMenu($rollen, $mnr);

include("ip_blocks.inc.php");


#############################################################################

$template->assign(array("CHILDOU" => "Noch keine untergeordnete AU angelegt",
					         "RANGE1" => "",
            		      "RANGE2" => "",
            		      "CHILDDN" => ""));
		
$childau_array = get_childau($auDN,array("dn","ou","maxipblock"));
# print_r ($childau_array);

$template->define_dynamic("Delegs", "Webseite");
$template->define_dynamic("AUs", "Webseite");

foreach ($childau_array as $childau){
	
	$template->clear_parse("DELEGS_LIST");
	if ( count($childau['maxipblock']) > 1 ){
		foreach ($childau['maxipblock'] as $j){
			$exp = explode('_',$j);
			$template->assign(array("CHILDOU" => $childau['ou'],
					                  "RANGE1" => $exp[0],
            		               "RANGE2" => $exp[1],
            		               "CHILDDN" => $childau['dn'],
            		            	"AUDN" => $auDN));
     		$template->parse("DELEGS_LIST", ".Delegs");
     		$template->clear_dynamic("Delegs");
   	}
  		$template->assign(array("CHILDOU" => $childau['ou'],
					               "RANGE1" => "",
            		            "RANGE2" => "",
            		            "CHILDDN" => $childau['dn'],
            		          	"AUDN" => $auDN));
		$template->parse("DELEGS_LIST", ".Delegs");
		$template->clear_dynamic("Delegs");
		$template->assign(array("OU" => $childau['ou']));
		$template->parse("AUS_LIST", ".AUs");
   	
   }elseif ( count($childau['maxipblock']) == 1 ){
   	
   	$exp = explode('_',$childau['maxipblock']);
		$template->assign(array("CHILDOU" => $childau['ou'],
					                  "RANGE1" => $exp[0],
            		               "RANGE2" => $exp[1],
            		               "CHILDDN" => $childau['dn'],
            		            	"AUDN" => $auDN));
		$template->parse("DELEGS_LIST", ".Delegs");
		$template->clear_dynamic("Delegs");
		$template->assign(array("CHILDOU" => $childau['ou'],
					               "RANGE1" => "",
            		            "RANGE2" => "",
            		            "CHILDDN" => $childau['dn'],
            		          	"AUDN" => $auDN));
		$template->parse("DELEGS_LIST", ".Delegs");
		$template->clear_dynamic("Delegs");
		$template->assign(array("OU" => $childau['ou']));
		$template->parse("AUS_LIST", ".AUs");
  		
	}else{
			$template->assign(array("CHILDOU" => $childau['ou'],
					                  "RANGE1" => "",
            		               "RANGE2" => "",
            		               "CHILDDN" => $childau['dn'],
            		            	"AUDN" => $auDN));
			$template->parse("DELEGS_LIST", ".Delegs");
			$template->clear_dynamic("Delegs");
			$template->assign(array("OU" => $childau['ou']));
			$template->parse("AUS_LIST", ".AUs");
	}
	
}


#####################################################################################

include("ip_footer.inc.php");

?>
