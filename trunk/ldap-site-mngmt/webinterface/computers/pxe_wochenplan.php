<?php

#####################################
# Wochenübersicht  

$template->assign(array("A0" => "","B0" => "","C0" => "","D0" => "","E0" => "","F0" => "","G0" => "",
								"A1" => "","B1" => "","C1" => "","D1" => "","E1" => "","F1" => "","G1" => "",
								"A2" => "","B2" => "","C2" => "","D2" => "","E2" => "","F2" => "","G2" => "",
								"A3" => "","B3" => "","C3" => "","D3" => "","E3" => "","F3" => "","G3" => "",
								"A4" => "","B4" => "","C4" => "","D4" => "","E4" => "","F4" => "","G4" => "",
								"A5" => "","B5" => "","C5" => "","D5" => "","E5" => "","F5" => "","G5" => "",
								"A6" => "","B6" => "","C6" => "","D6" => "","E6" => "","F6" => "","G6" => "",
								"A7" => "","B7" => "","C7" => "","D7" => "","E7" => "","F7" => "","G7" => "",
								"A8" => "","B8" => "","C8" => "","D8" => "","E8" => "","F8" => "","G8" => "",
								"A9" => "","B9" => "","C9" => "","D9" => "","E9" => "","F9" => "","G9" => "",
								"A10" => "","B10" => "","C10" => "","D10" => "","E10" => "","F10" => "","G10" => "",
								"A11" => "","B11" => "","C11" => "","D11" => "","E11" => "","F11" => "","G11" => "",
								"A12" => "","B12" => "","C12" => "","D12" => "","E12" => "","F12" => "","G12" => "",
								"A13" => "","B13" => "","C13" => "","D13" => "","E13" => "","F13" => "","G13" => "",
								"A14" => "","B14" => "","C14" => "","D14" => "","E14" => "","F14" => "","G14" => "",
								"A15" => "","B15" => "","C15" => "","D15" => "","E15" => "","F15" => "","G15" => "",
								"A16" => "","B16" => "","C16" => "","D16" => "","E16" => "","F16" => "","G16" => "",
								"A17" => "","B17" => "","C17" => "","D17" => "","E17" => "","F17" => "","G17" => "",
								"A18" => "","B18" => "","C18" => "","D18" => "","E18" => "","F18" => "","G18" => "",
								"A19" => "","B19" => "","C19" => "","D19" => "","E19" => "","F19" => "","G19" => "",
								"A20" => "","B20" => "","C20" => "","D20" => "","E20" => "","F20" => "","G20" => "",
								"A21" => "","B21" => "","C21" => "","D21" => "","E21" => "","F21" => "","G21" => "",
								"A22" => "","B22" => "","C22" => "","D22" => "","E22" => "","F22" => "","G22" => "",
								"A23" => "","B23" => "","C23" => "","D23" => "","E23" => "","F23" => "","G23" => ""));

#print_r($timeranges); echo "<br>";

