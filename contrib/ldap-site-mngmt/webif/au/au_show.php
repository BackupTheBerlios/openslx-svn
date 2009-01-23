<?php

include('../standard_header.inc.php');
# Filename of Template
$webseite = "au_show.dwt";

include('au_header.inc.php');

###############################################################################
# Menus

$mnr = 1; 
$sbmnr = -1; 

createMainMenu($rollen, $mainnr);
createAUMenu($rollen, $mnr, $auDN, $sbmnr);

###############################################################################
# MainpageData

# Parent AU, Email MainAdmin
$parentMA = 0;
$exp = explode(',',$auDN);
$parentau = array_slice($exp, 1, 1);
$parentau = substr($parentau[0],3);

if ( $parentau != "RIPM"){
   $length = count($exp);
   $out = array_slice($exp, 1, $length -1);
   $parentauDN = implode(',',$out);
   
   if ( $parentauDN == $rootAU ) {
	   $rol = get_roles($parentauDN);
   	#print_r($rol); echo "<br>";
		if ( in_array($userDN,$rol['MainAdmin']) ){
			#echo "PARENT AU MAINADMIN<br><br>";
			$parentMA = 1;
		}
   #$mainadminDN = $rol['MainAdmin'][0];
   #$emailMA = get_user_data($mainadminDN, array("mail"));
   #$emailCODE = "<a href'mailto:".$emailMA['mail']."' class='maillink' 	style='text-decoration:none'>".$emailMA['mail']."</a>";
   }
}

$template->assign(array("OU" => $au_ou,
	"CN" => $au_cn,
	"DSC" => $au_desc,
	"AUDN" => $auDN,
	"PARENTAU" => $parentau,
	"EMAILMA" => $emailCODE));

# MaxIPBlocks
$mipb = $au_mipb;
#print_r($mipb);echo "<br>";

$mipbs .= "";
if ( is_array($mipb) ) {
	$mipbs = "<table cellpadding='0' cellspacing='0' border='0' align='left' width='100%'>";
	foreach ($mipb as $ir) {
		$exp = explode('_',$ir);
		$mipbs .= "<tr>
						<td width='35%'>$exp[0]</td><td> - </td><td width='35%'>$exp[1]</td>
						<td width='20%'>&nbsp;</td>
						</tr>";
	}
	$mipbs .= "</table>";
} 
elseif ($mipb) {
	$exp = explode('_',$mipb);
	$mipbs .= "<table cellpadding='0' cellspacing='0' border='0' align='left' width='100%'><tr>
					<td width='35%'>$exp[0]</td><td> - </td><td width='35%'>$exp[1]</td>
					<td width='20%'>&nbsp;</td>
					</tr></table>";
}
else {
	$mipbs .= "&nbsp;";
}
$template->assign(array("MIPBS" => $mipbs));
#print_r($mipbs);

###############################################################################
# Footer

include("au_footer.inc.php");

?>