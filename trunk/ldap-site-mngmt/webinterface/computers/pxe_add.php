<?php
include('../standard_header.inc.php');

$pxecn = $_POST['pxecn'];  $pxecn = htmlentities($pxecn);
#$rbsDN = $_POST['rbs'];

$pxeday = $_POST['pxeday']; $pxeday = htmlentities($pxeday);
$pxebeg = $_POST['pxebeg']; $pxebeg = htmlentities($pxebeg);
$pxeend = $_POST['pxeend']; $pxeend = htmlentities($pxeend);

$conffile = $_POST['conffile'];  $conffile = htmlentities($conffile);

$mnr = $_POST['mnr'];

$targets = $_POST['targets'];
#print_r($targets); echo "<br>";
$n = array_keys($targets,'none');
#print_r($n); echo "<br>";
for ($i=0; $i<count($n); $i++){
	$match = array_search('none',$targets);
	array_splice($targets, $match, 1);
}
#echo "Zielobjekte: ";print_r($targets); echo "<br>";

$pxeattribs = $_POST['attribs'];
if (count($pxeattribs) != 0){
	foreach (array_keys($pxeattribs) as $key){
		$pxeatts[$key] = htmlentities($pxeattribs[$key]);
	}
}
# print_r($mcatts); echo "<br><br>";

$seconds = 20;
$get_pxecn = str_replace ( " ", "_", $pxecn );
$get_pxeday = str_replace ( " ", "_", $pxeday );
$get_pxebeg = str_replace ( " ", "_", $pxebeg );
$get_pxeend = str_replace ( " ", "_", $pxeend );
$url = "new_pxe.php?pxecn=".$get_pxecn."&pxeday=".$get_pxeday."&pxebeg=".$get_pxebeg."&pxeend=".$get_pxeend."&mnr=".$mnr;

