<?php

/**  
* host_management_functions.php - Rechner und Gruppen Management Funktions-Bibliothek
* Diese Bibliothek enthält alle Funktionen für die Verwaltung von Rechnern und Rechnergruppen,
* sowie von MachineConfig-Objekten
*
* @param string ldapError
* @param resource ds
* 
* @author Tarik Gasmi
* @copyright Tarik Gasmi
*/  

# Konfiguration laden
require_once("config.inc.php");

$ldapError = null;

###################################################################################################

###############################################################################
# Funktionen zur Verwaltung von Rechnern
#

# Ändern des DN des Rechners, d.h. beim Ändern des Attributes 'hostname'
function modify_host_dn($hostDN, $newhostDN){

	global $ds, $suffix, $auDN, $ldapError;
	
	if (move_subtree($hostDN,$newhostDN)){
		adjust_dn_entries($hostDN,$newhostDN);
		
		# Gruppen anpassen in denen Host Member ist
		$groups = get_groups_member($auDN,array("dn","member"),$hostDN);
		# print_r($groups); echo "<br>";
		if (count($groups != 0)){
			
			foreach ($groups as $group){
				#$entry = array("member");
				if ( count($group['member']) > 1 ){
					for($i=0; $i<count($group['member']); $i++){
						if ($hostDN == $group['member'][$i]){
							$entry ['member'][$i] = $newhostDN;
						}else{
							$entry ['member'][$i] = $group['member'][$i];
						}
					}
					# print_r($entry); echo "<br>";
					ldap_mod_replace($ds,$group['dn'],$entry);
				}
				if ( count($group['member']) == 1 && $group['member'] == $hostDN ){
					$entry['member'] = $newhostDN;
					# print_r($entry); echo "";
					ldap_mod_replace($ds,$group['dn'],$entry);
				}
			}
		}
		
	}
}


# Rechner neu anlegen
function add_host($hostDN,$hostname,$hostdesc,$mac,$ip,$atts){
	
	global $ds, $suffix, $auDN, $assocdom, $ldapError;
	
	$entryhost ['objectclass'][0] = "Host";
	$entryhost ['objectclass'][1] = "dhcpHost";
	$entryhost ['objectclass'][2] = "dhcpOptions";
	$entryhost ['objectclass'][3] = "top";
	$entryhost ["hostname"] = $hostname;
	$entryhost ["domainname"] = $assocdom;
	if ($hostdesc != ""){$entryhost ["description"] = $hostdesc;}
	if ($mac != ""){$entryhost ["hwaddress"] = $mac;}
	foreach (array_keys($atts) as $key){
		if ($atts[$key] != ""){
			$entryhost[$key] = $atts[$key];
		}
	}
	
	print_r($entryhost); echo "<br>";
	if ($result = ldap_add($ds, $hostDN, $entryhost)){
		
		if($ip != ""){
			$syntax = new Syntaxcheck;
			if( $syntax->check_ip_syntax($ip) ){
				$newip_array = array($ip,$ip);
				$newip = implode('_',$newip_array);
				print_r($newip); echo "<br><br>";
				if (new_ip_host($newip,$hostDN,$auDN)){
					echo "IP erfolgreich eingetragen<br><br>";
				}else{
					echo "Fehler beim eintragen der IP<br><br>";
				}
			}else{
				echo "Falsche IP Syntax! IP nicht eingetragen";
			}
		}
		
		return 1;
	}
	else{
		$mesg = "Fehler beim eintragen des neuen Rechners!";
		return 0;
	}
}


