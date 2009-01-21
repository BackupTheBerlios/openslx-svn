<?php

/**  
* au_management_functions.php - Administrative Unit Management Funktions-Bibliothek
* Diese Bibliothek enthält alle Funktionen für die Verwaltung von AUs, deren DNS Domains, sowie 
* zum Rollen-Management 
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

########################################################################################################



###############################################################################
# Funktionen zur Verwaltung der AU (und Child-AUs)
#


# Ändern des DN der AU, d.h. beim Ändern des Attributes 'ou'
function modify_au_dn($auDN, $newauDN){

	global $ds, $suffix, $ldapError;
	
	if (move_subtree($auDN,$newauDN)){
		adjust_dn_entries($auDN,$newauDN);} 
}



# Anlegen neue untergeordnete AU
function new_childau($childDN,$childou,$childcn,$childdesc,$mainadmin){

	global $ds, $suffix, $auDN, $ldapError;
	
	$entryAU ["objectclass"][0] = "administrativeunit";
	$entryAU ["objectclass"][1] = "organizationalunit";
	$entryAU ["objectclass"][2] = "top";
	$entryAU ["ou"] = $childou;
	if ($childcn != ""){$entryAU ["cn"] = $childcn;}
	if ($childdesc != ""){$entryAU ["description"] = $childdesc;}
	
	if ($resultAU = ldap_add($ds,$childDN,$entryAU)){
	
		# alle Au Container anlegen
		$containers = array("computers","dhcp","groups","rbs","roles");
		foreach ($containers as $cont){
			$entryCont = array();
			$entryCont ['objectclass'] = "AUContainer";
			$entryCont ['cn'] = $cont;
			#print_r($entryRolesCont); echo "<br><br>";
			$resultC = ldap_add($ds,"cn=".$cont.",".$childDN,$entryCont);
			if (!($resultC)) break;
		}
	
		# MainAdmin anlegen
		$entryMA ['objectclass'] = "groupOfNames";
		$entryMA ['cn'] = "MainAdmin";
		$entryMA ['member'] = $mainadmin;
		if ($resultMA = ldap_add($ds,"cn=MainAdmin,cn=roles,".$childDN,$entryMA)){
			$admins = array("HostAdmin","DhcpAdmin","ZoneAdmin");
			foreach ($admins as $admin){
				$entryAdmin ['objectclass'] = "Admins";
				$entryAdmin ['cn'] = $admin;
				ldap_add($ds,"cn=".$admin.",cn=roles,".$childDN,$entryAdmin);
			}
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



# Löschen untergeordnete AU (d.h. deren untergeordnete AUs werden als neue uAUs integriert)
function delete_childau($childDN,$childou,$delmodus){

	global $ds, $suffix, $auDN, $domDN, $assocdom, $ldapError;
	
	if ( $delmodus == "integrate"){

		# Associated DNS Domain integrieren
		$childdc = get_domain_data($childDN,array("dn","associatedname"));
		print_r($childdc); echo "<br>";
		# wenn einzige AU dann einfach in Parentdomain aufnehmen und betroffene Einträge löschen
		if (count($childdc[0]['associatedname']) == 1 ){
			echo "einzige AU<br>";
			# dc Childs verschieben
			$dcchilds = get_dc_childs($childdc[0]['dn'],array("dn","dc"));
			# print_r($dcchilds); echo "<br>";
			if (count($dcchilds) != 0){
				foreach ($dcchilds as $dcc){
					# print_r($dcc['dn']); echo " >> "; print_r("dc=".$dcc['dc'].",".$domDN); echo "<br>";
					if(move_subtree($dcc['dn'],"dc=".$dcc['dc'].",".$domDN)){
						$newdom = $dcc['dc'].".".$assocdom;
						#print_r($newdom); echo "<br><br>";
						dive_into_dctree_adapt("dc=".$dcc['dc'].",".$domDN,$newdom);
					}
				}
			}
			
			# alten dc-Knoten löschen
			dive_into_tree_del($childdc[0]['dn'],"");
				
		}
		# wenn noch andere AUs in der Domain, dann nur betroffene Einträge entfernen
		if (count($childdc[0]['associatedname']) > 1 ){
			echo "mehrere AUs<br>";
			# ChildAU-Rollen unterhalb dc-Knoten löschen (nur diese)(oder übernehmen: MA zu HA, HA zu HA)
			$roles = get_roles($childDN);
			#print_r($roles); echo "<br>";
			if(count($roles['MainAdmin']) != 0){
				$mainadmins = $roles['MainAdmin'];
				for ($i=0; $i<count($mainadmins); $i++){
					$entryRoleMain ['member'][$i] = $mainadmins[$i];
				}
				#print_r($entryRoleHost); echo "<br>";
				$resultMA = ldap_mod_del($ds,"cn=MainAdmin,cn=roles,".$childdc[0]['dn'],$entryRoleMain);
			}
			if(count($roles['HostAdmin']) != 0){
				$hostadmins = $roles['HostAdmin'];
				for ($i=0; $i<count($hostadmins); $i++){
					$entryRoleHost ['member'][$i] = $hostadmins[$i];
				}
				#print_r($entryRoleHost); echo "<br>";
				$resultHA = ldap_mod_del($ds,"cn=HostAdmin,cn=roles,".$childdc[0]['dn'],$entryRoleHost);
			}
			if(count($roles['ZoneAdmin']) != 0){
				$zoneadmins = $roles['ZoneAdmin'];
				for ($i=0; $i<count($zoneadmins); $i++){
					$entryRoleZone ['member'][$i] = $zoneadmins[$i];
				}
				$resultZA = ldap_mod_del($ds,"cn=ZoneAdmin,cn=roles,".$childdc[0]['dn'],$entryRoleZone);
			}			
			
			$entrydel ['associatedname'] = $childDN;
			# print_r($entrydel); echo "<br>";
			ldap_mod_del($ds, $childdc[0]['dn'], $entrydel);
			$zentries = get_zone_entries_assocname($childdc[0]['dn'],array("dn"),$childDN);
			# print_r($zentries); echo "<br>";
			foreach ($zentries as $ze){ 
				# print_r($ze['dn']); echo "<br>";
				ldap_delete($ds, $ze['dn']);
			}
		}
		
		# Rechner (mit IP) + dranhängende MCs, PXEs verschieben
		$hosts = get_hosts($childDN,array("dn","hostname"));
		if (count($hosts) != 0){
			foreach ($hosts as $host){
				# print_r($host['dn']); echo "<br>";
				# print_r($host['hostname']);  echo "<br>";
				# print_r("hostname=".$host['hostname']."-int-".$childou.",cn=computers,".$auDN); echo "<br><br>";
				if (move_subtree($host['dn'], "hostname=".$host['hostname']."-ex-".$childou.",cn=computers,".$auDN)){
					$newhostDN = "hostname=".$host['hostname']."-ex-".$childou.",cn=computers,".$auDN;
					$dhcp = get_node_data($newhostDN, array("dhcphlpcont"));
					# print_r($dhcp); echo "<br>";
					if ($dhcp['dhcphlpcont'] != ""){
						$entrydel ['dhcphlpcont'] = array();
						$entrydel ['objectclass'] = "dhcpHost";
						# print_r($dhcphlpcont);
						ldap_mod_del($ds, $newhostDN, $entrydel);
					}	
				}
			}
		}	
		# DHCP Objekte IP Ranges löschen
		$subnets = get_subnets($childDN,array("dn"));
		# print_r($subnets); echo "<br>";
		if (count($subnets) != 0){
			foreach ($subnets as $subnet){
				# print_r($subnet['dn']); echo "<br>";
				delete_ip_dhcprange($subnet['dn'],$childDN);	
			}
		} # DHCP Pools auch noch	
		
		# Freie IP Bereiche zurücknehmen
		$fipb_array = get_freeipblocks_au($childDN);
		# print_r($fipb_array); echo "<br>";
		# print_r(count($fipb_array)); echo "<br>";
		if (count($fipb_array) == 1 && $fipb_array[0] != ""){
			$entry_ipblock ['freeipblock'] = $fipb_array[0];
			# print_r($entry_ipblock); echo "<br>";
			ldap_mod_add($ds,$auDN,$entry_ipblock);
		}
		if (count($fipb_array) > 1 ){
			foreach ($fipb_array as $fipb){
				$entry_ipblock ['FreeIPBlock'][] = $fipb;
				# print_r($entry_ipblock); echo "<br>";
				ldap_mod_add($ds,$auDN,$entry_ipblock);
			}
		}
		merge_ipranges($auDN);
		
		
		# Verschieben der Childs an neue Stelle
		$child_childs = get_childau($childDN,array("dn","ou"));
		# print_r($child_childs); echo "<br>";
		if (count($child_childs) != 0){
			foreach ($child_childs as $cc){
				$child_childDN = $cc['dn'];
				$newccDN = "ou=".$cc['ou'].",".$auDN;
				# print_r($child_childDN); echo " >> ";
				# print_r($newccDN); echo "<br>";
				if (move_subtree($child_childDN,$newccDN)){
					adjust_dn_entries($child_childDN,$newccDN);
				}
			}
		}
		
		# Löschen des AU Knotens
		dive_into_tree_del($childDN,"");
		
		$mesg = "<br>Erfolgreich gel&ouml;scht mit Integration<br>";
		return $mesg;
	}
	
	if ( $delmodus == "complete" ){
		# IP Bereiche zurück
		# DNS Teilbaum Objekte löschen
		# alles rekursive löschen 
	
		/*if (dive_into_tree_del($dcDN,"")){
			$delentry ['objectclass'] = "domainrelatedobject";
			$delentry ['associateddomain'] = $domsuffix;
			#print_r($delentry); echo "<br>";
			$delresult = ldap_mod_del($ds,$childDN,$delentry);
		   if ($delresult){
				$mesg = "Domain komplett gel&ouml;scht<br>";
			}else{$mesg = "Fehler! ldap_mod_del<br>";}
		}else{$mesg = "Fehler! dive_into_tree_del<br>";}
		*/
		$mesg = "Komplettes l&ouml;schen mometan noch nicht unterst&uuml;tzt.<br>
					Nur eine Ebene mit Integration ...<br>";
		return $mesg;
	}
}




