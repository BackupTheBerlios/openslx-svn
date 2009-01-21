<?php
include('../standard_header.inc.php');

$mcDN = $_POST['mcdn'];
$mccn = "MC_".$_POST['mccncp'];
$oldmccn = "MC_".$_POST['oldmccncp'];

$deltr = $_POST['deltr']; 

$nodeDN = $_POST['nodedn'];
$mnr = $_POST['mnr'];
$sbmnr = $_POST['sbmnr'];
$mcnr = $_POST['mcnr'];

$copytargets = $_POST['copytargets']; 
#print_r($copytargets); echo "<br>";
$n = array_keys($copytargets,'none');
#print_r($n); echo "<br>";
for ($i=0; $i<count($n); $i++){
	$match = array_search('none',$copytargets);
	array_splice($copytargets, $match, 1);
}
print_r($copytargets); echo "<br>";


$seconds = 2;
$url = "mcdef.php?dn=".$mcDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;
 
echo "  
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $mccn != ""){
	
	# Formulareingaben anpassen
	$expmc = explode(" ",$mccn);
	foreach ($expmc as $word){$expuc[] = ucfirst($word);}
	$mccn = implode(" ",$expuc);
	$mccn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $mccn);
	
	
	if (count($copytargets) != 0){
		foreach ($copytargets as $targetDN){
		
			$brothers = get_machineconfigs($targetDN,array("cn"));
			$brother = 0;
			foreach ($brothers as $item){
				if( $item['cn'] == $mccn ){
					$mesg = "Es existiert bereits eine Machine Config mit dem eingegebenen Namen!<br>
								Bitte geben Sie einen anderen Namen ein.<br><br>";
					$url = "mcdef.php?dn=".$mcDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;
					$brother = 1;
					break;
				}
			}
			if ($brother == 0){

				print_r($targetDN); echo "<br>";
				$exptarget = explode(',',$targetDN);
				$target = explode('=',$exptarget[0]);
				
				$newmcDN = "cn=".$mccn.",".$targetDN;
				print_r($newmcDN); echo "<br>";
				
			
				if (dive_into_tree_cp($mcDN,$newmcDN)){
					if($deltr == 1){
						$entrydel ['timerange'] = array();
						# Timeranges im neuen Objekt löschen
						if (ldap_mod_del($ds,$newmcDN,$entrydel)){
							$mesg .= "<br>MachineConfig erfolgreich nach ".$target[1]." kopiert<br>";
						}
						else{
							ldap_delete($ds,$newmcDN);
							$mesg .= "<br>Fehler beim kopieren der MachineConfig nach <b>".$target[1]."</b><br>";
						}
					}
				}
				else{
					$mesg .= "<br>Fehler beim kopieren der MachineConfig nach <b>".$target[1]."</b><br>";
				}
			}
		}
	}	
	else{
		$mesg .= "<br>Sie haben kein Ziel angegeben!<br>";
	}
}

elseif ( $mccn == ""){

	$mesg = "Sie haben den Namen der neuen Machine Config nicht angegeben. Dieser ist aber ein notwendiges Attribut.<br>
				Bitte geben Sie ihn an.<br><br>";
	$url = "mcdef.php?dn=".$mcDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;
}



$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>