# Rechner löschen 
function delete_host($hostDN){

	global $ds, $suffix, $auDN, $ldapError;
	
	$hostdata = get_node_data($hostDN,array("hwaddress","ipaddress"));

	# IP Adresse freigeben
	if ($hostdata['ipaddress'] != ""){
		delete_ip_host($hostDN,$auDN);
	}
	
	if (dive_into_tree_del($hostDN,"")){
		
		# alle DN Objekte in denen Rechner stand ebenfalls löschen 
		# Member in Groups
		$groups = get_groups_member($auDN,array("dn","cn"),$hostDN);
		# echo "Rechner aus den Gruppen entfernen: <br>"; print_r($groups); echo "<br>";
		if (count($groups) != 0){
			$entrydel ['member'] = $hostDN;
			foreach ($groups as $group){
				echo "Entferne gel&ouml;schten Rechner aus Gruppe <b>".$group['cn']."</b> <br>";
				$resultG = ldap_mod_del($ds, $group['dn'], $entrydel);
				
				# Filename in Gruppen-PXEs
				$pxes = get_pxeconfigs($group['dn'],array("dn","cn"));
				if ( count($pxes) != 0 && $hostdata['hwaddress'] != ""){
					foreach ($pxes as $pxe){
						$delfilename ['filename'] = "01-".$hostdata['hwaddress'];
						$resultP = ldap_mod_del($ds,$pxe['dn'],$delfilename);
						echo "Entferne MAC des gel&ouml;schten Rechners aus Gruppen-PXE <b>".$pxe['cn']."</b> <br>";
					}
				}
			}
		}
		
		# DHCP, DNS, RBS Server ... noch todo
		# ... 
		return 1;
	}
	else{
		return 0;
	}
}


###############################################################################
# Funktionen zur Verwaltung von Rechnergruppen
#

# Gruppen DN ändern
function modify_group_dn($groupDN, $newgroupDN){

	global $ds, $suffix, $ldapError;
	
	if (move_subtree($groupDN,$newgroupDN)){
		adjust_dn_entries($groupDN,$newgroupDN);}
}


# Gruppe neu anlegen
function add_group($groupDN,$groupcn,$groupdesc,$addmember){
	
	global $ds, $suffix, $auDN, $assocdom, $ldapError;
	
	$entrygroup ['objectclass'][0] = "groupOfComputers";
	$entrygroup ['objectclass'][1] = "top";
	$entrygroup ["cn"] = $groupcn;
	if ($groupdesc != ""){$entrygroup ["description"] = $groupdesc;}
	
	# Members anlegen (zuerst 'none' rausnehmen)
	$n = array_search('none',$addmember);
	if ($n === 0 ){array_splice($addmember, $n, 1);}

	if (count($addmember) != 0){
		$i = 0;
		foreach ($addmember as $member){
			$exp = explode('_',$member);
			$entrygroup['member'][$i] = $exp[0];
			$i++;
		}
	}
	print_r($entrygroup); echo "<br>";
	
	if ($result = ldap_add($ds, $groupDN, $entrygroup)){
		return 1;
	}
	else{
		return 0;
	}
}


# Gruppe löschen 
function delete_group($groupDN){

	global $ds, $suffix, $auDN, $ldapError;
	
	if (dive_into_tree_del($groupDN,"")){
		
		# alle DN Objekte in denen Gruppe stand ebenfalls löschen 
		# DHCP ... noch todo
		
		return 1;
	}
	else{
		return 0;
	}
}


function add_groupmember($groupDN,$member){
	
	global $ds, $suffix, $auDN, $ldapError;
	
}


function delete_groupmember($groupDN,$member){
	
	global $ds, $suffix, $auDN, $ldapError;
	
}


###############################################################################
# Funktionen zur Verwaltung von MachineConfigs
#