############################################################################
# Default-Dienst PXE Timeranges
# vom spezifischsten zum unspezifischsten :
# FR_0_7  ->  FR_X_X  ->  X_0_7  ->  X_X_X 
$daytime = array();
$timex = array();
$dayx = array();
$allx = array();
$legend = array();
if(count($wopldeftranges) != 0){
foreach ($wopldeftranges as $tr){
	if (count($tr[0]) > 1){
		foreach ($tr as $item){
			if ($item[0] != "X" && $item[1] != "X" && $item[2] != "X" && ($item[0] == "MO" || $item[0] == "DI" || $item[0] == "MI" || $item[0] == "DO" || $item[0] == "FR" || $item[0] == "SA" || $item[0] == "SO")){
				$daytime[] = $item;
			}
			if ($item[0] != "X" && $item[1] == "X" && $item[2] == "X"){
				$timex[] = $item;
			}
			if ($item[0] == "X" && $item[1] != "X" && $item[2] != "X"){
				$dayx[] = $item;
			}
			if ($item[0] == "X" && $item[1] == "X" && $item[2] == "X"){
				$allx[] = $item;
			}
		}
	}else{
		if ($tr[0] != "X" && $tr[1] != "X" && $tr[2] != "X" && ($tr[0] == "MO" || $tr[0] == "DI" || $tr[0] == "MI" || $tr[0] == "DO" || $tr[0] == "FR" || $tr[0] == "SA" || $tr[0] == "SO")){
			$daytime[] = $tr;
		}
		if ($tr[0] != "X" && $tr[1] == "X" && $tr[2] == "X"){
			$timex[] = $tr;
		}
		if ($tr[0] == "X" && $tr[1] != "X" && $tr[2] != "X"){
			$dayx[] = $tr;
		}
		if ($tr[0] == "X" && $tr[1] == "X" && $tr[2] == "X"){
			$allx[] = $tr;
		}
	}
}

#print_r($daytime); echo "<br>";
#print_r($timex); echo "<br>"; 
#print_r($dayx); echo "<br>"; 
#print_r($allx); echo "<br>";	

$daycode = array("MO" => "A", "DI" => "B", "MI" => "C", "DO" => "D", "FR" => "E", "SA" => "F", "SO" => "G");
$daytimexcolors = array("#BEBEBE","A0A0A0","#696969","#EEDFCC","#D8BFD8","#505050");
$allxcolors = array("#483D8B","#7B68EE","#191970","#8470FF","#708090","#6A5ACD");
$dayxcolors = array("#CDC673","#A2CD5A","#BDB76B","#8B864E","#6B8E23","#CDBE70");
$timecolors = array("880000","#CD6839","#CC3300","#CC6600","#993300","#8B4C39");


if (count($allx) != 0){
	$c = 0;
	foreach ($allx as $range){
		foreach ($daycode as $dc){
			for ($i = 0; $i <= 23; $i++){
				$template->assign(array($dc.$i => "background-color:".$allxcolors[$c].";")); 
			}
		}
		$legend[] = array($range ,$allxcolors[$c]);
		$c++;	
	}
}

if (count($dayx) != 0){
	$c = 0;
	foreach ($dayx as $range){
		foreach ($daycode as $dc){
			for ($i = $range[1]; $i<= $range[2]; $i++){
				$template->assign(array($dc.$i => "background-color:".$dayxcolors[$c].";")); 
			}
		}
		$legend[] = array($range ,$dayxcolors[$c]);
		$c++;	
	}
}

if (count($timex) != 0){
	$c = 0;
	foreach ($timex as $range){
		$dc = $daycode[$range[0]];
		for ($i = 0; $i<= 23; $i++){
			$template->assign(array($dc.$i => "background-color:".$timexcolors[$c].";")); 
		}
		$legend[] = array($range ,$timexcolors[$c]);
		$c++;	
	}
}

if (count($daytime) != 0){
	$c = 0;
	foreach ($daytime as $range){
		$dc = $daycode[$range[0]];
		for ($i = $range[1]; $i<= $range[2]; $i++){
			$template->assign(array($dc.$i => "background-color:".$daytimecolors[$c].";")); 
		}
		$legend[] = array($range ,$daytimecolors[$c]);
		$c++;	
	}
}

}

############################################################################
# Rechner-spezifische PXE Timeranges
# vom spezifischsten zum unspezifischsten :
# FR_0_7  ->  FR_X_X  ->  X_0_7  ->  X_X_X 
$daytime = array();
$timex = array();
$dayx = array();
$allx = array();

