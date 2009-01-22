<?php
include('../standard_header.inc.php');

$pxeDN = $_POST['pxedn'];
$pxecn = "PXE_".$_POST['pxecncp'];
$oldpxecn = "PXE_".$_POST['oldpxecncp'];

$deltr = $_POST['deltr'];

$oldpxeday = $_POST['oldpxedaycp']; $oldpxeday = htmlentities($oldpxeday);
$oldpxebeg = $_POST['oldpxebegcp']; $oldpxebeg = htmlentities($oldpxebeg);
$oldpxeend = $_POST['oldpxeendcp']; $oldpxeend = htmlentities($oldpxeend);

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
#print_r($copytargets); echo "<br>";


$seconds = 2;
$url = "pxe.php?dn=".$pxeDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;
 
echo "  
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>"; 

if ( $pxecn != ""){
	
	# Formulareingaben anpassen
	$exppxe = explode(" ",$pxecn);
	foreach ($exppxe as $word){$expuc[] = ucfirst($word);}
	$pxecn = implode(" ",$expuc);
	$pxecn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $pxecn);
	
	$nomac = 0;
	
	if (count($copytargets) != 0){
		foreach ($copytargets as $targetDN){
			
			$exptargetdn = ldap_explode_dn($targetDN, 1);
			$targetcn = $exptargetdn[0];
			$targettype = $exptargetdn[1];
			
			# falls Target keine MAC hat dann kann keine PXE angelegt werden
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
			
			$brothers = get_pxeconfigs($targetDN,array("cn"));
			$brother = 0;
			foreach ($brothers as $item){
				if( $item['cn'] == $pxecn ){
					$mesg = "Es existiert bereits ein PXE Boot Men&uuml; mit dem eingegebenen Namen!<br>
								Bitte geben Sie einen anderen Namen ein.<br><br>";
					$url = "pxe.php?dn=".$pxeDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;
					$brother = 1;
					break;
				}
			}
			if ($brother == 0 && $nomac == 0){

				$exptargetdn = ldap_explode_dn($targetDN, 1);
				$target = $exptargetdn[0];
				$targettype = $exptargetdn[1];
			
				$oldpxetimerange = $oldpxeday."_".$oldpxebeg."_".$oldpxeend;
				$newpxeDN = "cn=".$pxecn.",".$targetDN;
				print_r($newpxeDN); echo "<br>";
			
				if (dive_into_tree_cp($pxeDN,$newpxeDN)){
					
					$delfileuri = 0;
					# Filename anpassen
					if ($targettype == "rbs"){
						$entrymod ['filename'] = "default";
					}
					if ($targettype == "computers"){
						$macdata = get_node_data($targetDN, array("hwaddress"));
						$entrymod ['filename'] = "01-".$macdata['hwaddress'];
						$delfileuri = 1;
						#$entrymod ['fileuri'] = "01-".$macdata['hwaddress'].".tgz";
					}
					if ($targettype == "groups"){
						$members = get_node_data($targetDN, array("member"));
						if (count($members) != 0){
							foreach ($members['member'] as $hostDN){
								$macdata = get_node_data($hostDN, array("hwaddress"));
								$entrymod ['filename'][] = "01-".$macdata['hwaddress'];
								$delfileuri = 1;
								#$entrymod ['fileuri'] = $target.".tgz";
							}
						}
					}
					if(ldap_mod_replace($ds,$newpxeDN,$entrymod)){
						if($deltr == 1){
							# Timeranges und FileURI im neuen Objekt löschen
							$entrydel ['timerange'] = array();
							if ($delfileuri == 1){
								$entrydel ['fileuri'] = array();
							}
							if ( ldap_mod_del($ds,$newpxeDN,$entrydel) ){
								$mesg .= "<br>PXE Boot Men&uuml; erfolgreich nach ".$target[1]." kopiert<br>";
							}
							else{
								ldap_delete($ds,$newpxeDN);
								$mesg .= "<br>Fehler beim kopieren des PXE Boot Men&uuml;s nach <b>".$target[1]."</b><br>";
							}
						}
					}
					else{
						ldap_delete($ds,$newpxeDN);
						$mesg .= "<br>Fehler beim kopieren des PXE Boot Men&uuml;s nach <b>".$target[1]."</b><br>";
					}
				}
				else{
					$mesg .= "<br>Fehler beim kopieren des PXE Boot Men&uuml;s nach <b>".$target[1]."</b><br>";
				}
			}
		}
	}	
	else{
		$mesg .= "<br>Sie haben kein Ziel angegeben!<br>";
	}
}

elseif ( $pxecn == ""){

	$mesg = "Sie haben den Namen des neuen PXE Boot Men&uuml;s nicht angegeben. Dieser ist aber ein notwendiges Attribut.<br>
				Bitte geben Sie ihn an.<br><br>";
	$url = "pxe.php?dn=".$pxeDN."&mnr=".$mnr."&sbmnr=".$sbmnr."&mcnr=".$mcnr;
}



$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>