function check_timerange($mcday,$mcbeg,$mcend,$nodeDN,$excepttimerange){

	global $ds, $suffix, $auDN, $ldapError;
	
	$brothers = get_machineconfigs($nodeDN,array("timerange"));
	# keine Überschneidungen pro Spez.Ebene zulassen
	#print_r($brothers); echo "<br><br>";
	if (count($brothers) != 0){
		
		$intersect = 0;
		foreach ($brothers as $item){
			
			# Fall, dass Brother mehrere TimeRanges hat
			if (count($item['timerange']) > 1){
				foreach ($item['timerange'] as $tr){
					
					if($tr != $excepttimerange){
						$exptime = explode('_',$tr);
						$bmcday = $exptime[0];
						$bmcbeg = $exptime[1];
						$bmcend = $exptime[2];
						#echo "mcday:"; print_r($mcday); echo "<br>";
						#echo "bmcday:"; print_r($bmcday); echo "<br>";
						#echo "mcbeg:"; print_r($mcbeg); echo "<br>";
						#echo "bmcbeg:"; print_r($bmcbeg); echo "<br>";
						#echo "mcend:"; print_r($mcend); echo "<br>";
						#echo "bmcend:"; print_r($bmcend); echo "<br>";
						
						if ($mcday == $bmcday){
							if ( $mcbeg > $bmcend || $mcend < $bmcbeg ){
								# keine Überschneidung in der Uhrzeit
							}else{
								# Uhrzeit Überschneidung
								$intersect = 1;
								$intersecttr = $bmcday."_".$bmcbeg."_".$bmcend;
								break;
							}
						}
					}
					
				}
			}
			# Fall, dass Brother nur eine TimeRange hat
			elseif (count($item['timerange']) == 1){
			
				if($item['timerange'] != $excepttimerange){
					$exptime = explode('_',$item['timerange']);
					$bmcday = $exptime[0];
					$bmcbeg = $exptime[1];
					$bmcend = $exptime[2];
					#echo "mcday:"; print_r($mcday); echo "<br>";
					#echo "bmcday:"; print_r($bmcday); echo "<br>";
					#echo "mcbeg:"; print_r($mcbeg); echo "<br>";
					#echo "bmcbeg:"; print_r($bmcbeg); echo "<br>";
					#echo "mcend:"; print_r($mcend); echo "<br>";
					#echo "bmcend:"; print_r($bmcend); echo "<br>";
					
					if ($mcday == $bmcday){
						if ( $mcbeg > $bmcend || $mcend < $bmcbeg ){
							# keine Überschneidung in der Uhrzeit
						}else{
							# Uhrzeit Überschneidung
							$intersect = 1;
							$intersecttr = $bmcday."_".$bmcbeg."_".$bmcend;
							break;
						}
					}
				}
			}
		}
		#echo "intersect: "; print_r($intersect); echo "<br>";
		if ($intersect == 1){
			echo "<b>[".$mcday."_".$mcbeg."_".$mcend."]</b> &uuml;berschneidet sich mit der 
					bereits existierende <b>Time Range [".$intersecttr."]</b> !";
			return 0;
		}else{
			return 1;
		}
	}else{
		return 1;
	}
}



function add_mc($mcDN,$mccn,$mctimerange,$mcdesc,$mcattribs){
	
	global $ds, $suffix, $auDN, $ldapError;
	
	$mcentry ['objectclass'][0] = "MachineConfig";
	$mcentry ['objectclass'][1] = "top";
	$mcentry ['cn'] = $mccn;
	if ($mctimerange != ""){$mcentry ['timerange'] = $mctimerange;}
	if ($mcdesc != ""){$mcentry ['description'] = $mcdesc;}
	if ($mcdesc == ""){$mcentry ['description'] = $mccn;}
	foreach (array_keys($mcattribs) as $key){
		if ($mcattribs[$key] != ""){
			$mcentry[$key] = $mcattribs[$key];
		}
	}
	
	#print_r($mcentry); echo "<br>";
	#print_r($mcDN); echo "<br>";
	if (ldap_add($ds,$mcDN,$mcentry)){
		return 1;
	}
	else{
		return 0;
	}
}

# MachineConfig CN (DN) ändern
function modify_mc_dn($mcDN, $newmcDN){

	global $ds, $suffix, $ldapError;
	
	if (move_subtree($mcDN,$newmcDN)){
		return 1;
	}else{
		return 0;
	}
}

function change_mc_timerange($mcDN,$newmcDN,$mctimerange){
	
	global $ds, $suffix, $auDN, $ldapError;
	
	# move tree
	if (move_subtree($mcDN,$newmcDN)){
		# timerange ändern
		$entrymc ['timerange'] = $mctimerange;
		if (ldap_mod_replace($ds,$newmcDN,$entrymc)){
			return 1;
		}
		else{
			return 0;
		}
	}
	else{
		return 0;
	} 
}



?>