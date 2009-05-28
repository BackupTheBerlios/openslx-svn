<?php

/**  
* dhcp_management_functions.php - DHCP Management Funktions-Bibliothek
* Diese Bibliothek enthält alle Funktionen für die Verwaltung des DHCP Dienstes
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

# wenn DHCP Objekte geändert werden DHCP modify time der AU aktualisieren, und auch der AUs 
# referenzierter Objekte (Subnetz, RBS Dhcp Optionen) aktualisieren 
function update_dhcpmtime($audn){

   global $ds, $ldapError, $dhcpman_pwd;
   
   $entry ['dhcpmtime'] = time();
	$mesg = "";
	if ( $audn ) {
		# Bind als DHCP Manager
		$dhcp_uid = "dhcpmanager";
		if (!($dhcp_ds = uniLdapConnect($dhcp_uid,$dhcpman_pwd))){
			echo "Konnte nicht als <b>DHCP-Manager</b> mit LDAP Server verbinden";
			die;
		}else{
			#echo "DHCP BIND erfolgreich";
			$results = ldap_mod_replace($dhcp_ds,$audn,$entry);
			if ($results){
			echo "<br><b>DHCP Config erfolgreich aktualisiert<br>&Auml;nderung ist innerhalb der n&auml;chsten 10 min aktiv!<br><br></b>";
			$mesg .= "<br><b>Neue DHCP Config innerhalb der n&auml;chsten 10 min aktualisiert!<br><br></b>";
// 				return 1;
		   }else{
		      echo "<br>Fehler beim Aktualisieren der <b>dhcpMTime</b> in AU $audn!<br>" ;
			  $mesg .= "<br>Fehler beim Aktualisieren der <b>dhcpMTime</b> in AU $audn!<br>";
		   }
	   ldap_unbind($dhcp_ds);
	   }
   }else{
   	echo "Fehler: AU DN ist leer!<br>";
	$mesg .= "Fehler: AU DN ist leer!<br>";
   }
   return $mesg;
}

function update_dhcpmtime_old($au_array){

   global $ds, $auDN, $ldapError, $dhcpman_pwd;
   
   $entry ['dhcpmtime'] = time();
   
   # eigene AU
   $results = ldap_mod_replace($ds,$auDN,$entry);
	if ($results){
      echo "<br><b>dhcpMTime</b> erfolgreich in AU ".$auDN." aktualisiert!<br>" ;
      #return 1;
   }else{
      echo "<br>Fehler beim Aktualisieren der <b>dhcpMTime</b> in $auDN!<br>" ;
   }
   
   # andere AUs
	if ( count($au_array) != 0 ) {
		$au_array = array_unique($au_array);
	   # Bind als DHCP Manager
	   $dhcp_uid = "dhcpmanager";
	   if (!($dhcp_ds = uniLdapConnect($dhcp_uid,$dhcpman_pwd))){
			echo "Konnte nicht als <b>DHCP-Manager</b> mit LDAP Server verbinden";
			die;
		}else{
			#echo "DHCP BIND erfolgreich";
		   foreach ($au_array as $au){
			   $results = ldap_mod_replace($dhcp_ds,$au,$entry);
				if ($results){
			      echo "<b>dhcpMTime</b> erfolgreich in AU ".$au." aktualisiert!<br>" ;
					#return 1;
			   }else{
			      echo "<br>Fehler beim Aktualisieren der <b>dhcpMTime</b> in AU $au!<br>" ;
			   }
		   }
	   ldap_unbind($dhcp_ds);
	   }
   }
}


# freie x.x.x.0/24 Netzwerke einer AU holen
function get_networks(){

	global $ds, $suffix, $auDN, $ldapError;
   
   $networks = array();
   $fipb_array = get_freeipblocks_au($auDN);
   foreach ( $fipb_array as $fipb ){
      $exp = explode('_',$fipb);
      $fs = explode('.',$exp[0]);
      $fe = explode('.',$exp[1]);
      #print_r($fs); echo "<br>";
      #print_r($fe); echo "<br>";
      
      if ($fs[3] == 0){$networks [] = $exp[0];}
      $fs[2] = $fs[2] + 1;
      $fs[3] = 0;
      
      while ( $fs[2] <= $fe[2] ){
         $iprange = implode('_',array(implode('.',$fs),implode('.',$fs)));
         if (check_ip_in_iprange($iprange,$fipb)){
            $networks [] = implode('.',$fs);
            if ($fs[2] == 255){ $fs[1] = $fs[1] + 1; $fs[2] = 0; }
            else{ $fs[2] = $fs[2] + 1; }
         }
      }
   }
   #print_r($networks); echo "<br>";
   return $networks;
}

# x.x.x.0/24 Netzwerke einer AU holen
function get_max_networks(){

	global $ds, $suffix, $auDN, $ldapError;
   
   $networks = array();
   $mipb_array = get_maxipblocks_au($auDN);
   foreach ( $mipb_array as $mipb ){
      $exp = explode('_',$mipb);
      $fs = explode('.',$exp[0]);
      $fe = explode('.',$exp[1]);
      $fs[3] = 0;
      $networks [] = implode('.',$fs);
   }
   #print_r($networks); echo "<br>";
   $nets = array_unique($networks);
   return $nets;
}

# Check ob AU über noch freie x.x.x.0/24 Netzwerke verfügt (freie IP Blöcke)
function check_if_free_networks(){

	global $ds, $suffix, $auDN, $ldapError;
   
   $networks = 0;
   $fipb_array = get_freeipblocks_au($auDN);
   if ( $fipb_array[0] != "" ){
      foreach ( $fipb_array as $fipb ){
         $exp = explode('_',$fipb);
         $fs = explode('.',$exp[0]);
         $fe = explode('.',$exp[1]);
         
         if ($fs[3] == 0){return 1; break;}
         else{
            $fs[2] = $fs[2] + 1;
            $fs[3] = 0;
   
            while ( $fs[2] <= $fe[2] ){
               $iprange = implode('_',array(implode('.',$fs),implode('.',$fs)));
               if (check_ip_in_iprange($iprange,$fipb)){
                  return 1; break 2;
               }
               if ($fs[2] == 255){ $fs[1] = $fs[1] + 1; $fs[2] = 0; }
               else{ $fs[2] = $fs[2] + 1; }
            }
         }
      }
   }
   return $networks;
}

# Check ob AU über x.x.x.0/24 Netzwerke insgesamt verfügt (maximale IP Blöcke)
function check_if_max_networks(){

	global $ds, $suffix, $auDN, $ldapError;
   
   $networks = 0;
   $mipb_array = get_maxipblocks_au($auDN);
   if ( $mipb_array[0] != "" ){
      foreach ( $mipb_array as $mipb ){
         $exp = explode('_',$mipb);
         $fs = explode('.',$exp[0]);
         $fe = explode('.',$exp[1]);
         
         if ($fs[3] == 0){return 1; break;}
         else{
            $fs[2] = $fs[2] + 1;
            $fs[3] = 0;
   
            while ( $fs[2] <= $fe[2] ){
               $iprange = implode('_',array(implode('.',$fs),implode('.',$fs)));
               if (check_ip_in_iprange($iprange,$mipb)){
                  return 1; break 2;
               }
               if ($fs[2] == 255){ $fs[1] = $fs[1] + 1; $fs[2] = 0; }
               else{ $fs[2] = $fs[2] + 1; }
            }
         }
      }
   }
   return $networks;
}

function test_ip_dhcpsubnet($ip) {

	global $ds, $suffix, $auDN, $ldapError;
	
	$ipexp = explode(".",$ip);
	array_splice($ipexp,-1,1,array("0"));
	$network  = implode(".",$ipexp);
	
	if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(&(objectclass=dhcpSubnet)(cn=$network)(dhcphlpcont=*))", array("cn","dhcphlpcont"), "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}else{
		$result = ldapArraySauber($result);
		if ($result){
			return 0;
		}else{
			return $network;
		}
	}
}

function add_to_file_structure($objectDN) {
	global $DHCP_FS_ROOT;
	$dhcp_dir = implode("/",array_reverse(array_slice(ldap_explode_dn($objectDN,1),1,-3)));
	$full_path = $DHCP_FS_ROOT."/".$dhcp_dir."/";
	echo "mkdir $full_path";
	mkdir_recursive($full_path, 0755);
	chown($full_path,"tarik");
}

function mkdir_recursive($pathname, $mode)
{
    is_dir(dirname($pathname)) || mkdir_recursive(dirname($pathname), $mode);
    return is_dir($pathname) || @mkdir($pathname, $mode);
}

###################################################################################################

function get_dhcpoffers($auDN){

	global $ds, $suffix, $auDN, $ldapError;
	
	$attribs = array("dn","dhcpofferdn");
	if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, "(objectclass=dhcpService)", $attribs, "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	else{
		$result = ldapArraySauber($result);
		#print_r($result);echo "<br><br>";
		
		$dhcp_offers = array();
		foreach ($result as $dhcp){
			if ( strpos($auDN, $dhcp['dhcpofferdn']) !== false ) # && $dhcp['dn'] != $dhcpserviceDN
				$dhcp_offers [] = $dhcp['dn'];
			}
		}
		#print_r($dhcp_offers);echo "<br><br>";
		return $dhcp_offers;
}

function alternative_dhcpservices($dhcpserviceDN){

   global $ds, $suffix, $auDN, $ldapError;
   
   $alt_dhcp = array();
   
   $dhcparray = get_dhcpoffers($auDN);
   # print_r($dhcparray); echo "<br>";
   if (count($dhcparray) != 0){
      for ($i=0; $i < count($dhcparray); $i++){
         if ($dhcparray[$i] != $dhcpserviceDN){
		      $exp = ldap_explode_dn ( $dhcparray[$i], 1 );
   	      $alt = array ("dn" => $dhcparray[$i], "cn" => $exp[0], "au" => " / ".$exp[2]);
   	      $alt_dhcp[] = $alt; 
         }
      }
   }
   
   return $alt_dhcp;
}

function alternative_dhcpsubnets($dhcpsubnetDN){

   global $ds, $suffix, $auDN, $ldapError;
   
   $alt_subnet = array();
   $dhcpservices = get_dhcpoffers($auDN);
   #print_r($dhcpservices); echo "<br>";
   if (count($dhcpservices) != 0){
      foreach ($dhcpservices as $servDN){
         $attribs = array("dn","cn","dhcphlpcont");
         #$servDN = $item['dn'];
         #print_r($servDN); echo "<br>";
         $filter = "(&(objectclass=dhcpSubnet)(dhcphlpcont=$servDN))";
	      if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, $filter, $attribs, "cn", "sub", 0, 0))) {
 		      # redirect(5, "", $ldapError, FALSE);
  		      echo "no search";
  		      die;
	      }else{
		      $result = ldapArraySauber($result);
		      #print_r($result); echo "<br>";
		      foreach ($result as $subnet){
		         if ( check_subnet_mipb($subnet['cn']) && $subnet['dn'] != $dhcpsubnetDN){
		            $exp = ldap_explode_dn ( $subnet['dn'], 1 );
   	            $alt = array ("dn" => $subnet['dn'], "cn" => $exp[0], "au" => " / ".$exp[2]);
   	            $alt_subnet[] = $alt; 
		         }
		      }
		   }
		      
      }
   }
   
   return $alt_subnet;
}

function check_subnet_mipb($subnet){

   global $ds, $suffix, $auDN, $ldapError;
   
   $subexp = explode('.',$subnet);
   $ret = 0;
   $mipb_array = get_maxipblocks_au($auDN);
   if ( $mipb_array[0] != "" ){
      foreach ( $mipb_array as $mipb ){
         $exp = explode('_',$mipb);
         $ms = explode('.',$exp[0]);
         $me = explode('.',$exp[1]);
         if ( $subexp[2] >= $ms[2] && $subexp[2] <= $me[2] ){
            $ret = 1;
            break;
         }
      }
   }
   if ($ret){return 1;}
   else{return 0;}
   
}

###############################################################################
# Funktionen zur Verwaltung von DHCP Service Objekten
#

function add_dhcpservice ($dhcpserviceName,$dhcpoffer,$atts){

   global $ds, $suffix, $auDN, $ldapError;
   
   #$dnarray = ldap_explode_dn ( $dhcpserviceDN, 1 );
   $dhcpserviceDN = "cn=".$dhcpserviceName.",cn=dhcp,".$auDN;
   
	$entrydhcp ['objectclass'][0] = "dhcpService";
   $entrydhcp ['objectclass'][1] = "dhcpOptions";
   $entrydhcp ['objectclass'][2] = "top";
	$entrydhcp ['cn'] = $dhcpserviceName;
   $entrydhcp ['dhcpofferdn'] = $dhcpoffer;
	
	# weitere Attribute
	foreach (array_keys($atts) as $key){
		if ($atts[$key] != ""){
			$entrydhcp[$key] = $atts[$key];
		}
	}
	print_r($entrydhcp); echo "<br>";
	print_r($dhcpserviceDN); echo "<br>";
	
	if ($result = ldap_add($ds, $dhcpserviceDN, $entrydhcp)){
		return 1;
	}
	else{
		$mesg = "Fehler beim eintragen des neuen DHCP Service Objekts!";
		return 0;
	}
}


# Löschen von Referenzen (dhcpHlpService) auf DHCP Service Objekt
function cleanup_del_dhcpservice ($dhcpserviceDN){
   
   global $ds, $suffix, $auDN, $ldapError;
   
   $filter = "(&(|(objectClass=dhcpSubnet)(objectclass=dhcpHost))(dhcphlpcont=$dhcpserviceDN))";
   if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, $filter, array("dn"), "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	$result = ldapArraySauber($result);
	$delentry ['dhcphlpcont'] = $dhcpserviceDN;
	foreach ($result as $item){
		ldap_mod_del($ds, $item['dn'], $delentry);
	}
}


# Anpassen von Referenzen auf DHCP Service Objekt an neuen DN
function adjust_dhcpservice_dn ($newdhcpserviceDN,$dhcpserviceDN){
   
   global $ds, $suffix, $auDN, $ldapError;

   $filter = "(&(|(objectClass=dhcpSubnet)(objectclass=dhcpHost))(dhcphlpcont=$dhcpserviceDN))";
   if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, $filter, array("dn"), "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	$result = ldapArraySauber($result);
	$modentry ['dhcphlpcont'] = $newdhcpserviceDN;
	foreach ($result as $item){
		ldap_mod_replace($ds, $item['dn'], $modentry);
	}

}



function alternative_dhcpobjects($objecttype,$objectDN,$ip){

   global $ds, $suffix, $auDN, $assocdom, $ldapError;
   
   $alt_dhcp = array();
   $expip = explode('.',$ip);
   $subnetDN = "";
   
   /*if ($objecttype == "subnet"){
      # alternative DHCP Dienstobjekte eigene AU/übergeordnete AUs
      $servarray = alternative_dhcpservices("");
      #print_r($servarray); echo "<br>";
      if (count($servarray) != 0){
         for ($i=0; $i < count($servarray); $i++){
		      $alt_dhcp[] = $servarray[$i];
	      }
      }
      if ($ip == ""){
         # alternative DHCP Subnetzobjekte eigene AU/übergeordnete AUs hinzufügen 
         $subarray = alternative_dhcpsubnets($objectDN);
         #print_r($subarray);
         if (count($subarray) != 0){
            for ($i=0; $i < count($subarray); $i++){
   			      $alt_dhcp[] = $subarray[$i];
   	      }
         }
      }
   }*/
   
   if ($objecttype == "service"){
      # alternative DHCP Dienstobjekte eigene AU/übergeordnete AUs
      $servarray = alternative_dhcpservices($objectDN);
      #print_r($servarray); echo "<br>";
      if (count($servarray) != 0){
         for ($i=0; $i < count($servarray); $i++){
		      $alt_dhcp[] = $servarray[$i];
	      }
      }
      /*# Subnetz entsprechend IP
      $subarray = alternative_dhcpsubnets($objectDN);
      #print_r($subarray);
      if (count($subarray) != 0){
         for ($i=0; $i < count($subarray); $i++){
            $expsub = explode('.', $subarray[$i]['cn']);
            if ($expip[0] == $expsub[0] && $expip[1] == $expsub[1] && $expip[2] == $expsub[2]){
			      $alt_dhcp[] = $subarray[$i];
			      $subnetDN = $subarray[$i]['dn'];
			      break;
	   	   }
	      }
      }
      # falls keine IP weitere Subnetze hinzufügen
      #print_r($subarray);
      if ( $ip == "" && count($subarray) != 0 ){
         for ($i=0; $i < count($subarray); $i++){
   	      if ($subnetDN != $subarray[$i]['dn']){
   		      $alt_dhcp[] = $subarray[$i];
   	  	   }
   	   }
      }*/
   }
   
   if ($objecttype == "nodhcp"){
      # alternative DHCP Dienstobjekte eigene AU/übergeordnete AUs
      $servarray = alternative_dhcpservices("");
      #print_r($servarray); echo "<br>";
      if (count($servarray) != 0){
         for ($i=0; $i < count($servarray); $i++){
		      $alt_dhcp[] = $servarray[$i];
	      }
      }
      /*# Subnetz entsprechend IP
      $subarray = alternative_dhcpsubnets($objectDN);
      #print_r($subarray);
      if (count($subarray) != 0){
         for ($i=0; $i < count($subarray); $i++){
            $expsub = explode('.', $subarray[$i]['cn']);
            if ($expip[0] == $expsub[0] && $expip[1] == $expsub[1] && $expip[2] == $expsub[2]){
			      $alt_dhcp[] = $subarray[$i];
			      $subnetDN = $subarray[$i]['dn'];
			      break;
	   	   }
	      }
      }
      # falls keine IP weitere Subnetze hinzufügen
      #print_r($subarray); echo "<br>";print_r($subnetDN);
      if ( $ip == "" && count($subarray) != 0 ){
         for ($i=0; $i < count($subarray); $i++){
   	      if ($subnetDN != $subarray[$i]['dn']){
   		      $alt_dhcp[] = $subarray[$i];
   	  	   }
   	   }
      }*/
   }
   #echo "<br>";print_r($alt_dhcp);
   return $alt_dhcp;
}


