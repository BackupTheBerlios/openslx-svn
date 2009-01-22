<?php
include('../standard_header.inc.php');

$mccn = $_POST['mccn'];  $mccn = htmlentities($mccn);
$mcdesc = $_POST['mcdesc']; $mcdesc = htmlentities($mcdesc);
$mcday = $_POST['mcday']; $mcday = htmlentities($mcday);
$mcbeg = $_POST['mcbeg']; $mcbeg = htmlentities($mcbeg);
$mcend = $_POST['mcend']; $mcend = htmlentities($mcend); 

$nodeDN = $_POST['nodedn'];
$mnr = $_POST['mnr'];
$sbmnr = $_POST['sbmnr'];
$mcnr = $_POST['mcnr'];

$targets = $_POST['targets'];
#print_r($targets); echo "<br>";
$n = array_keys($targets,'none');
#print_r($n); echo "<br>";
for ($i=0; $i<count($n); $i++){
	$match = array_search('none',$targets);
	array_splice($targets, $match, 1);
}
#echo "Zielobjekte: ";print_r($targets); echo "<br>";

$mcattribs = $_POST['mcattribs'];
if (count($mcattribs) != 0){
	foreach (array_keys($mcattribs) as $key){
		$mcatts[$key] = htmlentities($mcattribs[$key]);
	}
}
# print_r($mcatts); echo "<br><br>";

$seconds = 2;
$get_mccn = str_replace ( " ", "_", $mccn );
$get_mcdesc = str_replace ( " ", "_", $mcdesc );
$get_mcday = str_replace ( " ", "_", $mcday );
$get_mcbeg = str_replace ( " ", "_", $mcbeg );
$get_mcend = str_replace ( " ", "_", $mcend );
$url = "new_mcdef.php?mccn=".$get_mccn."&mcdesc=".$get_mcdesc."&mcday=".$get_mcday."&mcbeg=".$get_mcbeg."&mcend=".$get_mcend."&mnr=".$mnr."&sbmnr=".$sbmnr;

echo " 
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $mccn != "" && $mccn != "Hier_MC_NAME_eintragen"){

	$mccn = "MC_".$mccn;
	# Formulareingaben anpassen
	$expmc = explode(" ",$mccn);
	foreach ($expmc as $word){$expuc[] = ucfirst($word);}
	$mccn = implode(" ",$expuc);
	$mccn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $mccn);
	
	$mctimerange = "";
	
	if (count($targets) != 0){
		foreach ($targets as $targetDN){
		
		$exptargetdn = ldap_explode_dn($targetDN, 1);
		$targetcn = $exptargetdn[0];
		$targettype = $exptargetdn[1];
		
		# Check auf eindeutigen MC-Namen am Zielobjekt 
			$brothers = get_machineconfigs($targetDN,array("cn"));
			$brother = 0;
			foreach ($brothers as $item){
				if( $item['cn'] == $mccn ){
					$mesg = "Es existiert bereits ein PXE Boot Men&uuml; mit dem eingegebenen Namen!<br>
								Bitte geben Sie einen anderen Namen ein.<br><br>";
					$url = "new_mcdef.php?mccn=".$get_mccn."&mcday=".$get_mcday."&mcbeg=".$get_mcbeg."&mcend=".$get_mcend."&mnr=".$mnr."&sbmnr=".$sbmnr;
					$brother = 1;
					break;
				}
			}
			if ($brother == 0){
	
				if ( $mcday != "" && $mcbeg != "" && $mcend != "" && $mcbeg <= $mcend ){
				
					# TimeRange Syntax checken
					$syntax = new Syntaxcheck;
					if ($syntax->check_timerange_syntax($mcday,$mcbeg,$mcend)){
						
						# in Grossbuchstaben
						if (preg_match("/([a-z]+)/",$mcday)){$mcday = strtoupper($mcday);}
						if (preg_match("/([a-z]+)/",$mcbeg)){$mcbeg = strtoupper($mcbeg);}
						if (preg_match("/([a-z]+)/",$mcend)){$mcend = strtoupper($mcend);}
					
						# führende Nullen weg
						$mcbeg = preg_replace ( '/0([0-9])/', '$1', $mcbeg);
						$mcend = preg_replace ( '/0([0-9])/', '$1', $mcend);
						
						# TimeRange auf Überschneidung mit vorhandenen checken
						if(check_timerange($mcday,$mcbeg,$mcend,$targetDN,"")){
							$mctimerange = $mcday."_".$mcbeg."_".$mcend;
						}
						else{
							$mesg = "Es existiert bereits eine MachineConfig, die sich mit der eingegebenen Time Range
										&uuml;berschneidet!<br>
										Die neue MachineConfig wird ohne Time Range angelegt.<br>
										Bitte geben Sie diese anschlie&szlig;end ein.<br><br>";
						}
					}
					else{
						$mesg = "Falsche Syntax in der Time-Range-Eingabe! Die neue MachineConfig wird ohne Time Range angelegt.<br>
									Bitte geben Sie diese anschlie&szlig;end ein.<br><br>";
					}
				}
				else{
					$mesg = "Keine vollst&auml;ndige Time-Range-Eingabe! Die neue MachineConfig wird ohne Time Range angelegt.<br>
								Bitte geben Sie diese anschlie&szlig;end ein.<br><br>";
				}
			
				$mcDN = "cn=".$mccn.",".$targetDN;
				print_r($mcDN); echo "<br>";
						
				if (add_mc($mcDN,$mccn,$mctimerange,$mcdesc,$mcattribs)){			
					$mesg .= "<br>Neue MachineConfig erfolgreich angelegt<br>";
					if ($targettype == "computers"){
						$url = "mcdef.php?dn=".$mcDN."&mnr=1";
					}
					if ($targettype == "groups"){
						$url = "mcdef.php?dn=".$mcDN."&mnr=2";
					}
					if ($targettype == $au_ou){
						$url = "machineconfig_default.php";
					}
				}
				else{
					$mesg .= "<br>Fehler beim anlegen der MachineConfig!<br>";
				}
			}
		}
	}
	else{
		$mesg .= "<br>Sie haben kein Ziel angegeben!<br>";
	}
}

elseif ( $mccn == "" || $mccn == "Hier_MC_NAME_eintragen"){

	$mesg = "Sie haben den Namen der neuen Machine Config nicht angegeben. Dieser ist aber ein notwendiges Attribut.<br>
				Bitte geben Sie ihn an.<br><br>";
	$url = "new_mcdef.php?mccn=Hier_MC_NAME_eintragen&mcdesc=".$get_mcdesc."&mcday=".$get_mcday."&mcbeg=".$get_mcbeg."&mcend=".$get_mcend."&mnr=".$mnr."&sbmnr=".$sbmnr;
}



$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>