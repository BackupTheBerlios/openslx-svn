<?php

/**  
* rbs_management_functions.php - Remote Boot Services Management Funktions-Bibliothek
* Diese Bibliothek enthält alle Funktionen für die Verwaltung von RBS Diensten, 
* PXE Konfigurationsdateien ihren Menüeinträgen und ihren Genersichen Bootmenüeinträgen
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


#######################################################################
# Funktionen zur Verwaltung von RBS Diensten
# 

function check_tftpip_in_mipb($tftpserverip) {

		global $ds, $suffix, $auDN, $rootAU, $ldapError;
// 		echo " $auDN == $rootAU <br><br>";
		if ( $auDN == $rootAU ) {
			return 1;
		}
		else {
		
		$mipb_array = get_maxipblocks_au($auDN);
		if ( $mipb_array[0] != "" ) {
			$new_tftpip = $tftpserverip.'_'.$tftpserverip;
			for ($i=0; $i < count($mipb_array); $i++){
				if ( split_iprange($new_tftpip,$mipb_array[$i]) != 0 ){
					return 1;
					break;
				}
			}
		}
		
		}
		
		return 0;
}

#
# Neues RBS Dienst-Objekt anlegen 
#
function add_rbs($rbsDN,$rbscn,$rbsoffer,$atts){
	
	global $ds, $suffix, $auDN, $ldapError;
	
	$rbsentry ['objectclass'][0] = "RBService";
	$rbsentry ['objectclass'][1] = "top";
	$rbsentry ['cn'] = $rbscn;
	$rbsentry ['rbsofferdn'] = $rbsoffer;
	if (count($atts) != 0){
		foreach (array_keys($atts) as $key){
			if ($atts[$key] != ""){
				$rbsentry[$key] = $atts[$key];
			}
		}
	}
	
	print_r($rbsentry); echo "<br>";
// 	print_r($rbsDN); echo "<br>";
	
	if (ldap_add($ds,$rbsDN,$rbsentry)){
		return 1;
	}
	else{
		return 0;
	}
}

function old_add_rbs($rbsDN,$rbscn,$rbsoffer,$server,$atts){
	
	global $ds, $suffix, $auDN, $ldapError;
	
	$rbsentry ['objectclass'][0] = "RBService";
	$rbsentry ['objectclass'][1] = "top";
	$rbsentry ['cn'] = $rbscn;
	$rbsentry ['rbsofferdn'] = $rbsoffer;
	if (count($atts) != 0){
		foreach (array_keys($atts) as $key){
			if ($atts[$key] != ""){
				$rbsentry[$key] = $atts[$key];
			}
		}
	}
	if (count($server) != 0){
		if ($server['tftp'] != ""){$rbsentry ['tftpserverip'] = $server['tftp'];}
		if ($server['nfs'] != ""){$rbsentry ['nfsserverip'] = $server['nfs'];}
		if ($server['nbd'] != ""){$rbsentry ['nbdserverip'] = $server['nbd'];}
	}
	# print_r($rbsentry); echo "<br>";
	print_r($rbsDN); echo "<br>";
	
	# Standard Fallback Menü anlegen
	$pxecn = "PXE_Fallback-No-Config";
	$pxeDN = "cn=".$pxecn.",".$rbsDN;
	$filename = array("fallback-nopxe");
	$ldapuri = LDAP_HOST."/dn=cn=computers,".$auDN; # wirklich nötig??
	$mecn = "Fallback-Text";
	$meDN = "cn=".$mecn.",".$pxeDN;
	$meattribs = array("label" => "Keine PXE Boot-Konfiguration fuer die aktuelle Zeit definiert",
							"kernel" => "menu.c32",
							"submenulink" => "fallback-nopxe");
	
	if (ldap_add($ds,$rbsDN,$rbsentry)){
		if (add_pxe($pxeDN,$pxecn,$rbsDN,"",array(),$filename,$ldapuri)){
			if (add_me($meDN,$mecn,"","01",$meattribs,$pxeDN)){
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
	else{
		return 0;
	}
}

#
# "RBS-Angebote" im Verzeichnis suchen, die die AU ($auDN) nutzen darf,
# Suche nach passenden RBS-Offer-DNs
#
function get_rbsoffers($auDN){

	global $ds, $suffix, $auDN, $ldapError;
	
	$attribs = array("dn","rbsofferdn");
	if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(objectclass=RBService)", $attribs, "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	else{
		$result = ldapArraySauber($result);
		#print_r($result);echo "<br><br>";
		
		$rbs_offers = array();
		foreach ($result as $rbs) {
			if ( count($rbs['rbsofferdn']) > 1 ) {     # bei multi-value rbsofferdn
				foreach ($rbs['rbsofferdn'] as $rbs_offer_dn) {
					#print_r(strpos($auDN, $rbs['rbsofferdn']));echo "<br>";
					if ( strpos($auDN, $rbs_offer_dn) !== false ) {
						$rbs_offers [] = $rbs['dn'];
					}
				}
			}
			else {
				#print_r(strpos($auDN, $rbs['rbsofferdn']));echo "<br>";
				if ( strpos($auDN, $rbs['rbsofferdn']) !== false ) {
					$rbs_offers [] = $rbs['dn'];
				}
			}
		}
	}
	#print_r($rbs_offers);echo "<br><br>";
	return $rbs_offers;
}

function get_rbsoffers_other($au_dn){

	global $ds, $suffix, $ldapError;
	
	$attribs = array("dn","rbsofferdn");
	if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(objectclass=RBService)", $attribs, "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	else{
		$result = ldapArraySauber($result);
		#print_r($result);echo "<br><br>";
		
		$rbs_offers = array();
		foreach ($result as $rbs){
			#print_r(strpos($au_dn, $rbs['rbsofferdn']));echo "<br>";
			if ( strpos($au_dn, $rbs['rbsofferdn']) !== false )
				$rbs_offers [] = $rbs['dn'];
			}
		}
		#print_r($rbs_offers);echo "<br><br>";
		return $rbs_offers;
}


#
# Beim Löschen von RBS-Objekten muss dafür gesorgt werden dass keine PXEs mehr auf 
# diese zeigen, Ref. Abhängigkeiten 
# 
function clean_up_del_rbs($rbsDN){

	global $ds, $suffix, $auDN, $ldapError;
	
	$attribs = array("dn");
	if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(&(objectclass=PXEConfig)(rbservicedn=$rbsDN))", $attribs, "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	$result = ldapArraySauber($result);
	#print_r($result); echo "<br><br>";
	$delentry ['rbservicedn'] = $rbsDN;
	foreach ($result as $item){
		#print_r($item['dn']); echo "<br>";
		ldap_mod_del($ds, $item['dn'], $delentry); 
	}
	
	if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(&(objectclass=Host)(hlprbservice=$rbsDN))", $attribs, "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	$result = ldapArraySauber($result);
	#print_r($result); echo "<br><br>";
	$delentry2 ['hlprbservice'] = $rbsDN;
	foreach ($result as $item){
		#print_r($item['dn']); echo "<br>";
		ldap_mod_del($ds, $item['dn'], $delentry2); 
	}
	
}

#
# beim ändern des CN (DN) des RBS muss dieses in allen referenzierenden PXEConfig-Objekten
# nachvollzogen werden, Ref. Abhängigkeiten
#
function adjust_rbs_dn($newrbsDN, $rbsDN){

	global $ds, $suffix, $auDN, $ldapError;
	
	if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(&(objectclass=PXEConfig)(rbservicedn=$rbsDN))", array("dn"), "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	$result = ldapArraySauber($result);
	$modentry ['rbservicedn'] = $newrbsDN;
	foreach ($result as $item){
		ldap_mod_replace($ds, $item['dn'], $modentry);
	}
	
   if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(&(objectclass=Host)(hlprbservice=$rbsDN))", array("dn"), "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	$result = ldapArraySauber($result);
	$modentry2 ['hlprbservice'] = $newrbsDN;
	foreach ($result as $item){
		ldap_mod_replace($ds, $item['dn'], $modentry2);
	}
}

function rbs_adjust_host($hostDN, $rbs){
   
   global $ds, $suffix, $ldapError;
   
   $modentry ['rbservicedn'] = $rbs;
   
   $pxearray = get_pxeconfigs($hostDN,array("dn"));
   if ( count($pxearray) != 0 ){
      foreach ( $pxearray as $item ){
         if ($result = ldap_mod_replace($ds,$item['dn'],$modentry)){
            return 1;
         }else{
            return 0;
         }
      }
   }
}

# Bei Änderung der TFTP Server IP eines RBS-Objekts entsprechend DHCP Option next-server
# in den Hostobjekten anpassen und DHCP modify time in den AUs aktualisieren
function adjust_dhcpnextserver($tftpIP, $rbsDN){

   global $ds, $suffix, $ldapError;
   
   if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(&(|(objectclass=Host)(objectclass=dhcpPool))(hlprbservice=$rbsDN))", array("dn"), "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	$result = ldapArraySauber($result);
	$host_au = array();
	if ($tftpIP == ""){
	   $deltftpentry ['dhcpoptnext-server'] = array();
      foreach ($result as $item){
   		ldap_mod_del($ds, $item['dn'], array());
	   	$expdn = array_slice(ldap_explode_dn($item['dn'], 0), 3);
	   	$host_au [] = implode(",", $expdn);
	   }  
	}else{
	   $modtftpentry ['dhcpoptnext-server'] = $tftpIP;
	   foreach ($result as $item){
   		ldap_mod_replace($ds, $item['dn'], $modtftpentry);
	   	$expdn = array_slice(ldap_explode_dn($item['dn'], 0), 3);
	   	$host_au [] = implode(",", $expdn);
	   }
	}
	if ( count($host_au) != 0 ){
	   $host_au = array_unique($host_au);
	   foreach ($hostau as $au) {
	   	update_dhcpmtime($au);
	   }
	}
}

# Bei Änderung des PXE Init Boot File eines RBS-Objekts entsprechend DHCP Option Filename
# in den Hostobjekten anpassen 
function adjust_dhcpfilename($initbootfile, $rbsDN, $type){

   global $ds, $suffix, $ldapError;
   
   if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(&(objectclass=Host)(hlprbservice=$rbsDN))", array("dn"), "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	$result = ldapArraySauber($result);
	$host_au = array();
	if ($type == "add"){
   	$modentry ['dhcpoptfilename'] = $initbootfile;
   	foreach ($result as $item){
   		ldap_mod_add($ds, $item['dn'], $modentry);
   	}
   }
   elseif ($type == "delete"){
      $modentry ['dhcpoptfilename'] = array();
   	foreach ($result as $item){
   		ldap_mod_del($ds, $item['dn'], $modentry);
   	}
   }
   elseif ($type == "replace"){
      $modentry ['dhcpoptfilename'] = $initbootfile;
   	foreach ($result as $item){
   		ldap_mod_replace($ds, $item['dn'], $modentry);   		
		   $expdn = array_slice(ldap_explode_dn($item['dn'], 0), 3);
		   $host_au [] = implode(",", $expdn);
   	}
   }
   if ( count($host_au) != 0 ){
	   $host_au = array_unique($host_au);
	   foreach ($host_au as $au) { 
	   	update_dhcpmtime($au);
	   }
	}
}

# IP Adresse eines Host ändern -> RBS TFTP Server IP anpassen (inkl. dhcpNext-server)
function adjust_hostip_tftpserverip($oldip,$newip){

   global $ds, $suffix, $ldapError, $auDN;

   if(!($result = uniLdapSearch($ds, "cn=rbs,".$auDN, "(&(objectclass=RBService)(tftpserverip=$oldip))", array("dn","tftpserverip"), "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	$result = ldapArraySauber($result);
	if (count($result) != 0){
   	foreach ($result as $item){
	      if ($newip == ""){
	         $delentry ['tftpserverip'] = array();
	         ldap_mod_del($ds, $item['dn'], $delentry);
	         adjust_dhcpnextserver("", $item['dn']);
	      }else{
	         $modentry ['tftpserverip'] = $newip;
	         ldap_mod_replace($ds, $item['dn'], $modentry);
	         adjust_dhcpnextserver($newip, $item['dn']);
	      }
	   }  
	}
}

# 
# Sucht den Hostname zu einer IP im Rechnerteilbaum der AU
# Verwaltung der am RBS beteiligten Server
# 
function get_hostname_from_ip($ip){
	
	global $ds, $suffix, $ldapError, $auDN;
	
	$ipp = array($ip,$ip);
	$ipaddress = implode('_',$ipp); 
	if(!($result = uniLdapSearch($ds, "cn=computers,".$auDN, "(&(objectclass=Host)(ipaddress=$ipaddress))", array("dn","hostname"), "", "list", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	$result = ldapArraySauber($result);
	#print_r($result);
	$host ['hostname'] = $result[0]['hostname'];
	$host ['dn'] = $result[0]['dn'];
	return $host;
}


###############################################################################
# Funktionen zur Verwaltung von PXE Bootmenüs 

#
# Überprüft, ob sich die angegebene Timerange auf einer der 4 Spezifikationsstufen mit anderen
# Timeranges des Objkets überschneidet
#
function check_timerange_pxe($pxeday,$pxebeg,$pxeend,$nodeDN,$excepttimerange){

	global $ds, $suffix, $auDN, $ldapError;
	
	$brothers = get_pxeconfigs($nodeDN,array("timerange"));
	# keine Überschneidungen pro Spez.Ebene zulassen
	# print_r($brothers); echo "<br><br>";
	if (count($brothers) != 0){
		
		$intersect = 0;
		foreach ($brothers as $item){
			
			# Fall das Brother mehrere TimeRanges hat
			if (count($item['timerange']) > 1){
				foreach ($item['timerange'] as $tr){
					
					if($tr != $excepttimerange){
						$exptime = explode('_',$tr);
						$bpxeday = $exptime[0];
						$bpxebeg = $exptime[1];
						$bpxeend = $exptime[2];
						#echo "pxeday:"; print_r($pxeday); echo "<br>";
						#echo "bpxeday:"; print_r($bpxeday); echo "<br>";
						#echo "pxebeg:"; print_r($pxebeg); echo "<br>";
						#echo "bpxebeg:"; print_r($bpxebeg); echo "<br>";
						#echo "pxeend:"; print_r($pxeend); echo "<br>";
						#echo "bpxeend:"; print_r($bpxeend); echo "<br>";
						
						if ($pxeday == $bpxeday){
							if ( $pxebeg > $bpxeend || $pxeend < $bpxebeg ){
								# keine Überschneidung in der Uhrzeit
							}else{
								# Uhrzeit Überschneidung
								$intersect = 1;
								$intersecttr = $bpxeday."_".$bpxebeg."_".$bpxeend;
								break;
							}
						}
					}
					
				}
			}
			# Fall das Brother nur eine TimeRange hat
			elseif (count($item['timerange']) == 1){
			
				if($item['timerange'] != $excepttimerange){
					$exptime = explode('_',$item['timerange']);
					$bpxeday = $exptime[0];
					$bpxebeg = $exptime[1];
					$bpxeend = $exptime[2];
					#echo "pxeday:"; print_r($pxeday); echo "<br>";
					#echo "bpxeday:"; print_r($bpxeday); echo "<br>";
					#echo "pxebeg:"; print_r($pxebeg); echo "<br>";
					#echo "bpxebeg:"; print_r($bpxebeg); echo "<br>";
					#echo "pxeend:"; print_r($pxeend); echo "<br>";
					#echo "bmcend:"; print_r($bpxeend); echo "<br>";
					
					if ($pxeday == $bpxeday){
						if ( $pxebeg > $bpxeend || $pxeend < $bpxebeg ){
							# keine Überschneidung in der Uhrzeit
						}else{
							# Uhrzeit Überschneidung
							$intersect = 1;
							$intersecttr = $bpxeday."_".$bpxebeg."_".$bpxeend;
							break;
						}
					}
				}
			}
		}
		#echo "intersect: "; print_r($intersect); echo "<br>";
		if ($intersect == 1){
			echo "<b>[".$pxeday."_".$pxebeg."_".$pxeend."]</b> &uuml;berschneidet sich mit der 
					bereits existierende <b>Time Range [".$intersecttr."]</b> !<br><br>";
			return 0;
		}else{
			return 1;
		}
	}else{
		return 1;
	}
}


#
# Neues PXE Bootmenü anlegen 
#
function add_pxe($pxeDN,$pxecn,$rbsDN,$pxetimerange,$pxeattribs,$filenames,$conffile){
	
	global $ds, $suffix, $auDN, $ldapError;
	
	$pxeentry ['objectclass'][0] = "PXEConfig";
	$pxeentry ['objectclass'][1] = "top";
	$pxeentry ['cn'] = $pxecn;
	$pxeentry ['rbservicedn'] = $rbsDN;
	#$pxeentry ['ldapuri'] = $ldapuri;
	if ($conffile != ""){$pxeentry ['fileuri'] = $conffile;}
	if (count($filenames) > 1 ){
		for ($i=0; $i<count($filenames); $i++){
			$pxeentry ['filename'][$i] = $filenames[$i];
		}
	}
	if (count($filenames) == 1){
		$pxeentry ['filename'] = $filenames[0];
	}
	if ($pxetimerange != ""){$pxeentry ['timerange'] = $pxetimerange;}
	if (count($pxeattribs) != 0){
		foreach (array_keys($pxeattribs) as $key){
			if ($pxeattribs[$key] != ""){
				$pxeentry[$key] = $pxeattribs[$key];
			}
		}
	}
	print_r($pxeentry); echo "<br>";
	print_r($pxeDN); echo "<br>";
	if (ldap_add($ds,$pxeDN,$pxeentry)){
		return 1;
	}
	else{
		return 0;
	}
}


#
# PXE CN (DN) ändern, Teilbaum verschieben
#
function modify_pxe_dn($pxeDN, $newpxeDN){

	global $ds, $suffix, $ldapError;
	
	if (move_subtree($pxeDN,$newpxeDN)){
		return 1;
	}else{
		return 0;
	}
}


#
# Timerange eines PXEConfig-Objekts ändern
#
function change_pxe_timerange($pxeDN,$newpxeDN,$pxetimerange){
	
	global $ds, $suffix, $auDN, $ldapError;
	
	# move tree
	if (move_subtree($pxeDN,$newpxeDN)){
		# timerange ändern
		$entrypxe ['timerange'] = $pxetimerange;
		if (ldap_mod_replace($ds,$newpxeDN,$entrypxe)){
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

#
# nach dem Löschen von PXEConfig Menueinträgen müssen Menüpositionen in der PXEConfig 
# angepasst werden (Lücken schließen) 
# 
function cleanup_menupositions($pxeDN){
	
	global $ds, $suffix, $auDN, $ldapError;
	
	$me = get_menuentries($pxeDN,array("dn","menuposition"));
	if (count($me) != 0){
		foreach ($me as $item){	
			$pos = $item['menuposition'];
			$pos = preg_replace ( '/0([0-9])/', '$1', $pos);
			$menpos[$pos] = $item['dn'];
			ksort($menpos);
		}
		$p = 1;
		foreach ($menpos as $item){
			if (strlen($p) == 1){
				$p = "0".$p;
			}
			$entry ['menuposition'] = $p;
			ldap_mod_replace($ds,$item,$entry);
			$p++; 
		}	
	}
}

#
# Hilfsfunktion zur Verarbeitung von Menüpositionen in PXEConfigs
# 
function increment_menupositions($pxeDN,$menpos){
	
	global $ds, $suffix, $auDN, $ldapError;
	
	if (strlen($menpos) == 1){
		$menpos = "0".$menpos;
	}
	$meDN = get_dn_menuposition($pxeDN,$menpos);
	if ($meDN != ""){
		# zur Berechnung erst führende Nullen weg
		$menpos = preg_replace ( '/0([0-9])/', '$1', $menpos);
		$newpos = $menpos+1;
		increment_menupositions($pxeDN,$newpos);
		# zum Eintragen führenden Nullen wieder dazu
		if (strlen($newpos) == 1){
			$newpos = "0".$newpos;
		}
		$entry ['menuposition'] = $newpos;
		ldap_mod_replace($ds,$meDN,$entry);
	}
}

#
# Neuen Menüeintrag anlegen 
#
function add_me($meDN,$mecn,$gbmDN,$menpos,$meattribs,$pxeDN){
	
	global $ds, $suffix, $auDN, $ldapError;
	
	$mentry ['objectclass'][0] = "MenuEntry";
	$mentry ['objectclass'][1] = "top";
	$mentry ['cn'] = $mecn;
	if($gbmDN != ""){$mentry ['genericmenuentrydn'] = $gbmDN;}
	$mentry ['menuposition'] = $menpos;
	if (count($meattribs) != 0){
		foreach (array_keys($meattribs) as $key){
			if ($meattribs[$key] != ""){
				$mentry[$key] = $meattribs[$key];
			}
		}
	}
	print_r($mentry); echo "<br>";
	print_r($meDN); echo "<br>";
	increment_menupositions($pxeDN,$menpos); # andere jeweils um 1 erhöhen
	if (ldap_add($ds,$meDN,$mentry)){
		return 1;
	}
	else{
		return 0;
	}
}


#
# Menu Entry CN (DN) ändern
#
function modify_me_dn($meDN, $newmeDN){

	global $ds, $suffix, $ldapError;
	
	if (move_subtree($meDN,$newmeDN)){
		return 1;
	}else{
		return 0;
	}
}



#####################################################################
# Verwaltung von GBM
#

function add_gbm($gbmDN,$gbmcn,$attribs){

	global $ds, $suffix, $auDN, $ldapError;
	
	$entry ['objectclass'][0] = "MenuEntry";
	$entry ['objectclass'][1] = "top";
	$entry ['cn'] = $gbmcn;
	if (count($attribs) != 0){
		foreach (array_keys($attribs) as $key){
			if ($attribs[$key] != ""){
				$entry[$key] = $attribs[$key];
			}
		}
	}
	print_r($entry); echo "<br>";
	print_r($gbmDN); echo "<br>";
	if (ldap_add($ds,$gbmDN,$entry)){
		return 1;
	}
	else{
		return 0;
	}
}


# 
# beim löschen von GBMs muss dafür gesorgt werden, dass keine MEs mehr auf diese zeigen, 
# Ref.Abhängigkeiten  (sonst gibts Fehler beim PXE-Perlskript und die Nutzer wissen nicht dass ihr PXE Menü nicht
# mehr funktioniert, so kann man durch Fehlen des gbmDN wissen das es kein GBM mehr zu diesem ME gibt
#
function clean_up_del_gbm($gbmDN){

	global $ds, $suffix, $auDN, $ldapError;
	
	$attribs = array("dn","genericmenuentrydn");
	if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(&(objectclass=MenuEntry)(genericmenuentrydn=$gbmDN))", $attribs, "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	$result = ldapArraySauber($result);
	#print_r($result); echo "<br><br>";
	$delentry ['genericmenuentrydn'] = $gbmDN;
	foreach ($result as $item){
		#print_r($item['dn']); echo "<br>";
		ldap_mod_del($ds, $item['dn'], $delentry); 
	}
	
}


#
# beim ändern des CN (DN) des GBM, Meüeinträge anpassen, Ref. Abhängigkeiten
#
function adjust_gbm_dn($newgbmDN, $gbmDN){

	global $ds, $suffix, $auDN, $ldapError;
	
	if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(&(objectclass=MenuEntry)(genericmenuentrydn=$gbmDN))", array("dn"), "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	$result = ldapArraySauber($result);
	$modentry ['genericmenuentrydn'] = $newgbmDN;
	foreach ($result as $item){
		ldap_mod_replace($ds, $item['dn'], $modentry);
	}
}



function alternative_rbservices($rbsDN){

   global $ds, $suffix, $auDN, $ldapError;
   
   $alt_rbs = array();
   
   $rbsarray = get_rbsoffers($auDN);
   # print_r($rbsarray); echo "<br>";
   if (count($rbsarray) != 0){
      for ($i=0; $i < count($rbsarray); $i++){
         if ($rbsarray[$i] != $rbsDN){
		      $exp = ldap_explode_dn ( $rbsarray[$i], 1 );
   	      $alt = array ("dn" => $rbsarray[$i], "cn" => $exp[0], "au" => " &nbsp;&nbsp;[ Abt.: ".$exp[2]." ]");
   	      $alt_rbs[] = $alt; 
         }
      }
   }
   
   return $alt_rbs;
}

?>