###############################################################################
# Funktionen zur Verwaltung von DHCP Subnet Objekten
#

function add_dhcpsubnet ($cn,$dhcpservice,$netmask,$atts,$subnet_audn){

   global $ds, $suffix, $ldapError;
   
   if (!$subnet_audn) {
		$subnet_audn = $auDN;
	}
   $subnet = implode('_',array($cn,$cn));
   
   $ipmatch = 0;
   
   # IP checken und FIBS anpassen
   $fipb_array = get_freeipblocks_au($subnet_audn);
   
	for ($i=0; $i < count($fipb_array); $i++){
		if ( split_iprange($subnet,$fipb_array[$i]) != 0 ){
			$ipmatch = 1;
			$ipranges = split_iprange($subnet,$fipb_array[$i]);
			array_splice($fipb_array, $i, 1, $ipranges);
			break;
		}		
	}
	
	if ($ipmatch) {	
		# ldap_mod_replace -> Array fipb_array aktualisiert die FIPB in AU mit $auDN
		if ($fipb_array){
   		foreach ( $fipb_array as $item ){
   		 	$entry ['FreeIPBlock'][] = $item;
   		}
   	}else{
   		$entry ['FreeIPBlock'] = array();
   	}
		 
		$results = ldap_mod_replace($ds,$subnet_audn,$entry);
		if ($results){
			#echo "<br>FIPBs erfolgreich angepasst!<br>" ;
			
			$dhcpsubnetDN = "cn=".$cn.",cn=dhcp,".$subnet_audn;
   
      	$entrydhcp ['objectclass'][0] = "dhcpSubnet";
         $entrydhcp ['objectclass'][1] = "dhcpOptions";
         $entrydhcp ['objectclass'][2] = "top";
      	$entrydhcp ['cn'] = $cn;
         $entrydhcp ['dhcpoptnetmask'] = $netmask;
         if ( $dhcpservice ){
            $entrydhcp ['dhcphlpcont'] = $dhcpservice;
         }
         # broadcast Adresse durch Subnetz vorgegeben
         #$exp_cn = explode (".",$cn);
         #array_splice($exp_cn, -1, 1, "255");
     		#$broadcast = implode (".", $exp_cn);
         #$entrydhcp ['dhcpoptbroadcast-address'] = $broadcast;
      	# weitere Attribute
      	foreach (array_keys($atts) as $key){
      		if ($atts[$key] != ""){
      			$entrydhcp[$key] = $atts[$key];
      		}
      	}
      	#print_r($entrydhcp); echo "<br>";
      	#print_r($dhcpsubnetDN); echo "<br>";
      	
      	if ($result = ldap_add($ds, $dhcpsubnetDN, $entrydhcp)){
      	   printf("Subnet <b>%s / %s</b> erfolgreich eingetragen<br>",$cn,$netmask);
      	   if ( $dhcpservice ){
      			#$subnetaudn = get_audn_of_objectdn($dhcpsubnetDN);
					#update_dhcpmtime($subnetaudn);					
					update_dhcpmtime($subnet_audn);
				}						
				return 1;
      	   #if ( check_ip_in_subnet($range1,$cn) && check_ip_in_subnet($range2,$cn)){
      	   #   $dhcprange = implode('_',array($range1,$range2));
				#   if ( $range = new_ip_dhcprange($dhcprange,$dhcpsubnetDN,$auDN) ){
				#      echo "DHCP Range <b>".$range1." - ".$range2."</b> erfolgreich im Subnetobjekt eingetragen";
				#   }else{
				#      echo "DHCP Range <b>".$range1." - ".$range2."</b> konnte nicht im Subnetobjekt eingetragen werden!";
				#   }
				#   return 1;
				#}else{
				#   echo "DHCP Range nicht in Subnetz ".$cn." enthalten.<br>Keine DHCP Range angelegt.<br>";
				#   return 1;
				#}
	   	}else{ 
	   		echo "<br>Fehler beim anlegen des DHCP Subnet Objekts!<br>";
	   		return 0;
	   	}	 
	   }else{
	   	echo "<br>Fehler beim eintragen der FIPBs!<br>";
	   	return 0;
	   }	      
	}
	else{
		printf("<br>Subnet %s nicht im verfuegbaren IP Bereich!<br>", $subnet );
		return 0;
	}
   
}

