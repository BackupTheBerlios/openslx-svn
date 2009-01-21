<?php
include('../standard_header.inc.php');

$groupcn = $_POST['groupcn'];
$oldgroupcn = $_POST['oldgroupcn'];
$groupdesc = $_POST['groupdesc'];
$oldgroupdesc = $_POST['oldgroupdesc'];

$delmember = $_POST['delmember'];

$addmember = $_POST['addmember'];
$n = array_search('none',$addmember);
if ($n === 0 ){array_splice($addmember, $n, 1);}

$groupDN = $_POST['groupdn'];
$sbmnr = $_POST['sbmnr'];

$syntax = new Syntaxcheck;

$groupcn = htmlentities($groupcn);
$oldgroupcn = htmlentities($oldgroupcn);
$groupdesc = htmlentities($groupdesc);
$oldgroupdesc = htmlentities($oldgroupdesc);

/* 
echo "new groupcn:"; print_r($groupcn); echo "<br>";
echo "old groupcn:"; print_r($oldgroupcn); echo "<br>";
echo "new groupdesc:"; print_r($groupdesc); echo "<br>";
echo "old groupdesc:"; print_r($oldgroupdesc); echo "<br><br>";

echo "members to delete:"; print_r($delmember); echo "<br><br>";
echo "members to add:"; print_r($addmember); echo "<br><br>";

echo "Group DN:"; print_r($groupDN); echo "<br>";
echo "submenuNR:"; print_r($submenu); echo "<br><br>";
*/

$seconds = 2;
$url = 'group.php?dn='.$groupDN.'&sbmnr='.$sbmnr;
 
echo "  
<html>
<head>
	<title>AU Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>";

##############################################
# CN (DN) 

if ( $oldgroupcn == $groupcn ){
	# $mesg = "keine Aenderung<br>";
}

if ( $oldgroupcn != "" && $groupcn != "" && $oldgroupcn != $groupcn ){
	echo "Gruppenname aendern<br>";
	# hier noch Syntaxcheck
	# Formulareingaben anpassen
	$expgr = explode(" ",$groupcn);
	foreach ($expgr as $word){$expuc[] = ucfirst($word);}
	$groupcn = implode(" ",$expuc);
	$groupcn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $groupcn);
	
	
	$newgroupDN = "cn=".$groupcn.",cn=groups,".$auDN;
	print_r($newgroupDN); echo "<br><br>";
	
	modify_group_dn($groupDN, $newgroupDN);
	
	# newsubmenu holen...
	$url = 'group.php?dn='.$newgroupDN.'&sbmnr='.$sbmnr;
}

if ( $oldgroupcn != "" && $groupcn == "" ){
	echo "Gruppenname loeschen!<br> 
			Dieses ist Teil des DN, Sie werden die Gruppe komplett l&ouml;schen<br><br>";
	echo "Wollen Sie die Gruppe <b>".$oldgroupcn."</b>mit seinen Hardware-Profilen (MachineConfigs) 
			und PXE Bootmen&uuml;s wirklich l&ouml;schen?<br><br>
			<form action='group_delete.php' method='post'>
				Falls ja:<br><br>
				<input type='hidden' name='dn' value='".$groupDN."'>
				<input type='hidden' name='name' value='".$oldgroupcn."'>
				<input type='Submit' name='apply' value='l&ouml;schen' class='small_loginform_button'><br><br>
			</form>
			<form action='".$url."' method='post'>
				Falls, nein:<br><br>
				<input type='Submit' name='apply' value='zur&uuml;ck' class='small_loginform_button'>
			</form>";
			$seconds = 600;
}


########################################
# Member löschen/aufnehmen 

if ( count($delmember) == 0 || count($addmember) == 0 ){
	# $mesg = "keine Aenderung<br>";
}

if ( count($delmember) != 0 ){
	echo "Gruppen-Mitglieder l&ouml;schen<br>";
	# hier noch Syntaxcheck
	# print_r($delmember); echo "<br><br>";
	
	$i = 0;
	foreach ($delmember as $member){
		$entry['member'][$i] = $member;
		$i++;
	}
	#print_r($entry); echo "<br><br>";
	
	if ($result = ldap_mod_del($ds,$groupDN,$entry)){
		# Fehler hier muessen die verbliebenen Members hin!!!
		# Filenames in PXEs die an der Gruppe hängen anpassen
		$pxes = get_pxeconfigs($groupDN,array("dn"));
		foreach ($pxes as $pxe){
			if ( $entry['member'] > 1 ){
				$j = 0;
				foreach ($entry['member'] as $host){
					$macdata = get_node_data($host, array("hwaddress"));
					$entryfilename ['filename'][$j] = "01-".$macdata['hwaddress'];
					$j++;
				}	
			}
			if ( $entry['member'] == 1 ){
				$macdata = get_node_data($entry['member'], array("hwaddress"));
				$entryfilename ['filename'] = "01-".$macdata['hwaddress'];
			}
			ldap_mod_del($ds,$pxe['dn'],$entryfilename);
		}
		$mesg = "Gruppen-Mitglieder erfolgreich gel&ouml;scht<br><br>";
	}else{
		$mesg = "Fehler beim l&ouml;schen der Gruppen-Mitglieder<br><br>";
	}
}