###############################################################################
# Funktionen zur Verwaltung von Domains
# 


# Anlegen Domain beim Anlegen einer Child-AU
function new_child_domain($childdomain, $childDN, $assocdom, $domDN){
	
	global $ds, $suffix, $domprefix, $domsuffix, $ldapError;
	$domsuffix_actual = $domsuffix;
	
	# ChildAU in gleicher Domain wie AU	
	if ( $childdomain == "" || $childdomain == $domprefix ){
		
		$entryDC ["associatedname"] = $childDN;
		$resultDC = ldap_mod_add($ds,$domDN,$entryDC);
		if ($resultDC){
			# HostAdmins übernehmen, welche Admins noch? MainAdmin?
			$roles = get_roles($childDN);
			if(count($roles['MainAdmin']) != 0){
				$mainadmins = $roles['MainAdmin'];
				for ($i=0; $i<count($mainadmins); $i++){
					$entryRoleMain ['member'][$i] = $mainadmins[$i];
				}
				#print_r($entryRoleHost); echo "<br>";
				$resultMA = ldap_mod_add($ds,"cn=MainAdmin,cn=roles,".$domDN,$entryRoleMain);
			}
			if(count($roles['HostAdmin']) != 0){
				$hostadmins = $roles['HostAdmin'];
				for ($i=0; $i<count($hostadmins); $i++){
					$entryRoleHost ['member'][$i] = $hostadmins[$i];
				}
				#print_r($entryRoleHost); echo "<br>";
				$resultHA = ldap_mod_add($ds,"cn=HostAdmin,cn=roles,".$domDN,$entryRoleHost);
			}
			# Domainname zu associatedDomain der ChildAU
			$entryAD['objectclass'] = "domainRelatedObject";
			$entryAD['associateddomain'] = $assocdom;
			$resultAD = ldap_mod_add($ds,$childDN,$entryAD);		
			if($resultAD){return 1;}else{return 0;}
		}
		else{return 0;}	
	}
	
	# ChildAU in eigner Domain (inklusive Subdomain von AU Domain)
	if ( $childdomain != "" && $childdomain != $domprefix ){
		
		# entsprechenden DC Knoten anlegen, sowie Roles (MainAdmin, HostAdmin)
		$dc_array = explode('.',$childdomain);
		$dc_array = array_reverse($dc_array);
		$dcDN = "ou=DNS,".$suffix;
		# $childdomainfull = $childdomain.".".$domsuffix;
		#print_r($dc_array);
		foreach ($dc_array as $dc){
			$resultsum = false;
			if (check_for_dc($dcDN,$dc)){
				echo "dc <b>".$dc."</b> schon vorhanden ... n&auml;chster dc<br>";
				$domsuffix_actual = $dc.".".$domsuffix_actual;
				$dcDN = "dc=".$dc.",".$dcDN;
			}
			else{
				$dcDN = "dc=".$dc.",".$dcDN;
				
				$entryDC ["objectclass"][0] = "dnsdomain";
				$entryDC ["objectclass"][1] = "domainrelatedobject";
				$entryDC ["objectclass"][2] = "top";
				$entryDC ["dc"] = $dc;
				$entryDC ["associatedname"] = $childDN;
				$entryDC ["associateddomain"] = $dc.".".$domsuffix_actual;
				#print_r($entryDC); echo "<br>";
				#print_r($dcDN); echo "<br><br>";
				$resultDC = ldap_add($ds,$dcDN,$entryDC);
				if ($resultDC){
					$domsuffix_actual = $dc.".".$domsuffix_actual;
				
					#print_r($dcDN); echo"<br><br>";
				
					$entryRolesCont ['objectclass'] = "AUContainer";
					$entryRolesCont ['cn'] = "roles";
					#print_r($entryRolesCont); echo "<br><br>";
					$resultRC = ldap_add($ds,"cn=roles,".$dcDN,$entryRolesCont);
					if ($resultRC){
						# Rollen eintragen
						$roles = get_roles($childDN);
						#print_r($roles); echo "<br><br>";
						$mainadmins = $roles['MainAdmin'];
						$entryRoleMain ['objectclass'] = "groupOfNames";
						$entryRoleMain ['cn'] = "MainAdmin";
						for ($i=0; $i<count($mainadmins); $i++){
							$entryRoleMain ['member'][$i] = $mainadmins[$i];
						}
						#print_r($entryRoleMain); echo "<br>";
						$resultMA = ldap_add($ds,"cn=MainAdmin,cn=roles,".$dcDN,$entryRoleMain);
						
						$entryRoleHost ['objectclass'] = "Admins";
						$entryRoleHost ['cn'] = "HostAdmin";
						if(count($roles['HostAdmin']) != 0){
							$hostadmins = $roles['HostAdmin'];
							for ($i=0; $i<count($hostadmins); $i++){
								$entryRoleHost ['member'][$i] = $hostadmins[$i];
							}
							#print_r($entryRoleHost); echo "<br>";
						}
						$resultHA = ldap_add($ds,"cn=HostAdmin,cn=roles,".$dcDN,$entryRoleHost);
						
						$entryRoleZone ['objectclass'] = "Admins";
						$entryRoleZone ['cn'] = "ZoneAdmin";	
						$resultZA = ldap_add($ds,"cn=ZoneAdmin,cn=roles,".$dcDN,$entryRoleZone);
						
						if ($resultMA){$resultsum = true;}
					}
				}
				break;	# damit dc-Zuwachs immer nur um eine neue Ebene moeglich
			}	
		}
		# Domainname zu associatedDomain der ChildAU
		if ($resultsum == true){
			$entryAD['objectclass'] = "domainRelatedObject";
			$entryAD['associateddomain'] = $domsuffix_actual;
			$resultAD = ldap_mod_add($ds,$childDN,$entryAD);
		}
		# fixme: fehlt noch anlegen der INCLUDE-Direktive in der parentdomain
		if($resultAD){return 1;}
		else{return 0;}		
	}
}


