<?php

include('../standard_header.inc.php');

# Filename of Template
$webseite = "child_au.dwt";

include('au_header.inc.php');

###############################################################################
# Menus

$mnr = 2;
$sbmnr = -1;

#$sbmnr = $_GET['sbmnr'];

createMainMenu($rollen, $mainnr);
createAUMenu($rollen, $mnr, $auDN, $sbmnr);

###############################################################################
# MainPage Data

$childauDN = "ou=".$_GET['cau'].",".$auDN;
#$childauDN = $_GET['dn'];

$childau = get_au_data($childauDN,array("dn","cn","ou","associateddomain","description","maxipblock"));
#print_r($childau);

$domprefix = str_replace('.uni-freiburg.de','',$childau[0]['associateddomain']);
#print_r($domprefix);

$childzone = $childau[0]['associateddomain'];
if ( in_array("ZoneAdmin", $all_roles[$rootAU]['roles']) ) {
	$zoneinc = "<input type='Text' name='childdomain' value='$childzone' size='35' class='medium_form_field'>
					<input type='hidden' name='oldchilddomain' value='$childzone'>";
}else{
	if ($childzone) {
		$zoneinc = $childzone;
	}else{
		$zoneinc = "Kein DNS Zone zugeordnet <br>(Sie sind dazu nicht berechtigt. Wenden Sie sich an den DNS Administrator ..)";
	}
}

$template->assign(array("CHILDOU" => $childau[0]['ou'],
								"CHILDCN" => $childau[0]['cn'],
								"CHILDDN" => $childauDN,
								"CHILDDOMAIN" => $domprefix,
								"CHILDZONE" => $childzone,
								"ZONEINC" => $zoneinc,
								"CHILDDESC" => $childau[0]['description'],
					         "RANGE1" => "",
            		      "RANGE2" => "",
								"AUDN" => $auDN,
								"SBMNR" => $sbmnr));

if ($childzone) {
	# MaxIPBlocks
	$mipb = $childau[0]['maxipblock'];
	#print_r($au_mipb);
	# IP Delegs
	$delegs = "<table cellpadding='7' cellspacing='0' border='1' align='left' width='90%' style='border-width: 0 0 0 0;'>";
	
	if ($au_mipb) {
		$delegs .= "<form action='ip_deleg_change.php' method='post'>
						<tr>
				<td class='tab_h' colspan='4'><b>Delegierte IP Bereiche</b></td>
			</tr>
			<tr>
				<td class='tab_d'>";
	}else{
		# Root AU -> IP Bereiche registrieren
		if ($auDN == $rootAU) { 
		$delegs .= "<form action='ipblock_register.php' method='post'>
						<tr>
				<td class='tab_h' colspan='4'><b>Eingetragene IP Bereiche (Netze)</b></td>
			</tr>
			";
		}
	}
	
	if (count($mipb) > 1){
		foreach ($mipb as $block){
			$exp = explode('_',$block);
			#if ($exp[0] == $exp[1]){
			#	$exp[1] = "";
			#}
			if ($au_mipb) {
				$delegs .= "<input type='Text' name='range1[]' value='$exp[0]' size='15' class='medium_form_field'>
							 &nbsp;&nbsp;- &nbsp;&nbsp;
						<input type='Text' name='range2[]' value='$exp[1]' size='15' class='medium_form_field'><br>							
						<input type='hidden' name='oldrange1[]' value='$exp[0]'>
						<input type='hidden' name='oldrange2[]' value='$exp[1]'>";
			}else{
				if ($auDN == $rootAU) { 
				$delegs .= "<tr>
						<td class='tab_d_ohne' align='right' width='15%'> $exp[0] </td>
						<td class='tab_d_ohne' align='center' width='5%'> &nbsp;&nbsp;- &nbsp;&nbsp; </td>
						<td class='tab_d_ohne' align='right' width='15%'> $exp[1] </td>
						<td class='tab_d_ohne' align='right' width='65%'>&nbsp;</td>
					</tr>";
				}
			}
		}
	}
	elseif(count($mipb) == 1){
		$exp = explode('_',$mipb);
		#if ($exp[0] == $exp[1]){
		#	$exp[1] = "";
		#}
		if ($au_mipb) {
			$delegs .= "<input type='Text' name='range1[]' value='$exp[0]' size='15' class='medium_form_field'>
							 &nbsp;&nbsp;- &nbsp;&nbsp;
						<input type='Text' name='range2[]' value='$exp[1]' size='15' class='medium_form_field'><br>							
						<input type='hidden' name='oldrange1[]' value='$exp[0]'>
						<input type='hidden' name='oldrange2[]' value='$exp[1]'>";
		}else{
			if ($auDN == $rootAU) { 
			$delegs .= "<tr>
						<td class='tab_d' align='right' width='15%'> $exp[0] </td>
						<td class='tab_d' align='center' width='5%'> &nbsp;&nbsp;- &nbsp;&nbsp; </td>
						<td class='tab_d' align='right' width='15%'> $exp[1] </td>
						<td class='tab_d' align='right' width='65%'>&nbsp;</td>
					</tr>";
			}
		}
	}
	
	if ($au_mipb) {
		$delegs .= "<input type='Text' name='range1[]' value='' size='15' class='medium_form_field'>
							 &nbsp;&nbsp;- &nbsp;&nbsp;
						<input type='Text' name='range2[]' value='' size='15' class='medium_form_field'><br>							
						<input type='hidden' name='oldrange1[]' value=''>
						<input type='hidden' name='oldrange2[]' value=''>
						<input type='hidden' name='childdn' value='$childauDN'>
						<input type='hidden' name='childzone' value='$childzone'>
						<input type='hidden' name='submenu' value='$sbmnr'>
					</td>
				</tr></table>";
		$submit = "<tr>
						<td><input type='Submit' name='apply' value='anwenden' class='small_loginform_button'>
						</form></td>
					  </tr>";
	}else{
		if ($auDN == $rootAU) { 
		$delegs .= "<tr valign='top'>
						<td class='tab_d_1010' colspan='3'><b>Neues Netz eintragen:</b></td>
						<td class='tab_d_1010'>
							<input type='Text' name='ip[]' value='' size='3' maxlength='3' class='medium_form_field'> <b>.</b> 
							<input type='Text' name='ip[]' value='' size='3' maxlength='3' class='medium_form_field'> <b>.</b> 
							<input type='Text' name='ip[]' value='' size='3' maxlength='3' class='medium_form_field'> <b>.</b> 
							
							<b>0</b><br><br>
							<input type='checkbox' name='only_subnet' value= 'onlysubnet'>							
							&nbsp;&nbsp;<b>Nur DHCP Subnetz eintragen</b> <br>
							&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ohne kompletten Class-C-Netz IP Bereich [1-255] einzutragen.
						
							<input type='hidden' name='childdn' value='$childauDN'>
							<input type='hidden' name='childzone' value='$childzone'>
							<input type='hidden' name='submenu' value='$sbmnr'>
						</td>
					</tr>
					</table>";
		$submit = "<tr>
						<td><input type='Submit' name='apply' value='eintragen' class='small_loginform_button'>
						</form></td>
					  </tr>";
		}else{
			$delegs .= "</table>";
		}
	}
}
else {
	$delegs = "&nbsp;";
	$submit = "";
}
$template->assign(array("DELEGS" => $delegs,
								"SUBMITDELEG" => $submit));

###############################################################################
# Footer

include("au_footer.inc.php");

?>