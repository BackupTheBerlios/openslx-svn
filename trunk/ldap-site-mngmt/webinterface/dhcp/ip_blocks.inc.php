<?php

# Max und Free IP Blocks
$mipb_array = get_maxipblocks_au($auDN);
$fipb_array = get_freeipblocks_au($auDN);
#print_r(count($mipb_array)); echo "<br>";
#print_r(count($fipb_array)); echo "<br>";
$ipblocks = "";

# print_r($mipb_array);
if ($mipb_array[0] != "" ){
	if (count($mipb_array) > 1 ){
		$ipblocks .= "<table border='1' cellpadding='2' cellspacing='0' width='100%' style='border-width: 0 0 0 0;'>
							<tr><td colspan='3' style='border-color: black; border-style: solid; border-width: 0 0 3 0;'>
							<h4>Zugewiesene IP Bereiche:</h4></td></tr>";
		foreach ($mipb_array as $mipb){
			$exp = explode('_',$mipb);
			$ipblocks .= "<tr><td width='45%' style='border-color: black; border-style: solid; border-width: 0 0 1 0;'>$exp[0]&nbsp;</td>
									<td style='border-color: black; border-style: solid; border-width: 0 0 1 0;'> - </td>
									<td width='45%' style='border-color: black; border-style: solid; border-width: 0 0 1 0;'>$exp[1]&nbsp;</td></td></tr>";
		}
	}
	elseif (count($mipb_array) == 1){
		$ipblocks .= "<table border='1' cellpadding='2' cellspacing='0' width='100%' style='border-width: 0 0 0 0;'>
							<tr><td colspan='3' style='border-color: black; border-style: solid; border-width: 0 0 3 0;'>
							<h4>Zugewiesener IP Bereich:</h4></td></tr>";	
		$exp = explode('_',$mipb_array[0]);
		$ipblocks .= "<tr><td width='45%' style='border-color: black; border-style: solid; border-width: 0 0 1 0;'>$exp[0]&nbsp;</td>
							<td style='border-color: black; border-style: solid; border-width: 0 0 1 0;'> - </td>
							<td width='45%' style='border-color: black; border-style: solid; border-width: 0 0 1 0;'>$exp[1]&nbsp;</td></tr>";
	}
	elseif( $fipb_array[0] == "" ){
	$ipblocks .= "<table border='0' cellpadding='2' cellspacing='0' width='100%' style='border-width: 0 0 0 0;'>
						<tr><td><h4>Keine IP Adressen mehr verf&uuml;gbar</h4></td></tr>";
	}
	if (count($fipb_array) > 1 ){
		$ipblocks .= "<table border='1' cellpadding='2' cellspacing='0' width='100%' style='border-width: 0 0 0 0;'>
							<tr valign='bottom' height='50'>
							<td colspan='3' style='border-color: black; border-style: solid; border-width: 0 0 3 0;'>
							<h4>Davon noch frei verf&uuml;gbar:</h4></td></tr>";	
		foreach ($fipb_array as $fipb){
			$exp = explode('_',$fipb);
			$ipblocks .= "<tr><td width='45%' style='border-color: black; border-style: solid; border-width: 0 0 1 0;'>$exp[0]&nbsp;</td>
								<td style='border-color: black; border-style: solid; border-width: 0 0 1 0;'> - </td>
								<td width='45%' style='border-color: black; border-style: solid; border-width: 0 0 1 0;'>$exp[1]&nbsp;</td></tr>";
		}
	}
	elseif (count($fipb_array) == 1){
		$ipblocks .=  "<table border='1' cellpadding='2' cellspacing='0' width='100%' style='border-width: 0 0 0 0;'>
							<tr><td colspan='3' style='border-color: black; border-style: solid; border-width: 0 0 3 0;'>
							<h4>Davon noch frei verf&uuml;gbar:</h4></td></tr>";	
		$exp = explode('_',$fipb_array[0]);
		$ipblocks .= "<tr><td width='45%' style='border-color: black; border-style: solid; border-width: 0 0 1 0;'>$exp[0]&nbsp;</td>
							<td style='border-color: black; border-style: solid; border-width: 0 0 1 0;'> - </td>
							<td width='45%' style='border-color: black; border-style: solid; border-width: 0 0 1 0;'>$exp[1]&nbsp;</td></tr>";
	}
	
}

if( $mipb_array[0] == "" ){
	$ipblocks .= "<table border='0' cellpadding='2' cellspacing='0' width='100%' style='border-width: 0 0 0 0;'>
						<tr><td><h4>Ihnen wurden keine IP Adressen zugewiesen</h4></td></tr>";
}
$ipblocks .= "</table>";

$template->assign(array("IPBLOCKS" => $ipblocks));

?>