echo " 
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $pxecn != "" && $pxecn != "Hier_PXE_NAME_eintragen" && $rbsDN != "none" ){

	$pxecn = "PXE_".$pxecn;
	# Formulareingaben anpassen
	$exppxe = explode(" ",$pxecn);
	foreach ($exppxe as $word){$expuc[] = ucfirst($word);}
	$pxecn = implode(" ",$expuc);
	$pxecn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $pxecn);
	
	$pxetimerange = "";
	$nomac = 0;
	
	if (count($targets) != 0){
		foreach ($targets as $targetDN){
		
			$exptargetdn = ldap_explode_dn($targetDN, 1);
			$targetcn = $exptargetdn[0];
			$targettype = $exptargetdn[1];
			
			# falls Target keine MAC hat dann kann keine PXE angelegt werden
			# jetzt schon vorher bei der Zielobjektauswahl abgefangen
			if ($targettype == "computers"){
				$macdata = get_node_data($targetDN, array("hwaddress"));
				if ($macdata['hwaddress'] == ""){
					$nomac = 1;
					echo "F&uuml;r den Ziel-Rechner ist keine MAC Adresse eingetragen <br>
							Das PXE Bootmen&uuml; wird nicht angelegt. <br>
							<br>
							Tragen Sie zuerst eine MAC ein!<br><br>";
				}
			}
			if ($targettype == "groups"){
				$members = get_node_data($targetDN, array("member"));
				if (count($members) > 1){
					foreach ($members['member'] as $hostDN){
						$macdata = get_node_data($hostDN, array("hwaddress","hostname"));
						if ($macdata['hwaddress'] == ""){
							$nomac = 1;
							echo "F&uuml;r den Gruppen-Rechner <b>".$macdata['hostname']."</b> ist keine MAC Adresse eingetragen <br>
									Das PXE Bootmen&uuml; f&uuml;r die Gruppe wird nicht angelegt. <br>
									<br>
									Tragen Sie zuerst bei Rechner <b>".$macdata['hostname']."</b> eine MAC ein!<br><br>";
						}
					}
				}
				if (count($members) == 1){
					$macdata = get_node_data($members['member'], array("hwaddress"));
					if ($macdata['hwaddress'] == ""){
						$nomac = 1;
						echo "F&uuml;r den Gruppen-Rechner <b>".$macdata['hostname']."</b> ist keine MAC Adresse eingetragen <br>
								Das PXE Bootmen&uuml; f&uuml;r die Gruppe wird nicht angelegt. <br>
								<br>
								Tragen Sie zuerst bei Rechner <b>".$macdata['hostname']."</b> eine MAC ein!<br><br>";
					}
				}
			}
			
			# Check auf eindeutigen PXE-Namen (könnte man erweitern auf kompletten RBS) 
			$brothers = get_pxeconfigs($targetDN,array("cn"));
			$brother = 0;
			foreach ($brothers as $item){
				if( $item['cn'] == $pxecn ){
					$mesg = "Es existiert bereits ein PXE Boot Men&uuml; mit dem eingegebenen Namen!<br>
								Bitte geben Sie einen anderen Namen ein.<br><br>";
					$url = "new_pxe.php?pxecn=".$get_pxecn."&pxeday=".$get_pxeday."&pxebeg=".$get_pxebeg."&pxeend=".$get_pxeend."&mnr=".$mnr."&sbmnr=".$sbmnr;
					$brother = 1;
					break;
				}
			}
			if ($brother == 0 && $nomac == 0){
	
				if ( $pxeday != "" && $pxebeg != "" && $pxeend != "" && $pxebeg <= $pxeend ){
				
					# TimeRange Syntax checken
					$syntax = new Syntaxcheck;
					if ($syntax->check_timerange_syntax($pxeday,$pxebeg,$pxeend)){
						
						# in Grossbuchstaben
						if (preg_match("/([a-z]+)/",$pxeday)){$pxeday = strtoupper($pxeday);}
						if (preg_match("/([a-z]+)/",$pxebeg)){$pxebeg = strtoupper($pxebeg);}
						if (preg_match("/([a-z]+)/",$pxeend)){$pxeend = strtoupper($pxeend);}
					
						# führende Nullen weg
						$pxebeg = preg_replace ( '/0([0-9])/', '$1', $pxebeg);
						$pxeend = preg_replace ( '/0([0-9])/', '$1', $pxeend);
						
						# TimeRange auf Überschneidung mit vorhandenen checken
						if(check_timerange_pxe($pxeday,$pxebeg,$pxeend,$targetDN,"")){
							$pxetimerange = $pxeday."_".$pxebeg."_".$pxeend;
						}
						else{
							$mesg = "Es existiert bereits ein PXE Boot Men&uuml;, das sich mit der eingegebenen Time Range
										&uuml;berschneidet!<br>
										Das neue PXE Boot Men&uuml; wird ohne Time Range angelegt.<br>
										Bitte geben Sie diese anschlie&szlig;end ein.<br><br>";
						}
					}
					else{
						$mesg = "Falsche Syntax in der Time-Range-Eingabe! Das neue PXE Boot Men&uuml; wird ohne Time Range angelegt.<br>
									Bitte geben Sie diese anschlie&szlig;end ein.<br><br>";
					}
				}
				else{
					$mesg = "Keine vollst&auml;ndige Time-Range-Eingabe! Das neue PXE Boot Men&uuml; wird ohne Time Range angelegt.<br>
								Bitte geben Sie diese anschlie&szlig;end ein.<br><br>";
				}
	
				$pxeDN = "cn=".$pxecn.",".$targetDN;
				
				
				# PXE Dateinamen bestimmen, MAC(s)
				$filenames = array();
				if ($targettype == "computers"){
					$macdata = get_node_data($targetDN, array("hwaddress"));
					$pxemac = str_replace (":","-",$macdata['hwaddress']);
					$filenames[] = "01-".$pxemac;
				}
				if ($targettype == "groups"){
					$members = get_node_data($targetDN, array("member"));
					if (count($members) > 1){
						foreach ($members['member'] as $hostDN){
							$macdata = get_node_data($hostDN, array("hwaddress"));
							$pxemac = str_replace (":","-",$macdata['hwaddress']);
							$filenames[] = "01-".$pxemac;
						}
					}
					if (count($members) == 1){
						$macdata = get_node_data($members['member'], array("hwaddress"));
						$pxemac = str_replace (":","-",$macdata['hwaddress']);
						$filenames[] = "01-".$pxemac;
					}
				}
				echo "filenames: ";print_r($filenames); echo "<br>";
				#$ldapuri = LDAP_HOST."/dn=cn=computers,".$auDN;
				
				# rbsDN bestimmen
				$rbs = get_node_data($targetDN,array("hlprbservice"));
				$rbsDN = $rbs['hlprbservice'];
				print_r($rbsDN);
				
				if (add_pxe($pxeDN,$pxecn,$rbsDN,$pxetimerange,$pxeattribs,$filenames,$conffile)){			
					$mesg .= "<br>Neues PXE Boot Men&uuml; erfolgreich angelegt<br>";
					if ($targettype == "computers"){
						$mnr=1;
					}
					if ($targettype == "groups"){
						$mnr=2;
					}
					$url = "pxe.php?dn=".$pxeDN."&mnr=".$mnr;
				}
				else{
					$mesg .= "<br>Fehler beim anlegen des PXE Boot Men&uuml;s!<br>";
				}
			}
		}
	}
	else{
		$mesg .= "<br>Sie haben kein Ziel angegeben!<br>";
	}
}


elseif ( $pxecn == "" || $pxecn == "Hier_PXE_NAME_eintragen" || $rbsDN == "none" ){

	$mesg = "Sie haben den Namen des neuen PXE Boot Men&uuml;s nicht angegeben oder den
				Remote Boot Dienst nicht ausgew&auml;hlt. Beide sind aber ein notwendige Attribute.<br>
				Bitte geben Sie sie an.<br><br>";
	$url = "new_pxe.php?pxecn=Hier_PXE_NAME_eintragen&pxeday=".$get_pxeday."&pxebeg=".$get_pxebeg."&pxeend=".$get_pxeend."&mnr=".$mnr."&sbmnr=".$sbmnr;
}



$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>