if(count($wopltranges) != 0){
foreach ($wopltranges as $tr){
	if (count($tr[0]) > 1){
		foreach ($tr as $item){
			if ($item[0] != "X" && $item[1] != "X" && $item[2] != "X" && ($item[0] == "MO" || $item[0] == "DI" || $item[0] == "MI" || $item[0] == "DO" || $item[0] == "FR" || $item[0] == "SA" || $item[0] == "SO")){
				$daytime[] = $item;
			}
			if ($item[0] != "X" && $item[1] == "X" && $item[2] == "X"){
				$timex[] = $item;
			}
			if ($item[0] == "X" && $item[1] != "X" && $item[2] != "X"){
				$dayx[] = $item;
			}
			if ($item[0] == "X" && $item[1] == "X" && $item[2] == "X"){
				$allx[] = $item;
			}
		}
	}else{
		if ($tr[0] != "X" && $tr[1] != "X" && $tr[2] != "X" && ($tr[0] == "MO" || $tr[0] == "DI" || $tr[0] == "MI" || $tr[0] == "DO" || $tr[0] == "FR" || $tr[0] == "SA" || $tr[0] == "SO")){
			$daytime[] = $tr;
		}
		if ($tr[0] != "X" && $tr[1] == "X" && $tr[2] == "X"){
			$timex[] = $tr;
		}
		if ($tr[0] == "X" && $tr[1] != "X" && $tr[2] != "X"){
			$dayx[] = $tr;
		}
		if ($tr[0] == "X" && $tr[1] == "X" && $tr[2] == "X"){
			$allx[] = $tr;
		}
	}
}

#print_r($daytime); echo "<br>";
#print_r($timex); echo "<br>"; 
#print_r($dayx); echo "<br>"; 
#print_r($allx); echo "<br>";	

$daycode = array("MO" => "A", "DI" => "B", "MI" => "C", "DO" => "D", "FR" => "E", "SA" => "F", "SO" => "G");
$allxcolors = array("#BEBEBE","A0A0A0","#696969","#EEDFCC","#D8BFD8","#505050");
$dayxcolors = array("#483D8B","#7B68EE","#191970","#8470FF","#708090","#6A5ACD");
$timexcolors = array("#CDC673","#A2CD5A","#BDB76B","#8B864E","#6B8E23","#CDBE70");
$daytimecolors = array("880000","#CD6839","#CC3300","#CC6600","#993300","#8B4C39");


if (count($allx) != 0){
	$c = 0;
	foreach ($allx as $range){
		foreach ($daycode as $dc){
			for ($i = 0; $i <= 23; $i++){
				$template->assign(array($dc.$i => "background-color:".$allxcolors[$c].";")); 
			}
		}
		$legend[] = array($range ,$allxcolors[$c]);
		$c++;	
	}
}

if (count($dayx) != 0){
	$c = 0;
	foreach ($dayx as $range){
		foreach ($daycode as $dc){
			for ($i = $range[1]; $i<= $range[2]; $i++){
				$template->assign(array($dc.$i => "background-color:".$dayxcolors[$c].";")); 
			}
		}
		$legend[] = array($range ,$dayxcolors[$c]);
		$c++;	
	}
}

if (count($timex) != 0){
	$c = 0;
	foreach ($timex as $range){
		$dc = $daycode[$range[0]];
		for ($i = 0; $i<= 23; $i++){
			$template->assign(array($dc.$i => "background-color:".$timexcolors[$c].";")); 
		}
		$legend[] = array($range ,$timexcolors[$c]);
		$c++;	
	}
}

if (count($daytime) != 0){
	$c = 0;
	foreach ($daytime as $range){
		$dc = $daycode[$range[0]];
		for ($i = $range[1]; $i<= $range[2]; $i++){
			$template->assign(array($dc.$i => "background-color:".$daytimecolors[$c].";")); 
		}
		$legend[] = array($range ,$daytimecolors[$c]);
		$c++;	
	}
}

}

$template->assign(array("PXEPLANDESC" => ""));
#print_r($legend);
if (count($legend) != 0){
	$template->define_dynamic("Legende", "Webseite");
	foreach ($legend as $item){
		# Timerange Komponente
		$color = $item[1];
		$template->assign(array("TR1" => $item[0][0],
										"TR2" => $item[0][1],
										"TR3" => $item[0][2],
										"PXEPLANDESC" => $item[0][3],
										"COLOR" => $color));
		$template->parse("LEGENDE_LIST", ".Legende");
	}
}


?>