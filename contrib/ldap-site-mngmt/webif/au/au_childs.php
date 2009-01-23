<?php

include('../standard_header.inc.php');

# Filename of Template
$webseite = "au_childs.dwt";

include('au_header.inc.php');

###############################################################################
# Menus

$mnr = 2;
$sbmnr = -1;

createMainMenu($rollen, $mainnr);
createAUMenu($rollen, $mnr, $auDN, $sbmnr);

###############################################################################
# Mainpage Data

$template->assign(array("CHILDOU" => "Noch keine untergordnete AU angelegt",
	"CHILDCN" => "",
	"CHILDDN" => "",
	"CHILDDOMAIN" => "",
	"CHILDIPS" => "",
	"CHILDDESC" => ""));

$childau_array = get_childau($auDN,array("dn","cn","ou","associateddomain","description","maxipblock"));

$template->define_dynamic("Childaus", "Webseite");

foreach ($childau_array as $childau){
	#$auname = "<a href='child_au.php?dn=".$childau['dn']."' class='headerlink'>".$childau['ou']."</a>";
	$auname = "<a href='child_au.php?cau=".$childau['ou']."' class='headerlink'>".$childau['ou']."</a>";	
	
	$delegips = "";
	if ( is_array($childau['maxipblock']) ){
		natsort($childau['maxipblock']);
		$delegips = "<table cellpadding='0' cellspacing='0' border='0' align='left' width='100%'>";
		foreach ($childau['maxipblock'] as $mipb){
			$exp = explode('_',$mipb);
			$delegips .= "<tr valign='top'>
						<td width='35%'>$exp[0]</td><td> - </td><td width='35%'>$exp[1]</td>
						<td width='20%'>&nbsp;</td>
						</tr>";
		}
		$delegips .= "</table>";
	}
	elseif ($childau['maxipblock']) {
		$exp = explode('_',$childau['maxipblock']);
		$delegips .= "<table cellpadding='0' cellspacing='0' border='0' align='left' width='100%'><tr valign='top'>";
		if ($exp[0] != $exp[1]) {
			$delegips .= "<td width='35%'>$exp[0]</td><td> - </td><td width='35%'>$exp[1]</td>
					<td width='20%'>&nbsp;</td>";
		}else{
			$delegips .= "<td width='35%'>$exp[0]</td><td colspan='2'>&nbsp;</td>";
		}
		$delegips .= "</tr></table>";
	}
	else {
		$delegips = "&nbsp;";
	}
	$template->assign(array("CHILDOU" => $auname,
		"CHILDCN" => $childau['cn'],
		"CHILDDN" => $childau['dn'],
		"CHILDDOMAIN" => $childau['associateddomain'],
		"CHILDIPS" => $delegips,
		"CHILDDESC" => $childau['description'],
		"AUDN" => $auDN));
	$template->parse("CHILDAUS_LIST", ".Childaus");
}


###################################################################################
# Footer

include("au_footer.inc.php");

?>