# Domain einer Child-AU ändern
function change_child_domain($childdomain, $oldchilddomain, $childDN, $assocdom, $domDN, $domprefix){
	
	global $ds, $suffix, $domsuffix, $ldapError;
	#print_r($oldchilddomain); echo "<br>";
	#print_r($domprefix); echo "<br>";
	# dcDNnew
	$dcDN = "ou=DNS,".$suffix;
	$dc_array = explode('.',$childdomain);
	$dc_array = array_reverse($dc_array);
	$dcDNnew = "";
	foreach ($dc_array as $dc){
		if (check_for_dc($dcDN,$dc)){
			$dcDN = "dc=".$dc.",".$dcDN;			
		}
		else{
			$dcDN = "dc=".$dc.",".$dcDN;
			$dcDNnew .= $dcDN;
			break;
		}
	}
	# dcDNold
	$dcDNold = "ou=DNS,".$suffix;
	$dcold_array = explode('.',$oldchilddomain);
	$dcold_array = array_reverse($dcold_array);
	foreach ($dcold_array as $dc){
		$dcDNold = "dc=".$dc.",".$dcDNold;
	}
	
	#print_r($dcDNnew); echo "<br>";
	#print_r($dcDNold); echo "<br>";
	# Aus eigener AU Domain heraus in neue nicht AU Domain, d.h. dcDNold = domDN
	# Subdomain oder neue Domain anlegen
	if ($oldchilddomain == $domprefix){
		
		# associatedDomain aus ChildAU entfernen
		$entryAD['objectclass'] = "domainRelatedObject"; 
		$entryAD['associateddomain'] = $assocdom;
		#print_r($entryAD); echo "<br>";
		if ($resultAD = ldap_mod_del($ds,$childDN,$entryAD)){
		
			# neuen dc Knoten anlegen mit Rollen ...
			if(new_child_domain($childdomain, $childDN, $assocdom, $domDN)){
				
				# associatedName ChildDN aus altem dc-Knoten entfernen
				$entryAN ['associatedname'] = $childDN;
				#print_r($entryAN); echo "<br>";
				$result = ldap_mod_del($ds,$domDN,$entryAN);
				
				# Eigene Rollen aus dc-Knoten enrfernen 
				$roles = get_roles($childDN);
				if(count($roles['MainAdmin']) != 0){
					$mainadmins = $roles['MainAdmin'];
					if (count($mainadmins) > 1){
						for ($i=0; $i<count($mainadmins); $i++){
							$entryRoleMain ['member'][$i] = $mainadmins[$i];
						}
					}else{
						$entryRoleMain ['member'] = $mainadmins[0];
					}
					#print_r($entryRoleMain); echo "<br>";
					$resultMA = ldap_mod_del($ds,"cn=MainAdmin,cn=roles,".$dcDNold,$entryRoleMain);
				}
				if(count($roles['HostAdmin']) != 0){
					$hostadmins = $roles['HostAdmin'];
					if (count($hostadmins) > 1){
						for ($i=0; $i<count($hostadmins); $i++){
							$entryRoleHost ['member'][$i] = $hostadmins[$i];
						}
					}else{
						$entryRoleHost ['member'] = $hostadmins[0];
					}
					#print_r($entryRoleHost); echo "<br>"; 
					$resultHA = ldap_mod_del($ds,"cn=HostAdmin,cn=roles,".$dcDNold,$entryRoleHost);
				}
				if(count($roles['ZoneAdmin']) != 0){
					$zoneadmins = $roles['ZoneAdmin'];
					if (count($zoneadmins) > 1){	
						for ($i=0; $i<count($zoneadmins); $i++){
							$entryRoleZone ['member'][$i] = $zoneadmins[$i];
						}
					}else{
						$entryRoleZone ['member'] = $zoneadmins[0];
					}
					#print_r($entryRoleZone); echo "<br>";
					$resultZA = ldap_mod_del($ds,"cn=ZoneAdmin,cn=roles,".$dcDNold,$entryRoleZone);
				}
				
				
				# DNS Einträge mit associatedName ChildDN verschieben
				$zone_entries = get_zone_entries_assocname($domDN,array("dn","relativedomainname"),$childDN);
				#echo "<br>"; print_r($zone_entries); echo "<br>";
				if (count($zone_entries) >= 1){
					foreach ($zone_entries as $ze){
						#print_r($ze['relativedomainname']); echo "<br>";
						#print_r($dcDNnew); echo "<br>";
						move_subtree($ze['dn'], "relativedomainname=".$ze['relativedomainname'].",".$dcDNnew);
						$domsuffix = "uni-freiburg.de"; # neu setzen da es beim new_child_domain schon mal hochgezählt wurde
						$newassocdom = $childdomain.".".$domsuffix;
						$entryZE ['zonename'] = $newassocdom;
						#print_r($entryZE); echo "<br>";
						$resultZE = ldap_mod_replace($ds,"relativedomainname=".$ze['relativedomainname'].",".$dcDNnew,$entryZE);
					}
				}
				# fixme: fehlt noch anpassen der INCLUDE-Direktive in der parentdomain
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
	# Aus nicht AU Domain (aber eventuell Subdomain) in nicht AU Domain
	# Verschieben des dc-Teilbaumes
	if ($oldchilddomain != $domprefix){
		# Verschiebe dc-Baum von dcDNold nach dcDNnew
		# dcDNnew
		$dcDN = "ou=DNS,".$suffix;
		$dc_array = explode('.',$childdomain);
		$dc_array = array_reverse($dc_array);
		$dcDNnew = "";
		foreach ($dc_array as $dc){
			if (check_for_dc($dcDN,$dc)){
				$dcDN = "dc=".$dc.",".$dcDN;			
			}
			else{
				$dcDN = "dc=".$dc.",".$dcDN;
				$dcDNnew .= $dcDN;
				break;
			}
		}
		
		# dcDNold
		$dcDNold = "ou=DNS,".$suffix;
		$dcold_array = explode('.',$oldchilddomain);
		$dcold_array = array_reverse($dcold_array);
		foreach ($dcold_array as $dc){
			$dcDNold = "dc=".$dc.",".$dcDNold;
		}
		
		# dc Baum verschieben 
		if ($dcDNnew != ""){	
			if (move_subtree($dcDNold, $dcDNnew)){
				# rekursives anpassen im neue dc-Baum: 
				# associatedDomain, zoneName, includeFilename, includeOrigin
				$newassocdom = $childdomain.".".$domsuffix;
				if(dive_into_dctree_adapt($dcDNnew,$newassocdom)){
					return 1;
					# fixme: fehlt noch anpassen der INCLUDE-Direktive in der parentdomain
				}
				else{
					return 0;
				}
			}
			else{
				return 0;
			}
		}else{
			echo "Domain existiert schon, bitte anderen Domainnamen w&auml;hlen!";
			return 0;
		}	
	}	
}

function dive_into_dctree_adapt($dcDNnew,$newassocdom){
	
	global $ds, $suffix, $domprefix, $domsuffix, $ldapError;
	print_r($dcDNnew); echo "<br>";
	print_r($newassocdom); echo "<br><br>";
	
	# associatedDomain in dc-Knoten und in allen (mehrere) associatedName-ou-Knoten
	$entryAD['associateddomain'] = $newassocdom;
	print_r($entryAD); echo "<br>";
	$resultAD = ldap_mod_replace($ds,$dcDNnew,$entryAD);
	#$top_dcDN = str_replace("ou=DNS,","",$dcDNnew);
	#print_r($top_dcDN); echo "<br>";
	$assocnames = get_dc_data($dcDNnew,array("associatedname")); # funkt nicht bei uni-freiburg.de
	echo "<br>"; print_r($assocnames); echo "<br>";
	if (count($assocnames['associatedname']) > 1){
		foreach ($assocnames['associatedname'] as $aname){
			print_r($aname); echo "<br>";
		 	$resultAU = ldap_mod_replace($ds,$aname,$entryAD);
		}
	}else{
		$aname = $assocnames['associatedname'];
		print_r($aname); echo "<br>";
		$resultAU = ldap_mod_replace($ds,$aname,$entryAD);
	}
	
	# ZoneName in allen Knoten eine Ebene tiefer
	$zone_entries = get_zone_entries($dcDNnew,array("dn","zonename"));
	echo "<br>"; print_r($zone_entries); echo "<br>";
	foreach ($zone_entries as $ze){
		$entryZE ['zonename'] = $newassocdom;
		print_r($entryZE); echo "<br>";
		$resultZE = ldap_mod_replace($ds,$ze['dn'],$entryZE);
	}
	
	# Zonenamen in Reversezones ... Fehlt noch 
	
	# Rekursion 
	# child dc für Rekursion
	$dcchilds = get_dc_childs($dcDNnew,array("dn","dc"));
	echo "<br>"; print_r($dcchilds); echo "<br>";
	foreach ($dcchilds as $dcc){
		$newassocdom = $dcc['dc'].".".$newassocdom;
		print_r($dcc['dn']); echo " >> "; print_r($newassocdom); echo "<br>";
		dive_into_dctree_adapt($dcc['dn'],$newassocdom);
	}

}


function delete_child_domain($oldchilddomain,$assocdom,$childDN, $domDN, $delmodus){

	global $ds, $suffix, $domprefix, $domsuffix, $ldapError;
	#print_r($domDN); echo "<br>";
	
	# dcDNold
	$dcDNold = "ou=DNS,".$suffix;
	$dcold_array = explode('.',$oldchilddomain);
	$dcold_array = array_reverse($dcold_array);
	foreach ($dcold_array as $dc){
		$dcDNold = "dc=".$dc.",".$dcDNold;
	}
	#print_r($dcDNold); echo "<br>";
	# dcDNnew = domDN
	
	if ( $delmodus == "integrate" ){
	
		# associatedNames zu neuem dc-Knoten hinzufügen 
		$assocnames = get_dc_data($dcDNold,array("associatedname")); # funkt nicht bei uni-freiburg.de
		# echo "<br>"; print_r($assocnames); echo "<br>";
		if (count($assocnames['associatedname']) > 1){
			foreach ($assocnames['associatedname'] as $aname){
				#print_r($aname); echo "<br>";
			 	$entryAN['associatedname'][] = $aname;
			}
		}else{
			$entryAN['associatedname'] = $assocnames['associatedname'];
			$assocname = $assocnames['associatedname'];
			$assocnames ['associatedname'] = array($assocname);
		}
		#print_r($entryAN); echo "<br>";
		$resultAN = ldap_mod_add($ds,$domDN,$entryAN);		
		if($resultAN){
			
			# DNS Einträge verschieben und an neue Domain anpassen
			$zone_entries = get_zone_entries($dcDNold,array("dn","relativedomainname"));
			#echo "<br>"; print_r($zone_entries); echo "<br>";
			if (count($zone_entries) >= 1){
				foreach ($zone_entries as $ze){
					#print_r($ze['relativedomainname']); echo "<br>";
					#print_r($domDN); echo "<br>";
					move_subtree($ze['dn'], "relativedomainname=".$ze['relativedomainname'].",".$domDN);
					$entryZE ['zonename'] = $assocdom;
					print_r($entryZE); echo "<br>";
					$resultZE = ldap_mod_replace($ds,"relativedomainname=".$ze['relativedomainname'].",".$domDN,$entryZE);
				}
			}
			
			# Rollenmembers kopieren für jeden associatedName (ohne Duplikate zu generieren) 
			$newdom_roles = get_roles_dns($domDN);
			#print_r($newdom_roles); echo "<br>";
			if (count($newdom_roles['MainAdmin']) != 0){$newmainadmins = $newdom_roles['MainAdmin'];}else{$newmainadmins = array();}
			if (count($newdom_roles['HostAdmin']) != 0){$newhostadmins = $newdom_roles['HostAdmin'];}else{$newhostadmins = array();}
			if (count($newdom_roles['ZoneAdmin']) != 0){$newzoneadmins = $newdom_roles['ZoneAdmin'];}else{$newzoneadmins = array();}
			#print_r($newmainadmins); echo "<br>";
			#print_r($newhostadmins); echo "<br>";
			#print_r($newzoneadmins); echo "<br><br>";
			foreach ($assocnames['associatedname'] as $aname){
				#echo "_________________________________________<br>";
				#print_r($aname); echo "<br>";
				$roles = get_roles($aname);	
				#print_r($roles); echo "<br>";
				$mainadmins = $roles['MainAdmin'];
				#print_r($mainadmins); echo "<br>";
				#print_r($newmainadmins); echo "<br>";
				$mainadmins = array_diff($mainadmins, $newmainadmins);
				$mainadmins = array_merge($newmainadmins,$mainadmins);
				#print_r($mainadmins); echo "<br>";
				if (count($mainadmins) > 1){
					for ($i=0; $i<count($mainadmins); $i++){
						$entryRoleMain ['member'][$i] = $mainadmins[$i];
					}
				}else{
					$entryRoleMain ['member'] = $mainadmins[0];
				}
				#print_r($entryRoleMain); echo "<br><br>";
				$resultMA = ldap_mod_replace($ds,"cn=MainAdmin,cn=roles,".$domDN,$entryRoleMain);
					
				if(count($roles['HostAdmin']) != 0){
					$hostadmins = $roles['HostAdmin'];
					#print_r($hostadmins); echo "<br>";
					#print_r($newhostadmins); echo "<br>";
					$hostadmins = array_diff($hostadmins, $newhostadmins);
					$hostadmins = array_merge($newhostadmins,$hostadmins);
					#print_r($hostadmins); echo "<br>";
					if (count($hostadmins) > 1){
						for ($i=0; $i<count($hostadmins); $i++){
							$entryRoleHost ['member'][$i] = $hostadmins[$i];
						}
					}else{
						$entryRoleHost ['member'] = $hostadmins[0];
					}
					
					#print_r($entryRoleHost); echo "<br><br>";
					$resultHA = ldap_mod_replace($ds,"cn=HostAdmin,cn=roles,".$domDN,$entryRoleHost);
					
				}	
				if(count($roles['ZoneAdmin']) != 0){
					$zoneadmins = $roles['ZoneAdmin'];
					#print_r($zoneadmins); echo "<br>";
					#print_r($newzoneadmins); echo "<br>";
					$zoneadmins = array_diff($zoneadmins, $newzoneadmins);
					$zoneadmins = array_merge($newzoneadmins,$zoneadmins);
					#print_r($zoneadmins); echo "<br>";
					if (count($zoneadmins) > 1){
						for ($i=0; $i<count($zoneadmins); $i++){
							$entryRoleZone ['member'][$i] = $zoneadmins[$i];
						}
					}else{
						$entryRoleZone ['member'] = $zoneadmins[0];
					}
					#print_r($entryRoleZone); echo "<br><br>";
					$resultZA = ldap_mod_replace($ds,"cn=ZoneAdmin,cn=roles,".$domDN,$entryRoleZone);
						
				}
				
				# associatedDomain anpassen in allen AUs von $assocnames (alt)
				$entryAD ['associateddomain'] = $assocdom;
				#print_r($entryAD); echo "<br>";
				$resultAD = ldap_mod_replace($ds,$aname,$entryAD);
				
				#echo "_________________________________________<br>";
			}
			
			# Falls alter dc-Knoten noch Subdomains, d.h. dc-Teilbäume hat, diese verschieben mit 
			# rekursivem Anpassen aller Einträge
			$dcchilds = get_dc_childs($dcDNold,array("dn","dc"));
			#echo "<br><br>"; print_r($dcchilds); echo "<br>";
			if (count($dcchilds) != 0){
				foreach ($dcchilds as $dcc){
					print_r($dcc['dn']); echo " >> "; print_r("dc=".$dcc['dc'].",".$domDN); echo "<br>";
					if(move_subtree($dcc['dn'],"dc=".$dcc['dc'].",".$domDN)){
						$newdom = $dcc['dc'].".".$assocdom;
						#print_r($newdom); echo "<br><br>";
						dive_into_dctree_adapt("dc=".$dcc['dc'].",".$domDN,$newdom);
					}
				}
			}
			
			# alten dc-Knoten entfernen   
			dive_into_tree_del($dcDNold,"");
			
			# fixme: fehlt noch löschen der INCLUDE-Direktive in der parentdomain
		
		}
		else{
			return 0;
		}
	}

	
	if ( $delmodus == "complete" ){
		# if (dive_into_tree_del($dcDNold,"")){
			$delentry ['objectclass'] = "domainrelatedobject";
			$delentry ['associateddomain'] = $oldchilddomain.".".$domsuffix;
			print_r($delentry); echo "<br>";
		# 	$delresult = ldap_mod_del($ds,$childDN,$delentry);
		#    if ($delresult){
		# 		$mesg = "Domain komplett gel&ouml;scht<br>";
		# 	}else{$mesg = "Fehler! ldap_mod_del<br>";}
		# }else{$mesg = "Fehler! dive_into_tree_del<br>";}
	}
	
	# return $mesg;
}


/*
function modify_childau_domain($childdomain, $oldchilddomain, $childDN){

	global $ds, $suffix, $domsuffix, $ldapError;
	$dcDN = "ou=DNS,".$suffix;
	$dcoldDN = "ou=DNS,".$suffix;
	
	$dc_array = explode('.',$childdomain);
	$dc_array = array_reverse($dc_array);
	$dcold_array = explode('.',$oldchilddomain);
	$dcold_array = array_reverse($dcold_array);
	
	foreach ($dcold_array as $dc){
		$dcoldDN = "dc=".$dc.",".$dcoldDN;
		$aname = get_dc_data($dcoldDN,array("associatedname"));
		if ($aname == $childDN){
			break;
		} 
	}
	#print_r($dcoldDN); echo "<br>";
	#print_r($domsuffix); echo "<br>";
	
	$dcnewDN = "";
	foreach ($dc_array as $dc){
		if (check_for_dc($dc)){
			# echo "dc <b>".$dc."</b> schon vorhanden ... n&auml;chster dc<br>";
			$domsuffix = $dc.".".$domsuffix;
			$dcDN = "dc=".$dc.",".$dcDN;			
		}
		else{
			$dcDN = "dc=".$dc.",".$dcDN;
			$domsuffix = $dc.".".$domsuffix;
			$dcnewDN .= $dcDN;
			break;
		}
	}
	#print_r($dcnewDN); echo "<br>";
	#print_r($domsuffix); echo "<br>";
	
	if ($dcnewDN != ""){	
		if (move_subtree($dcoldDN,$dcnewDN)){
			$entryAD['associateddomain'] = $childdomain.".".$domsuffix;
			$resultAD = ldap_mod_replace($ds,$childDN,$entryAD);
			$resultAD2 = ldap_mod_replace($ds,$dcnewDN,$entryAD);
			if ($resultAD && $resultAD2){return 1;}else{return 0;}
		}
	}else{
		echo "Domain existiert schon, bitte anderen Domainnamen w&auml;hlen!";
	}

}


function same_domain($assocdom, $dcDN, $childDN){

	global $ds, $suffix, $domsuffix, $ldapError;
	
	$entryDC ["associatedname"] = $childDN;
	$resultDC = ldap_mod_add($ds,$dcDN,$entryDC);
	if ($resultDC){
		# HostAdmins übernehmen, welche Admins noch? MainAdmin?
		$roles = get_roles($childDN);
		if(count($roles['HostAdmin']) != 0){
			$hostadmins = $roles['HostAdmin'];
			for ($i=0; $i<count($hostadmins); $i++){
				$entryRoleHost ['member'][$i] = $hostadmins[$i];
			}
			#print_r($entryRoleHost); echo "<br>";
			$resultHA = ldap_mod_add($ds,"cn=HostAdmin,cn=roles,".$dcDN,$entryRoleHost);
		}
		# Domainname zu associatedDomain der ChildAU
		$entryAD['objectclass'] = "domainRelatedObject";
		$entryAD['associateddomain'] = $assocdom;
		$resultAD = ldap_mod_add($ds,$childDN,$entryAD);		
		if($resultAD){return 1;}else{return 0;}
	}
	else{return 0;}
}


function new_childau_domain($childdomain, $childDN){

	global $ds, $suffix, $domsuffix, $ldapError;
	
	# entsprechenden DC Knoten anlegen, sowie Roles (MainAdmin, HostAdmin)
	$dc_array = explode('.',$childdomain);
	$dc_array = array_reverse($dc_array);
	$dcDN = "ou=DNS,".$suffix;
	# $childdomainfull = $childdomain.".".$domsuffix;
	#print_r($dc_array);
	foreach ($dc_array as $dc){
		$resultsum = false;
		if (check_for_dc($dc)){
			echo "dc <b>".$dc."</b> schon vorhanden ... n&auml;chster dc<br>";
			$domsuffix = $dc.".".$domsuffix;
			$dcDN = "dc=".$dc.",".$dcDN;
		}
		else{
			$dcDN = "dc=".$dc.",".$dcDN;
			
			$entryDC ["objectclass"][0] = "dnsdomain";
			$entryDC ["objectclass"][1] = "domainrelatedobject";
			$entryDC ["objectclass"][2] = "top";
			$entryDC ["dc"] = $dc;
			$entryDC ["associatedname"] = $childDN;
			$entryDC ["associateddomain"] = $dc.".".$domsuffix;
			#print_r($entryDC); echo "<br>";
			#print_r($dcDN); echo "<br><br>";
			$resultDC = ldap_add($ds,$dcDN,$entryDC);
			if ($resultDC){
				$domsuffix = $dc.".".$domsuffix;
			
				#print_r($dcDN); echo"<br><br>";
			
				$entryRolesCont ['objectclass'] = "AUContainer";
				$entryRolesCont ['cn'] = "roles";
				#print_r($entryRolesCont); echo "<br><br>";
				$resultRC = ldap_add($ds,"cn=roles,".$dcDN,$entryRolesCont);
				if ($resultRC){ 
					$roles = get_roles($childDN);
					print_r($roles); echo "<br><br>";
					$mainadmins = $roles['MainAdmin'];
					$entryRoleMain ['objectclass'] = "groupOfNames";
					$entryRoleMain ['cn'] = "MainAdmin";
					for ($i=0; $i<count($mainadmins); $i++){
						$entryRoleMain ['member'][$i] = $mainadmins[$i];
					}
					#print_r($entryRoleMain); echo "<br>";
					$resultMA = ldap_add($ds,"cn=MainAdmin,cn=roles,".$dcDN,$entryRoleMain);
					
					if(count($roles['HostAdmin']) != 0){
						$hostadmins = $roles['HostAdmin'];
						$entryRoleHost ['objectclass'] = "groupOfNames";
						$entryRoleHost ['cn'] = "HostAdmin";
						for ($i=0; $i<count($hostadmins); $i++){
							$entryRoleHost ['member'][$i] = $hostadmins[$i];
						}
						#print_r($entryRoleHost); echo "<br>";
						$resultHA = ldap_add($ds,"cn=HostAdmin,cn=roles,".$dcDN,$entryRoleHost);
					}
					if ($resultMA){$resultsum = true;}
				}
			}
			break;	# damit dc-Zuwachs immer nur um eine neue Ebene moeglich
		}	
	}
	# Domainname zu associatedDomain der ChildAU
	if ($resultsum == true){
		$entryAD['objectclass'] = "domainRelatedObject";
		$entryAD['associateddomain'] = $domsuffix;
		$resultAD = ldap_mod_add($ds,$childDN,$entryAD);
	}
	if($resultAD){return 1;}
	else{return 0;}
	
}



function delete_childau_domain($oldchilddomain,$childDN,$delmodus){

	global $ds, $suffix, $domsuffix, $ldapError;
	
	$dcold_array = explode('.',$oldchilddomain);
	$dcold_array = array_reverse($dcold_array);
	$dcDN = "ou=DNS,".$suffix;
	
	foreach ($dcold_array as $dc){
		$dcDN = "dc=".$dc.",".$dcDN;
		$aname = get_dc_data($dcDN,array("associatedname"));
		$domsuffix = $dc.".".$domsuffix;
		
		if ($aname == $childDN){
			break;
		} 
	}
	#print_r($dcDN); echo "<br>";
	#print_r($domsuffix); echo "<br>";
	
	if ( $delmodus == "complete" ){
		if (dive_into_tree_del($dcDN,"")){
			$delentry ['objectclass'] = "domainrelatedobject";
			$delentry ['associateddomain'] = $domsuffix;
			#print_r($delentry); echo "<br>";
			$delresult = ldap_mod_del($ds,$childDN,$delentry);
		   if ($delresult){
				$mesg = "Domain komplett gel&ouml;scht<br>";
			}else{$mesg = "Fehler! ldap_mod_del<br>";}
		}else{$mesg = "Fehler! dive_into_tree_del<br>";}
	}
	
	if ( $delmodus == "integrate"){
	$mesg = "DNS Integration, noch nicht fertiggestellt";
	}
	
	return $mesg;
}
*/




###############################################################################
# Funktionen für das Rollen Management
#


function new_role_member($userDN,$role,$auDN,$domDN){

	global $ds, $suffix, $ldapError;
	
	$entry['member'] = $userDN;
	
	if ($domDN != ""){
		switch ($role){
		case 'MainAdmin':
			$roleDN1 = "cn=".$role.",cn=roles,".$auDN;
			$roleDN2 = "cn=".$role.",cn=roles,".$domDN;
			$results1 = ldap_mod_add($ds,$roleDN1,$entry);
			$results2 = ldap_mod_add($ds,$roleDN2,$entry);
			if ($results1 && $results2){ 
				return 1;
   		}else{ 
			   return 0;
			}	
			break;
		case 'HostAdmin':
			$roleDN1 = "cn=".$role.",cn=roles,".$auDN;
			$roleDN2 = "cn=".$role.",cn=roles,".$domDN;
			$results1 = ldap_mod_add($ds,$roleDN1,$entry);
			$results2 = ldap_mod_add($ds,$roleDN2,$entry);
			if ($results1 && $results2){ 
				return 1;
   		}else{ 
			   return 0;
			}	
			break;
		case 'DhcpAdmin':
			$roleDN = "cn=".$role.",cn=roles,".$auDN;
			$results = ldap_mod_add($ds,$roleDN,$entry);
			if ($results){ 
				return 1;
   		}else{ 
			   return 0;
			}	
			break;
		case 'ZoneAdmin':
			$roleDN1 = "cn=".$role.",cn=roles,".$auDN;
			$roleDN2 = "cn=".$role.",cn=roles,".$domDN;
			$results1 = ldap_mod_add($ds,$roleDN1,$entry);
			$results2 = ldap_mod_add($ds,$roleDN2,$entry);
			if ($results1 && $results2){ 
				return 1;
   		}else{ 
			   return 0;
			}	
			break;
		}
	}else{
		switch ($role){
		case 'MainAdmin':
			$roleDN = "cn=".$role.",cn=roles,".$auDN;
			$results = ldap_mod_add($ds,$roleDN,$entry);
			if ($results){ 
				return 1;
   		}else{ 
			   return 0;
			}	
			break;
		case 'HostAdmin':
			$roleDN = "cn=".$role.",cn=roles,".$auDN;
			$results = ldap_mod_add($ds,$roleDN,$entry);
			if ($results){ 
				return 1;
   		}else{ 
			   return 0;
			}	
			break;
		case 'DhcpAdmin':
			$roleDN = "cn=".$role.",cn=roles,".$auDN;
			$results = ldap_mod_add($ds,$roleDN,$entry);
			if ($results){ 
				return 1;
   		}else{ 
			   return 0;
			}	
			break;
		case 'ZoneAdmin':
			$roleDN = "cn=".$role.",cn=roles,".$auDN;
			$results = ldap_mod_add($ds,$roleDN,$entry);
			if ($results){ 
				return 1;
   		}else{ 
			   return 0;
			}	
			break;
		}
	}	 	 
}


function delete_role_member($userDN,$role,$auDN,$domDN){

	global $ds, $suffix, $ldapError;
	
	$entry['member'] = $userDN;
	
	if ($domDN != ""){
		switch ($role){
		case 'MainAdmin':
			$roleDN1 = "cn=".$role.",cn=roles,".$auDN;
			$roleDN2 = "cn=".$role.",cn=roles,".$domDN;
			$results1 = ldap_mod_del($ds,$roleDN1,$entry);
			$results2 = ldap_mod_del($ds,$roleDN2,$entry);
			if ($results1 && $results2){ 
				return 1;
   		}else{ 
			   return 0;
			}	
			break;
		case 'HostAdmin':
			$roleDN1 = "cn=".$role.",cn=roles,".$auDN;
			$roleDN2 = "cn=".$role.",cn=roles,".$domDN;
			$results1 = ldap_mod_del($ds,$roleDN1,$entry);
			$results2 = ldap_mod_del($ds,$roleDN2,$entry);
			if ($results1 && $results2){ 
				return 1;
   		}else{ 
			   return 0;
			}	
			break;
		case 'DhcpAdmin':
			$roleDN = "cn=".$role.",cn=roles,".$auDN;
			$results = ldap_mod_del($ds,$roleDN,$entry);
			if ($results){ 
				return 1;
   		}else{ 
			   return 0;
			}	
			break;
		case 'ZoneAdmin':
			$roleDN1 = "cn=".$role.",cn=roles,".$auDN;
			$roleDN2 = "cn=".$role.",cn=roles,".$domDN;
			$results1 = ldap_mod_del($ds,$roleDN1,$entry);
			$results2 = ldap_mod_del($ds,$roleDN2,$entry);
			if ($results1 && $results2){ 
				return 1;
   		}else{ 
			   return 0;
			}	
			break;
		}
	}else{
		switch ($role){
		case 'MainAdmin':
			$roleDN = "cn=".$role.",cn=roles,".$auDN;
			$results = ldap_mod_del($ds,$roleDN,$entry);
			if ($results){ 
				return 1;
   		}else{ 
			   return 0;
			}	
			break;
		case 'HostAdmin':
			$roleDN = "cn=".$role.",cn=roles,".$auDN;
			$results = ldap_mod_del($ds,$roleDN,$entry);
			if ($results){ 
				return 1;
   		}else{ 
			   return 0;
			}	
			break;
		case 'DhcpAdmin':
			$roleDN = "cn=".$role.",cn=roles,".$auDN;
			$results = ldap_mod_del($ds,$roleDN,$entry);
			if ($results){ 
				return 1;
   		}else{ 
			   return 0;
			}	
			break;
		case 'ZoneAdmin':
			$roleDN = "cn=".$role.",cn=roles,".$auDN;
			$results = ldap_mod_del($ds,$roleDN,$entry);
			if ($results){ 
				return 1;
   		}else{ 
			   return 0;
			}	
			break;
		}
	}	 
}


function get_role_members($roleDN)
{
	global $ds, $suffix, $ldapError;

	if(!($result = uniLdapSearch($ds, $roleDN, "objectclass=*", array("member"), "", "one", 0, 0))) {
      # redirect(5, "", $ldapError, FALSE);
      echo "search problem";
      die;
   } else {
   	$members_array = array();
   	$result = ldapArraySauber($result);
		foreach ($result as $item){
			if (count($item['member']) > 1){
	   		$members_array = $item['member'];
   		}
   		else{
   			$members_array[] = $item['member'];
   		}   	
   	}
   }
   return $members_array;
}


?>