function delete_dhcpsubnet($subnetDN,$cn,$dhcpsrv){
   
   global $ds, $suffix, $ldapError;
   
   $subnetaudn = get_audn_of_objectdn($subnetDN);
   
   delete_ip_dhcprange($subnetDN,$subnetaudn);
   if ( dive_into_tree_del($subnetDN,"") ){
		del_dhcpsubnet_pools($subnetDN);
      $oldsubnetip = implode("_",array($cn,$cn));
      $entry ['FreeIPBlock'] = $oldsubnetip;
      $results = ldap_mod_add($ds,$subnetaudn,$entry);
   	if ($results){
   	   merge_ipranges($subnetaudn);
   	   if ( $dhcpsrv ){
   	   	update_dhcpmtime($subnetaudn);
   	   }
   	   return 1;
		}else{
	      return 0;
	   }
	}else{
      return 0;
   }
  
}

# Pools des DHCP Subnets auch löschen, wenn Subnet gelöscht wird.
function del_dhcpsubnet_pools ($dhcpsubnetDN){

   global $ds, $suffix, $auDN, $ldapError;

   $filter = "(&(objectclass=dhcpPool)(dhcphlpcont=$dhcpsubnetDN))";
   if(!($result = uniLdapSearch($ds, $auDN, $filter, array("dn","cn","dhcprange"), "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	$result = ldapArraySauber($result);
	#print_r($result);echo "<br>";
	echo "<br>Pools des DHCP Subnets l&ouml;schen:<br>";
	$delentry ['dhcphlpcont'] = $dhcpsubnetDN;
	foreach ($result as $item){
		echo "Pool $item[cn]<br>";
		echo "$item[dn]<br>";
		delete_dhcppool($item['dn']);
	}
}



function modify_subnet_dn($subnetDN,$newsubnetDN){
   
   global $ds, $suffix, $auDN, $ldapError;
   
   # check IP-Net-Syntax ...
   
   # Subnet CNs (IP) in internes Range ".._.." Format bringen
   $newcn = ldap_explode_dn($newsubnetDN,1);
   $newcnarray = array($newcn[0],$newcn[0]);
   $newsubnetip = implode("_",$newcnarray);
   $oldcn = ldap_explode_dn($subnetDN,1);
   $oldcnarray = array($oldcn[0],$oldcn[0]);
   $oldsubnetip = implode("_",$oldcnarray);   
   
   # IP checken und FIBS anpassen
   $fipb_array = get_freeipblocks_au($auDN);
	for ($i=0; $i < count($fipb_array); $i++){
		if ( split_iprange($newsubnetip,$fipb_array[$i]) != 0 ){
			$ipranges = split_iprange($newsubnetip,$fipb_array[$i]);
			array_splice($fipb_array, $i, 1, $ipranges);
			break;
		}		
	}
	
	if ($i < count($fipb_array) ){
		
		# zunächst alte DHCP Ranges löschen
		delete_ip_dhcprange($subnetDN,$auDN);
	   # Move Subtree
	   if(move_subtree($subnetDN, $newsubnetDN)){
   		adjust_dhcpsubnet_dn($newsubnetDN, $subnetDN);
   	   printf("<br>Subnet Name (IP) erfolgreich von %s zu %s ge&auml;ndert!<br>", $oldcn[0], $newcn[0]);
   	   # neue Subnetz-IP aus FIPBs entfernen
   	   foreach ( $fipb_array as $item ){
   		 	$entry ['FreeIPBlock'][] = $item;
   		}
   		# alte Subnetz-IP in FIPBs integrieren
   		$entry ['FreeIPBlock'][] = $oldsubnetip;
   		$results = ldap_mod_replace($ds,$auDN,$entry);
   		if ($results){
   		   merge_ipranges($auDN);
   		   update_dhcpmtime($auDN);
   	      echo "<br>FIPBs erfolgreich angepasst!<br>" ;
   	      return 1;
   	   }else{
   	      echo "<br>Fehler beim Anpassen der FIPBs!<br>" ;
   	   }
   	}else{
   	   echo "<br>Fehler beim &auml;ndern des Subnet Namens (IP)!<br>" ;
   	}
	}else{
		printf("<br>Neues Subnet %s nicht im verfuegbaren IP Bereich!<br>", $newcn[0] );
		return 0;
	}
}

/*
# wird eigentlich nicht benötigt wenn host deklarationen nicht in subnet scope sind ...
function adjust_dhcpsubnet_dn ($newdhcpsubnetDN,$dhcpsubnetDN){
   
   global $ds, $suffix, $auDN, $ldapError;

   $filter = "(&(objectclass=dhcpHost)(dhcphlpcont=$dhcpsubnetDN))";
   if(!($result = uniLdapSearch($ds, "ou=RIPM,".$suffix, $filter, array("dn"), "dn", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";
  		die;
	}
	$result = ldapArraySauber($result);
	$modentry ['dhcphlpcont'] = $newdhcpsubnetDN;
	foreach ($result as $item){
		ldap_mod_replace($ds, $item['dn'], $modentry);
	}
}

# Nach Änderung der Host IP Adresse, überprüfen ob neue IP noch mit Subnet übereinstimmt
# Falls keine Übereinstimmung mehr, dann Subnetzuordnung aus Host löschen.
# wird eigentlich nicht benötigt wenn host deklarationen nicht in subnet scope sind ...
function adjust_hostip_dhcpsubnet($ip,$hostDN,$dhcphlpcont) {

   global $ds, $suffix, $auDN, $ldapError;
   
   $subnet = ldap_explode_dn($dhcphlpcont, 1);
   $expsub = explode('.', $subnet[0]);
   print_r($expsub); echo "<br>";
   $expip = explode('.', $ip);
   print_r($expsip); echo "<br>";
   if ($expip[0] != $expsub[0] || $expip[1] != $expsub[1] || $expip[2] != $expsub[2]){
      $entrydhcp ['dhcphlpcont'] = array();
      ldap_mod_del($ds,$hostDN,$entrydhcp);
      echo "Host mit neuer IP <b>".$ip."</b> wurde aus DHCP Subnet <b>".$subnet[0]."</b> entfernt<br><br>";
   }
}
*/

function check_ip_in_subnet($ip,$subnet) {

   global $ds, $suffix, $auDN, $ldapError;
   $ipchunks = explode('.',$ip);
   $netchunks = explode('.',$subnet);
   $return = 0;
   for ($i=1; $i<4; $i++){
      if ( $netchunks[$i] == "0" ){
         if ( $ipchunks[$i-1] == $netchunks[$i-1] ){
            $return = 1;
         }
         break;
      }
   }
   if ($return) { return 1; }else{ return 0; }
}


# Aus Array von child-AUs dieejenigen die IP Bereiche im Subnetz haben
function get_subnet_childaus ($all_childs, $subnetcn) {

	$childs = array();
	$subnetip = explode(".",$subnetcn);
	
	foreach ($all_childs as $childau) {
		
		# AUs die Subnet administrieren in rot
		$red = "";	
		$red_end = "";	
		
		if ( $childau ['maxipblock'] ) {
			if ( is_array($childau ['maxipblock']) ) {
				$ipblocks = "";						
				foreach ($childau ['maxipblock'] as $mipb) {
					$expmipb = explode("_",$mipb);
					$mipb1 = explode(".",$expmipb[0]);
					$mipb2 = explode(".",$expmipb[1]);
					if ($subnetip[0] == $mipb1[0] && $subnetip[1] == $mipb1[1] && $subnetip[2] == $mipb1[2]){
						#$ipblocks [] = "$mipb1[2].$mipb1[3] - $mipb2[2].$mipb2[3]";
						$netadmin = "";
						if ($mipb1[3] == "0"){
							$netadmin = 1;
							$red = "<code class='red_font_object'>";
							$red_end = "</code>";
						}
						$ip_string = "<td align='right' width='30%'>$red $mipb1[3] $red_end</td>";
						if ($mipb1[3] != $mipb2[3]){
							$ip_string .= "<td align='center' width='15%'> - </td>
											<td align='right' width='30%'>$red $mipb2[3] $red_end</td>
											<td>&nbsp;&nbsp;</td>";
						}else{
							$ip_string .= "<td align='center' width='15%'>&nbsp;&nbsp;</td>
											<td align='right' width='30%'>&nbsp;&nbsp;</td>
											<td>&nbsp;&nbsp;</td>";
						}
						$ipblocks [] = $ip_string;
						#$ipblocks [] = "<td align='right' width='30%'>$red $mipb1[3] $red_end</td>
						#					<td align='center' width='15%'> - </td>
						#					<td align='right' width='30%'>$red $mipb2[3] $red_end</td>
						#					<td>&nbsp;&nbsp;</td>";
					   $ipblocks = array_natsort($ipblocks, "", "");
					}
					
				}
				if ( $ipblocks ) {
				$childs [] = array('au' => $childau['ou'],
									 	 'dn' => $childau['dn'],
										'zone' => $childau['associateddomain'],
										'mipb' => $ipblocks,
										'netadmin' => $netadmin);						
				}
			}else{
				$expmipb = explode("_",$childau ['maxipblock']);
				$mipb1 = explode(".",$expmipb[0]);
				$mipb2 = explode(".",$expmipb[1]);
				if ($subnetip[0] == $mipb1[0] && $subnetip[1] == $mipb1[1] && $subnetip[2] == $mipb1[2]){
					$netadmin = "";
					if ($mipb1[3] == "0"){
						$netadmin = 1;
						$red = "<code class='red_font_object'>";
						$red_end = "</code>";
					}
					$childs [] = array('au' => $childau['ou'],
											 'dn' => $childau['dn'],
											 'zone' => $childau['associateddomain'],
											 #'mipb' => "$mipb1[2].$mipb1[3] - $mipb2[2].$mipb2[3]");
											 'mipb' => "<td align='right' width='30%'>$red $mipb1[3] $red_end</td>
											 				<td align='center' width='15%'> - </td>
											 				<td align='right' width='30%'>$red $mipb2[3] $red_end</td>
											 				<td>&nbsp;&nbsp;</td>",
											 'netadmin' => $netadmin);
				}
			}
		}
	}
	#$childs = array_natsort($childs, "mipb", "mipb");
	return $childs;
}


#########################
# Pools
function add_dhcppool ($dhcpsubnetdn,$range,$pcl,$dhcpservicedn,$poolopt_domain,$rbssrvdn){

   global $ds, $suffix, $auDN, $ldapError;

   if(!($result = uniLdapSearch($ds, "cn=dhcp,".$auDN,"(objectclass=*)", array("cn"), "dn", "list", 0, 0))) {
		# redirect(5, "", $ldapError, FALSE);
		echo "no search";
		die;
	}
	$result = ldapArraySauber($result);

	$dhcpcn_array = array();
   foreach ($result as $item){
      $dhcpcn_array [] = $item['cn'];
   }
   #print_r($dhcpcn_array);echo "<br><br>";
   for ($i=0;$i<100;$i++){
	   if ( array_search ( "Pool".$i, $dhcpcn_array ) === false ){
	      $cn = "Pool".$i;
	      break;
	   }
	}
   $dhcppoolDN = "cn=".$cn.",cn=dhcp,".$auDN;

   $entrydhcp ['objectclass'][0] = "dhcpPool";
   $entrydhcp ['objectclass'][1] = "dhcpOptions";
   $entrydhcp ['objectclass'][2] = "top";
	$entrydhcp ['cn'] = $cn;
   $entrydhcp ['dhcphlpcont'] = $dhcpsubnetdn;
   $entrydhcp ['dhcprange'] = $range;
   if ($pcl){
      $entrydhcp ['dhcppermittedclients'] = $pcl;
   }
   if ($poolopt_domain) {
   	$entrydhcp ['dhcpoptdomain-name'] = $poolopt_domain;
   }
	if ( $rbssrvdn ){
		$entrydhcp ['hlprbservice'] = $rbssrvdn;
	}
   #print_r($dhcppoolDN);echo "<br><br>";
   #print_r($entrydhcp);echo "<br><br>";
	
   if ($result = ldap_add($ds,$dhcppoolDN,$entrydhcp)){
   
		#add_to_file_structure($dhcppoolDN);   
     return 1;
   }else{return 0;}
	
}

function delete_dhcppool($poolDN){
   
   global $ds, $suffix, $auDN, $ldapError;
   
   $exppooldn = ldap_explode_dn($poolDN,0);
   $exppooldn = array_slice($exppooldn, 3);
   $poolaudn = implode(',',$exppooldn);
   echo "Pool-AUDN: $poolaudn<br>";
   $ranges_array = get_dhcp_range2($poolDN);
	if (count($ranges_array) != 0){
      if (count($ranges_array) > 1){  
   		foreach ($ranges_array as $range){
   			$new_fipbs ['FreeIPBlock'][] = $range;
   		}
   	}else{
   		$new_fipbs ['FreeIPBlock'] = $ranges_array[0];
   	}
   }
   #echo "Ranges: "; print_r($ranges_array); echo "<br>";
   #echo "FIPBS: "; print_r($new_fipbs); echo "<br>";
	if ( dive_into_tree_del($poolDN,"") ){
		if (ldap_mod_add($ds,$poolaudn,$new_fipbs)){
 	   	merge_ipranges($poolaudn);
	   	return 1;
	   }
	}else{
		echo "Fehler beim l&ouml;schen des Pool-Objekts";
	   return 0;
	}
}

?>