if ( count($addmember) != 0 ){	
	
	echo "Gruppen-Mitglieder anlegen<br>";
	# hier noch Syntaxcheck
	$members = get_node_data($groupDN,array("member"));
	if ( count($members['member']) == 1 ){
		$member = $members['member'];
		$members = array();
		$members['member'][] = $member;
	}
	if (count($members['member']) != 0){
		foreach ($members['member'] as $member){
	 		$entry2['member'][] = $member;
		}
	}
	$i = 0;
	foreach ($addmember as $member){
		$exp = explode('_',$member);
		# Falls ein neues Mitglied keine MAC hat und an der Gruppe PXEs hängen
		# dann wird diese nicht aufgenommen ... 
		$macdata = get_node_data($exp[0], array("hwaddress"));
		$pxes = get_pxeconfigs($groupDN,array("dn","filename"));
		if ( count($pxes) != 0 && $macdata['hwaddress'] == "" ){
			echo "Rechner ".$exp[1]." hat keine MAC Adresse eingetragen. <br> 
					F&uuml; die Gruppe sind PXE Bootmen&uuml;s definiert. <br>
					Da MACs f&uuml;r die PXE Datei notwendig ist wird der Rechner nicht aufgenommen!";
		}
		else{		
			$entry2['member'][] = $exp[0];
		}
		$i++;
		
	}
	
	#print_r($entry2); echo "<br><br>";
	
	if ($result = ldap_mod_replace($ds, $groupDN, $entry2)){
		
		# PXEs die an der Gruppe hängen anpassen
		$pxes = get_pxeconfigs($groupDN,array("dn"));
		foreach ($pxes as $pxe){
			if ( $entry2['member'] > 1 ){
				$j = 0;
				foreach ($entry2['member'] as $host){
					$macdata = get_node_data($host, array("hwaddress"));
					$entryfilename ['filename'][$j] = "01-".$macdata['hwaddress'];
					$j++;
				}	
			}
			if ( $entry2['member'] == 1 ){
				$macdata = get_node_data($entry2['member'], array("hwaddress"));
				$entryfilename ['filename'] = "01-".$macdata['hwaddress'];
			}
			ldap_mod_replace($ds,$pxe['dn'],$entryfilename);
		}
		$mesg = "Gruppen-Mitglieder erfolgreich angelegt<br><br>";
	}else{
		$mesg = "Fehler beim anlegen der Gruppen-Mitglieder<br><br>";
	}
}


#####################################
# Description
 
if ( $oldgroupdesc == $groupdesc ){
	# $mesg = "keine Aenderung<br>";
}

if ( $oldgroupdesc == "" && $groupdesc != "" ){
	echo "Gruppen-Beschreibung neu anlegen<br>";
	# hier noch Syntaxcheck
	$entry['description'] = $groupdesc;
	if($result = ldap_mod_add($ds,$groupDN,$entry)){
		$mesg = "Gruppen-Beschreibung erfolgreich eingetragen<br><br>";
	}else{
		$mesg = "Fehler beim eintragen der Gruppen-Beschreibung<br><br>";
	}
}

if ( $oldgroupdesc != "" && $groupdesc != "" && $oldgroupdesc != $groupdesc ){
	echo "Gruppen-Beschreibung aendern<br>";
	# hier noch Syntaxcheck
	$entry['description'] = $groupdesc;
	if($result = ldap_mod_replace($ds,$groupDN,$entry)){
		$mesg = "Gruppen-Beschreibung erfolgreich geaendert<br><br>";
	}else{
		$mesg = "Fehler beim aendern der Gruppen-Beschreibung<br><br>";
	}
}

if ( $oldgroupdesc != "" && $groupdesc == "" ){
	echo "Gruppen-Beschreibung loeschen<br>";
	# hier noch Syntaxcheck
	$entry['description'] = $oldgroupdesc;
	if($result = ldap_mod_del($ds,$groupDN,$entry)){
		$mesg = "Gruppen-Beschreibung erfolgreich geloescht<br><br>";
	}else{
		$mesg = "Fehler beim loeschen der Gruppen-Beschreibung<br><br>";
	}
}





$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>