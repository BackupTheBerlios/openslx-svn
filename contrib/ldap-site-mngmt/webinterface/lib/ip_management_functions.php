<?php

/**  
* ip_management_functions.php - IP Management Funktions-Bibliothek
* Diese Bibliothek enthält alle Funktionen für die Verwaltung der IP Adressen. 
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


####################################################################################
# Basisfunktionen zur Verarbeitung von IP Ranges 

/*PHP Funktionen ip2long(), long2ip() machen dasselbe und werden verwendet
function ip_dot_to_long($ip_dot)
{	
	$ip_long = unpack('N*', pack('C*', preg_split('/\./',$ip_dot)));
	return $ip_long;
}

function ip_long_to_dot($ip_long)
{
	$ip_dot = join('.',unpack('C*',pack('N',$ip_long)));
	return $ip_dot;
}*/ 

/**
* check_ip_in_iprange($iprange1, $iprange2)  
* Prueft ob erste IP Range in zweiter IP Range enthalten ist.
*
* @param string iprange1 erste IP Range
* @param string iprange2 zweite IP Range
*
* @return boolean Erfolg bzw. Misserfolg
*
* @author Tarik Gasmi
*/
function check_ip_in_iprange($iprange1,$iprange2)
{
	$ipr1exploded = explode('_',$iprange1);
	$ipr2exploded = explode('_',$iprange2); 
	$ipr1s = ip2long($ipr1exploded[0]);
	$ipr1e = ip2long($ipr1exploded[1]);
	$ipr2s = ip2long($ipr2exploded[0]);
	$ipr2e = ip2long($ipr2exploded[1]);
	
	if( $ipr1s >= $ipr2s && $ipr1e <= $ipr2e ){ return 1;}
	else{ return 0;}
}


/**
* split_iprange($iprange1, $iprange2)  
* Entnimmt erste IP Range aus der zweiten IP Range und gibt bei Erfolg Array verbleibender 
* IP Ranges zurueck.
*
* @param string iprange1 erste IP Range
* @param string iprange2 zweite IP Range
*
* @return array bei Erfolg bzw. boolean 0 bei Misserfolg
*
* @author Tarik Gasmi
*/
function split_iprange($iprange1,$iprange2)
{  
	$iprange3;
	$iprange4;
	$ipranges = array();
	
	if (check_ip_in_iprange($iprange1,$iprange2) == 1)
	{		
		$ipr1exploded = explode('_',$iprange1);
		$ipr2exploded = explode('_',$iprange2); 
		$ipr1s = ip2long($ipr1exploded[0]);
		$ipr1e = ip2long($ipr1exploded[1]);
		$ipr2s = ip2long($ipr2exploded[0]);
		$ipr2e = ip2long($ipr2exploded[1]);
		
		$ipr3s = $ipr2s;
		$ipr3e = $ipr1s - 1;
		$ipr4s = $ipr1e + 1;
		$ipr4e = $ipr2e;
		
		if ($ipr3s <= $ipr3e){$iprange3 = long2ip($ipr3s)."_".long2ip($ipr3e); $ipranges[] = $iprange3;}
		if ($ipr4s <= $ipr4e){$iprange4 = long2ip($ipr4s)."_".long2ip($ipr4e); $ipranges[] = $iprange4;}
		
		#echo "MATCH!<br>";
		return $ipranges;
	}
	else
	{
		#echo "IPRange1 not in IPRange2: ";
		return 0;
	}
}


/**
* intersect_ipranges($iprange1, $iprange2)  
* Bildet die Schnittmenge zweier IP Ranges.
*
* @param string iprange1 erste IP Range
* @param string iprange2 zweite IP Range
*
* @return string iprange3 Schnitt-IP-Range 
*
* @author Tarik Gasmi
*/
function intersect_ipranges($iprange1,$iprange2)
{  
	$ipr1exploded = explode('_',$iprange1);
	$ipr2exploded = explode('_',$iprange2); 
	$ipr1s = ip2long($ipr1exploded[0]);
	$ipr1e = ip2long($ipr1exploded[1]);
	$ipr2s = ip2long($ipr2exploded[0]);
	$ipr2e = ip2long($ipr2exploded[1]);
	
	if ( $ipr1s >= $ipr2s ){$ipr3s = $ipr1s;}else{$ipr3s = $ipr2s;}
	if ( $ipr1e <= $ipr2e ){$ipr3e = $ipr1e;}else{$ipr3e = $ipr2e;}
	
	if ($ipr3s <= $ipr3e){
		$iprange3 = long2ip($ipr3s)."_".long2ip($ipr3e);
		return $iprange3;
	}
	else{
	 return ""; 
	 echo "No Intersection<br>";
	}
}


/**
* merge_2_ipranges($iprange1, $iprange2)  
* Vereinigt 2 IP Ranges zu einer IP Range, falls sie adjazent sind oder sich ueberschneiden.
*
* @param string iprange1 erste IP Range
* @param string iprange2 zweite IP Range
*
* @return string iprange3 bei Erfolg bzw. boolean 0 bei Misserfolg.
*
* @author Tarik Gasmi
*/
function merge_2_ipranges($iprange1,$iprange2)
{

	$ipr1exploded = explode('_',$iprange1);
	$ipr2exploded = explode('_',$iprange2); 
	$ipr1s = ip2long($ipr1exploded[0]);
	$ipr1e = ip2long($ipr1exploded[1]);
	$ipr2s = ip2long($ipr2exploded[0]);
	$ipr2e = ip2long($ipr2exploded[1]);
	
	if ( ($ipr1e + 1) >= $ipr2s && $ipr1s <= ($ipr2e + 1) ){
		if ($ipr1s <= $ipr2s){ $ipr3s = $ipr1s; }else{ $ipr3s = $ipr2s; }
		if ($ipr1e <= $ipr2e){ $ipr3e = $ipr2e; }else{ $ipr3e = $ipr1e; }
		
		if ($ipr3s <= $ipr3e){
			$iprange3 = long2ip($ipr3s)."_".long2ip($ipr3e); 
			printf("Merging: %s and %s -> %s<br>",$iprange1,$iprange2,$iprange3);
			return $iprange3; 
		}
		else{
			# printf("No Merging possible: %s and %s<br>",$iprange1,$iprange2); 
			return 0; }
	}
	else{
		# printf("No Merging possible: %s and %s<br>",$iprange1,$iprange2);
		return 0;
	}
}


#########################################################################################
# IP Management LDAP Grundfunktionen 

/**
* get_freeipblocks_au($auDN)  
* Holt die FreeIPBlocks einer AU und gibt sie in einem Array zurueck.
*
* @param string auDN Distinguished Name des LDAP AU-Objektes
*
* @return array fipb_array FreeIPBlocks der AU.
*
* @author Tarik Gasmi
*/
function get_freeipblocks_au($auDN)
{
	global $ds, $suffix, $ldapError;

	if(!($result = uniLdapSearch($ds, $auDN, "objectclass=*", array("FreeIPBlock"), "", "one", 0, 0))) {
      # redirect(5, "", $ldapError, FALSE);
      echo "search problem";
      die;
   } else {
   	$fipb_array = array();
   	$result = ldapArraySauber($result);
		foreach ($result as $item){
			if (count($item['freeipblock']) > 1){
	   		$fipb_array = $item['freeipblock'];
   		}
   		else{
   			$fipb_array[] = $item['freeipblock'];
   		}   	
   	}
   }
   return $fipb_array;
}

/**
* get_maxipblocks_au($auDN)  
* Holt die MaxIPBlocks einer AU und gibt sie in einem Array zurueck.
*
* @param string auDN Distinguished Name des LDAP AU-Objektes
*
* @return array mipb_array MaxIPBlocks der AU.
*
* @author Tarik Gasmi
*/
function get_maxipblocks_au($auDN)
{
	global $ds, $suffix, $ldapError;

	if(!($result = uniLdapSearch($ds, $auDN, "objectclass=*", array("MaxIPBlock"), "", "one", 0, 0))) {
      # redirect(5, "", $ldapError, FALSE);
      echo "search problem";
      die;
   } else {
   	$result = ldapArraySauber($result);
		foreach ($result as $item){
			if (count($item['maxipblock']) > 1){
	   		$mipb_array = $item['maxipblock'];
   		}
   		else{
   			$mipb_array[] = $item['maxipblock']; 
   		}
   	}
   }
   return $mipb_array;
}

# benutze IP Ranges (Rechner, Ranges, Delegs)
function get_used_ipblocks_au($auDN)
{
	global $ds, $suffix, $ldapError;
   
   $host_ips = array();
   $dhcps_ips = array();
   $dhcpr_ips = array(); 
   $deleg_ips = array(); 
   # Rechner IPs
	if(!($result = uniLdapSearch($ds, "cn=computers,".$auDN, "(objectclass=Host)", array("IPAddress"), "", "list", 0, 0))) {
      # redirect(5, "", $ldapError, FALSE);
      echo "no search";
      die;
   } else {
   	$result = ldapArraySauber($result);
		foreach ($result as $item){
			if (count($item['ipaddress']) != 0){
	   		$host_ips [] = $item['ipaddress'];
   		}
   	}
   }
   echo "Rechner IPs:<br>"; print_r($host_ips); echo "<br><br>";
   
   # DHCP Subnets
   if(!($result = uniLdapSearch($ds, "cn=dhcp,".$auDN, "(objectclass=dhcpSubnet)", array("cn"), "", "list", 0, 0))) {
      # redirect(5, "", $ldapError, FALSE);
      echo "no search";
      die;
   } else {
   	$result = ldapArraySauber($result);
		foreach ($result as $item){
   		$dhcps_ips [] = $item['cn']."_".$item['cn'];
   	}
   }
   echo "DHCP Subnets:<br>"; print_r($dhcps_ips); echo "<br><br>";
   
   # DHCP Pool Ranges
   if(!($result = uniLdapSearch($ds, "cn=dhcp,".$auDN, "(objectclass=dhcpPool)", array("dhcpRange"), "", "list", 0, 0))) {
      # redirect(5, "", $ldapError, FALSE);
      echo "no search";
      die;
   } else {
   	$result = ldapArraySauber($result);
		foreach ($result as $item){
			if (count($item['dhcprange']) > 1){
			   foreach ($item['dhcprange'] as $range){
   	   		$dhcpr_ips [] = $range;
   	      }
   		}
   		elseif (count($item['dhcprange']) == 1){
   			$dhcpr_ips [] = $item['dhcprange']; 
   		}
   	}
   }
   echo "DHCP Pool Ranges:<br>"; print_r($dhcpr_ips); echo "<br><br>";
   
   # Delegierte IPs
   $childau_array = get_childau($auDN,array("dn","ou","maxipblock"));
   #print_r($childau_array);
   if (count($childau_array) != 0){
      foreach ($childau_array as $childau){
         if (count($childau['maxipblock']) > 1){
            foreach ($childau['maxipblock'] as $mipb){
               $deleg_ips [] = $mipb;
            }
         }elseif (count($childau['maxipblock']) == 1){
            $deleg_ips [] = $childau['maxipblock'];
         }
      }
   }
   echo "Delegiert IP Blocks:<br>"; print_r($deleg_ips); echo "<br><br>";
   
   $used_ips = array_merge($host_ips, $dhcps_ips, $dhcpr_ips, $deleg_ips);
   sort($used_ips);
   $used_ips = merge_ipranges_array($used_ips);
   
   return $used_ips;
}


/**
* get_host_ip($hostDN)  
* Holt die IP Adressen eines Hosts und gibt sie in einem Array zurueck.
*
* @param string hostDN Distinguished Name des LDAP Host-Objektes
*
* @return array host_array IPs des Hosts.
*
* @author Tarik Gasmi
*/
function get_host_ip($hostDN)
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $hostDN, "(objectclass=Host)", array("hostName","IPAddress","dhcpOptFixed-address"), "hostName", "one", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
  		return 0;
	} 
	else {
		$result = ldapArraySauber($result);
		$host_array = array();
		
		foreach ($result as $item){
		   $host_array['hostname'] = $item['hostname'];
		   $host_array['ipaddress'] = $item['ipaddress'];
		   #if ( $item['dhcpoptfixed-address'] != "" ){
		      $host_array['dhcpoptfixed-address'] = $item['dhcpoptfixed-address'];
		   #}
   		# $host_array = array('hostname' => $item['hostname'], 'ipaddress' => $item['ipaddress']);
   	}
   	return $host_array;
	}
}


/**
* get_dhcp_range($dhcpobjectDN)  
* Holt die IP Ranges eines DHCP Subnets/Pools und gibt sie in einem Array zurueck.
*
* @param string dhcpobjectDN Distinguished Name des LDAP DHCP-Objektes
*
* @return array dhcp_array IP Ranges des Subnets/Pools.
*
* @author Tarik Gasmi
*/
function get_dhcp_range($dhcpobjectDN)
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $dhcpobjectDN, "(objectclass=*)", array("cn","dhcpRange"), "cn", "one", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
  		return 0;
	} 
	else {
		$result = ldapArraySauber($result);
		$dhcp_array = array();
		
		foreach ($result as $item){
		   $dhcp_array['cn'] = $item['cn'];
		   $dhcp_array['dhcprange'] = $item['dhcprange'];
   	}
   	return $dhcp_array;
	}
}

function get_dhcp_range2($dhcpobjectDN)
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $dhcpobjectDN, "(objectclass=*)", array("dhcpRange"), "", "one", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
  		return 0;
	} 
	else {
		$result = ldapArraySauber($result);
		$dhcp_array = array();
		foreach ($result as $item){
		   if ( count($item['dhcprange']) == 1 ){
   	      $dhcp_array[] = $item['dhcprange'];
   	   }
   	   if ( count($item['dhcprange']) > 1 ){
   	      foreach ($item['dhcprange'] as $range){
   	         $dhcp_array[] = $range;
   	      }
   	   }
   	}
   	return $dhcp_array;
	}
}


/**
* merge_ipranges($auDN)  
* Nimmt die Arrays von IP Ranges eines AU Objektes, MaxIPBlocks und FreeIPBlocks, und vereinigt 
* rekusriv alle adjazenten/sich ueberschneidenden IP Ranges zu einer IP Range.
*
* @param string auDN Distinguished Name des LDAP AU-Objektes
*
* @author Tarik Gasmi
*/
function merge_ipranges($auDN)
{
	global $ds, $suffix, $ldapError;
   
   $fipb_array = get_freeipblocks_au($auDN);
   $mipb_array = get_maxipblocks_au($auDN);
   if ( count($fipb_array) > 1) sort($fipb_array);
   if ( count($mipb_array) > 1) sort($mipb_array);
   
   $c = count($fipb_array);
   for ($i=0; $i < $c; $i++){
   	for ($j=$i+1; $j < $c; $j++){
   		if ( merge_2_ipranges($fipb_array[$i],$fipb_array[$j])){
	   		$fipb_array[$i] = merge_2_ipranges($fipb_array[$i],$fipb_array[$j]);
   			array_splice($fipb_array, $j, 1); 
   			$c--;
   			$i=-1;
   			break;
   		}
   	}
   }
   #print_r($fipb_array);printf("<br>");
   foreach ( $fipb_array as $item ){
		$entry ['FreeIPBlock'][] = $item;
	}
	$results = ldap_mod_replace($ds,$auDN,$entry);
	if ($results) echo "FIPBs erfolgreich zusammengefasst!<br>" ;
   else echo "Fehler beim eintragen der FIPBs!<br>";	  
	 
	$d = count($mipb_array);
   for ($i=0; $i < $d; $i++){
   	for ($j=$i+1; $j < $d; $j++){
   		if ( merge_2_ipranges($mipb_array[$i],$mipb_array[$j])){
	   		$mipb_array[$i] = merge_2_ipranges($mipb_array[$i],$mipb_array[$j]);
   			array_splice($mipb_array, $j, 1); 
   			$d--;
   			$i=-1;
   			break;
   		}
   	}
   }
   #print_r($mipb_array);printf("<br>");
   foreach ( $mipb_array as $item ){
		 	$entry2 ['MaxIPBlock'][] = $item;
		}		 
	$results = ldap_mod_replace($ds,$auDN,$entry2);
	if ($results) echo "MIPBs erfolgreich zusammengefasst!<br>" ;
   else echo "Fehler beim eintragen der MIPBs!<br>";	  
}

function merge_dhcpranges($dhcpobjectDN)
{
	global $ds, $suffix, $ldapError;
   
   $dhcp_array = get_dhcp_range2($dhcpobjectDN);
   if ( count($dhcp_array) > 1) sort($dhcp_array);
   
   $c = count($dhcp_array);
   for ($i=0; $i < $c; $i++){
   	for ($j=$i+1; $j < $c; $j++){
   		if ( merge_2_ipranges($dhcp_array[$i],$dhcp_array[$j])){
	   		$dhcp_array[$i] = merge_2_ipranges($dhcp_array[$i],$dhcp_array[$j]);
   			array_splice($dhcp_array, $j, 1); 
   			$c--;
   			$i=-1;
   			break;
   		}
   	}
   }
   foreach ( $dhcp_array as $item ){
		$entry ['dhcprange'][] = $item;
	}
	$results = ldap_mod_replace($ds,$dhcpobjectDN,$entry);
	if ($results) echo "<br>DHCP Ranges erfolgreich zusammengefasst!<br><br>" ;
   else echo "<br>Fehler beim eintragen der DHCP Ranges!<br><br>";	  
}

function merge_ipranges_array($ipranges_array)
{
	global $ds, $suffix, $ldapError;
   
   sort($ipranges_array);
   $c = count($ipranges_array);
   for ($i=0; $i < $c; $i++){
   	for ($j=$i+1; $j < $c; $j++){
   		if ( merge_2_ipranges($ipranges_array[$i],$ipranges_array[$j])){
	   		$ipranges_array[$i] = merge_2_ipranges($ipranges_array[$i],$ipranges_array[$j]);
   			array_splice($ipranges_array, $j, 1); 
   			$c--;
   			$i=-1;
   			break;
   		}
   	}
   }
   return $ipranges_array;
   # Rückgabewert ...  
}


 
/**
* new_ip_host($ip,$hostDN,$auDN)  
* Weist einem Host eine IP Adresse neu zu, falls sie vergeben werden darf (in den FreeIPBlocks
* enthalten ist), und passt die FreeIPBlocks der AU an.
*
* @param string ip IP Adresse, die zugewiesen werden soll
* @param string hostDN Distinguished Name des LDAP Host-Objektes
* @param string auDN Distinguished Name des LDAP AU-Objektes
*
* @return boolean 1 bei Erfolg bzw. 0 bei Misserfolg
*
* @author Tarik Gasmi
*/
function new_ip_host($ip,$hostDN,$auDN)
{
	global $ds, $suffix, $ldapError;
   
   $fipb_array = get_freeipblocks_au($auDN);
   
	for ($i=0; $i < count($fipb_array); $i++){
		if ( split_iprange($ip,$fipb_array[$i]) != 0 ){
			$ipranges = split_iprange($ip,$fipb_array[$i]);
			array_splice($fipb_array, $i, 1, $ipranges);
			break;
		}		
	}
	
	if ($i < count($fipb_array) ){	
		# ldap_mod_replace -> Array fipb_array aktualisiert die FIPB in AU mit $auDN
		foreach ( $fipb_array as $item ){
		 	$entry ['FreeIPBlock'][] = $item;
		}
		 
		$results = ldap_mod_replace($ds,$auDN,$entry);
		if ($results){
			echo "<br>Neue FIPBs erfolgreich eingetragen!<br>" ;
			
			# ldap_mod_add -> IPAddress = $ip , in Host mit $hostDN
			$ipentry ['IPAddress'] = $ip;
			$results = ldap_mod_add($ds,$hostDN,$ipentry);
			if ($results){ 
				echo "<br>IP Adresse erfolgreich eingetragen!<br>" ;
				return 1;
	   	}else{ 
	   		echo "<br>Fehler beim eintragen der IP Adresse!<br>";
	   		return 0;
	   	}	 
	   }else{
	   	echo "<br>Fehler beim eintragen der FIPBs!<br>";
	   	return 0;
	   }	      
	}
	else{
		printf("<br>IP Adresse %s nicht im verfuegbaren Bereich!<br>", $ip );
		return 0;
	}
}

/**
* new_ip_dhcprange($ip,$dhcpobjectDN,$auDN)  
* Weist einem DHCP Subnet/Pool eine IP Range neu zu, falls sie vergeben werden darf (in den FreeIPBlocks
* enthalten ist), und passt die FreeIPBlocks der AU an.
*
* @param string ip IP Range, die zugewiesen werden soll
* @param string dhcpobjectDN Distinguished Name des LDAP DHCP-Objektes
* @param string auDN Distinguished Name des LDAP AU-Objektes
*
* @return boolean 1 bei Erfolg bzw. 0 bei Misserfolg
*
* @author Tarik Gasmi
*/
function new_ip_dhcprange($ip,$dhcpobjectDN,$auDN)
{
	global $ds, $suffix, $ldapError;
   
   $fipb_array = get_freeipblocks_au($auDN);
   
   #print_r($fipb_array);
   
	for ($i=0; $i < count($fipb_array); $i++){
		if ( split_iprange($ip,$fipb_array[$i]) != 0 ){
			$ipranges = split_iprange($ip,$fipb_array[$i]);
			array_splice($fipb_array, $i, 1, $ipranges);
			break;
		}		
	}
	
	if ($i < count($fipb_array) ){	
		# ldap_mod_replace -> Array fipb_array aktualisiert die FIPB in AU mit $auDN
		foreach ( $fipb_array as $item ){
		 	$entry ['FreeIPBlock'][] = $item;
		}
		 
		$results = ldap_mod_replace($ds,$auDN,$entry);
		if ($results){
			echo "<br>Neue FIPBs erfolgreich eingetragen!<br>" ;
			
			# ldap_mod_add -> IPAddress = $ip , in Host mit $hostDN 
			$ipentry ['dhcpRange'] = $ip;	
			$results = ldap_mod_add($ds,$dhcpobjectDN,$ipentry);
			if ($results){
				echo "<br>IP Adresse erfolgreich eingetragen!<br>" ;
				return 1;
	   	}else{
	   		echo "<br>Fehler beim eintragen der IP Adresse!<br>";
	   		return 0;
	   	}	    
		}else{
	   	echo "<br>Fehler beim eintragen der FIPBs!<br>";
	   	return 0;
	   }	  		
	}else{
		printf("<br>IP Range %s ist nicht im verfuegbaren Bereich!<br>", $ip );
		return 0;
	}	
}

## Add Dhcprange in DHCP Pool
function add_dhcprange($newrange,$pooldn) {
   
   global $ds, $auDN, $suffix, $ldapError;
   
   # Freie IP Bereiche testen
   $fipb_array = get_freeipblocks_au($auDN);
   $test = 0;
	for ($f=0; $f < count($fipb_array); $f++){
		if ( split_iprange($newrange,$fipb_array[$f]) != 0 ){
			$ipranges = split_iprange($newrange,$fipb_array[$f]);
			array_splice($fipb_array, $f, 1, $ipranges);
			$test = 1;
			break;
		}		
	}
	if ( $test ){
		foreach ( $fipb_array as $item ){
		 	$entry ['FreeIPBlock'][] = $item;
		}
		$result1 = ldap_mod_replace($ds,$auDN,$entry);
		if ($result1){
			echo "<br>Neue FIPBs erfolgreich eingetragen!<br>";
			$rangeentry ['dhcprange'] = $newrange;
			print_r($rangeentry);echo "<br><br>";
			$result2 = ldap_mod_add($ds,$pooldn,$rangeentry);
			if ($result2){
			      merge_dhcpranges($pooldn);
   				#printf("Neue dynamische IP Range %s - %s erfolgreich in Subnetz %s0 eingetragen!<br>",$addrange1[$i],$addrange2[$i],$net);
   				return 1;
	   	}else{
	   		# echo "<br>Fehler beim eintragen des dynamischen DHCP Pools!<br>";
	   		# Range wieder in FIPBs aufnehmen.
	   		$entry2 ['FreeIPBlock'] = $newrange;
	   		ldap_mod_add($ds,$auDN,$entry2);
	   		merge_ipranges($auDN);
	   		return 0;
	   	}
		}else{
	   	echo "<br>Fehler beim eintragen der FIPBs!<br>";
	   	return 0;
	   }	  		
	}else{
		printf("<br>IP Range %s ist nicht im verfuegbaren Bereich!<br>", $range );
		return 0;
	}
}


/**
* delete_ip_host($hostDN,$auDN)  
* Löscht die IP Adresse eines Hosts, und passt die FreeIPBlocks der AU an.
*
* @param string hostDN Distinguished Name des LDAP Host-Objektes
* @param string auDN Distinguished Name des LDAP AU-Objektes
*
* @return boolean 1 bei Erfolg bzw. 0 bei Misserfolg
*
* @author Tarik Gasmi
*/
function delete_ip_host($hostDN,$auDN)
{
	global $ds, $suffix, $ldapError;
	
	$host_array = get_host_ip($hostDN);
	$old_ip = $host_array['ipaddress'];  # oder IP aus dem Formular
	# print_r($host_array);printf("<br>");
	# printf($old_ip);
	$delentry ['ipaddress'] = $old_ip;
	if ( $host_array['dhcpoptfixed-address'] != "" ){
	   $delentry ['dhcpoptfixed-address'] = array();
	}
   # print_r($delentry);printf("<br>");
	
	$results = ldap_mod_del($ds,$hostDN,$delentry);
	if ($results){
		echo "<br>IP Adresse erfolgreich geloescht!<br>";	
		$modentry['FreeIPBlock'] = $old_ip;
   	$results = ldap_mod_add($ds,$auDN,$modentry); 
		if ($results){
			echo "<br>geloeschte IP Adresse erfolgreich als neuer FIPB in die AU eingetragen!<br>" ;
			merge_ipranges($auDN);
			return 1;
		}
		else{ 
			echo "<br>Fehler beim eintragen der geloeschten IP Adresse als neuen FIPB!<br>";
			return 0;
		}				
	}
	else{ 
		echo "<br>Fehler beim loeschen der IP Adresse!<br>";
   	return 0;
   }
}

/**
* delete_ip_dhcprange($dhcpobjectDN,$auDN)  
* Loescht die IP Range eines DHCP Subnets/Pools, und passt die FreeIPBlocks der AU an.
*
* @param string dhcpobjectDN Distinguished Name des LDAP DHCP-Objektes
* @param string auDN Distinguished Name des LDAP AU-Objektes
*
* @return boolean 1 bei Erfolg bzw. 0 bei Misserfolg
*
* @author Tarik Gasmi
*/
function delete_ip_dhcprange($dhcpobjectDN,$auDN)
{
	global $ds, $suffix, $ldapError;
	
	$dhcp_array = get_dhcp_range($dhcpobjectDN);
	
	if ( $dhcp_array['dhcprange'] != "" ){
   	$old_ip = $dhcp_array['dhcprange'];  # oder IP aus dem Formular besser da ja mehrere moeglich
   	# print_r($dhcp_array);printf("<br>");
   	# printf($old_ip);
   	$delentry['dhcpRange'] = $old_ip;
      # print_r($delentry);printf("<br>");
   	
   	$results = ldap_mod_del($ds,$dhcpobjectDN,$delentry);
   	if ($results){
   		echo "<br>DHCP IP Range erfolgreich geloescht!<br>";		
   		$modentry['FreeIPBlock'] = $old_ip;
      	$results = ldap_mod_add($ds,$auDN,$modentry); 
   		if ($results){
   			echo "<br>geloeschte IP Range erfolgreich als neuer FIPB in die AU eingetragen!<br>" ;
   			merge_ipranges($auDN);
   			return 1;
   		}
   		else{ 
   			echo "<br>Fehler beim eintragen der geloeschten IP Range als neuen FIPB!<br>";
   			# Transaktion simulieren und alte Range wieder eintragen ??
   			return 0;
   		}			
   	}
   	else{ 
   		echo "<br>Fehler beim loeschen der DHCP IP Range!<br>";
      	return 0;
      }
   }
}

/**
* modify_ip_host($ip,$hostDN,$auDN)  
* Aendert die IP Adresse eines Hosts, falls neue IP verfuegbar, und passt die FreeIPBlocks der AU an.
*
* @param string ip IP Adresse, die neu zugewiesen werden soll
* @param string hostDN Distinguished Name des LDAP Host-Objektes
* @param string auDN Distinguished Name des LDAP AU-Objektes
*
* @return boolean 1 bei Erfolg bzw. 0 bei Misserfolg
*
* @author Tarik Gasmi
*/
function modify_ip_host($ip,$hostDN,$auDN,$fixadd)
{
	global $ds, $suffix, $ldapError;
	
	if ( delete_ip_host($hostDN,$auDN) ){
		if ( new_ip_host($ip,$hostDN,$auDN) ){
			if ( $fixadd != ""){
				$fa_entry ['dhcpoptfixed-address'] = $fixadd;
				ldap_mod_add($ds,$hostDN,$fa_entry);
			}
			echo "<br>IP Adresse erfolgeich geaendert!<br>";
			return 1;
		}else{
			echo "<br>Fehler beim Aendern der IP Adresse!<br>";
			return 0;
		}
	}else{
		echo "<br>Fehler beim Aendern der IP Adresse!<br>";
		return 0;
	}
}

/**
* modify_ip_dhcprange($ip,$dhcpobjectDN,$auDN)  
* Aendert IP Range eines DHCP Subnet/Pool, falls neue Range verfuegbar ist,
* und passt die FreeIPBlocks der AU an.
*
* @param string ip IP Range, die neu zugewiesen werden soll
* @param string dhcpobjectDN Distinguished Name des LDAP DHCP-Objektes
* @param string auDN Distinguished Name des LDAP AU-Objektes
*
* @return boolean 1 bei Erfolg bzw. 0 bei Misserfolg
*
* @author Tarik Gasmi
*/
function modify_ip_dhcprange($ip,$dhcpobjectDN,$auDN)
{
	global $ds, $suffix, $ldapError;
	
	if ( delete_ip_dhcprange($dhcpobjectDN,$auDN) ){
		if ( new_ip_dhcprange($ip,$dhcpobjectDN,$auDN) ){
			echo "<br>DHCP IP Range erfolgeich geaendert!<br>";
			return 1;
		}else{
			echo "<br>Fehler beim Aendern der DHCP IP Range!<br>";
			return 0;
		}
	}else{
		echo "<br>Fehler beim Aendern der DHCP IP Range!<br>";
		return 0;
	}
}


/**
* new_ip_delegation($ip,$childauDN,$auDN)  
* Delegiert einen neuen IP Bereich an eine untergeordnete AU, falls dieser verfuegbar ist 
* (in den FreeIPBlocks enthalten ist), und passt die FreeIPBlocks der AU an.
*
* @param string ip IP Bereich, der zugewiesen werden soll
* @param string childauDN Distinguished Name des untergeordneten (Child) LDAP AU-Objektes
* @param string auDN Distinguished Name des LDAP AU-Objektes
*
* @return boolean 1 bei Erfolg bzw. 0 bei Misserfolg
*
* @author Tarik Gasmi
*/
function new_ip_delegation($ip,$childauDN,$auDN)
{
	global $ds, $suffix, $ldapError;
   
   $fipb_array = get_freeipblocks_au($auDN);
   #echo "<br>---<br>";print_r($fipb_array);echo "<br>---<br>";
	for ($i=0; $i < count($fipb_array); $i++){
		if ( split_iprange($ip,$fipb_array[$i]) != 0 ){
			$ipranges = split_iprange($ip,$fipb_array[$i]);
			array_splice($fipb_array, $i, 1, $ipranges);
			break;
		}		
	}
	
	if ($i < count($fipb_array) ){	
		# ldap_mod_replace -> Array fipb_array aktualisiert die FIPB in AU mit $auDN
		foreach ( $fipb_array as $item ){
		 	$entry ['FreeIPBlock'][] = $item;
		}
		 
		$results = ldap_mod_replace($ds,$auDN,$entry);
		if ($results){
			echo "<br>Neue FIPBs erfolgreich eingetragen!<br>" ;
			
			# ldap_mod_add -> IPAddress = $ip , in Host mit $hostDN 
			$mipbentry['MaxIPBlock'] = $ip;
			$mipbentry['FreeIPBlock'] = $ip;
			#print_r($mipbentry);
				
			$results = ldap_mod_add($ds,$childauDN,$mipbentry);
			if ($results){
				echo "<br>IP Adressblock erfolgreich delegiert!<br>" ;
				merge_ipranges($childauDN);
				return 1;
			}else{
				echo "<br>Fehler beim eintragen der IP Adresse!<br>";
				return 0;
			}
		}else{
			echo "<br>Fehler beim eintragen der FIPBs!<br>";
			return 0;
		}	  			    
	}
	else{
		printf("<br>Zu delegierende IP Range %s ist nicht im verfuegbaren Bereich!<br>", $ip );
	}	
}

/**
* delete_ip_delegation($oldmipb,$childauDN,$auDN)  
* Einen an eine untergeordnete AU delegierten IP Bereich zuruecknehmen. Diese Funktion wird rekursiv fuer
* alle weiter-delegierten Teilbereiche abgearbeitet. FreeIPBlocks der AU und Child-AU, sowie MaxIPBlocks
* der Child-AU werden angepasst.
*
* @param string oldmipb delegierter maximaler IP Bereich, der zurueckgenommen werden soll
* @param string childauDN Distinguished Name des untergeordneten (Child) LDAP AU-Objektes
* @param string auDN Distinguished Name des LDAP AU-Objektes
*
* @return boolean 1 bei Erfolg bzw. 0 bei Misserfolg
*
* @author Tarik Gasmi
*/
function delete_ip_delegation($oldmipb,$childauDN,$auDN)
{
	global $ds, $suffix, $ldapError;
	
	# Durch Reduzierung zu loeschende IP Ranges (Array)
   $delip[] = $oldmipb;
   #print_r($delip);printf("<br><br>");
   
   # Finde unter allen Child-AUs diejenigen, die von Reduzierung betroffene Child-Child-AUs haben 
	# Diese sind werden rekursiv abgearbeitet
   $cchild_array = get_childau($childauDN,array("dn","maxipblock"));
	# print_r($cchild_array);printf("<br><br>");
	$cchild_todo = array();
	foreach ($delip as $delipitem){
		foreach ($cchild_array as $item){
			if( count($item['maxipblock']) > 1 ){
				foreach ($item['maxipblock'] as $item2 ){
					if ( intersect_ipranges($delipitem,$item2) != false ){
						$cchild_todo[] = array('coldmipb' => $item2,
													'ccauDN' => $item['dn'],
													'childauDN' => $childauDN );
					}
				}
			}
			elseif ( count($item['maxipblock']) == 1 ){		
				if ( intersect_ipranges($delipitem,$item['maxipblock']) != false ){
					$cchild_todo[] = array('coldmipb' => $item['maxipblock'],
												'ccauDN' => $item['dn'],
												'childauDN' => $childauDN );
				}
			}
		}
	}	
	#print_r($cchild_todo);printf("<br><br>");
	
	###################
	# Rekursionsaufruf (für jede Child-AU, die betroffene Child-Child-AU hat)
	foreach ($cchild_todo as $item){
			delete_ip_delegation($item['coldmipb'],$item['ccauDN'],$item['childauDN']);
	}
	###################
	
	# Ab hier: alles was bei jedem Fkt.Aufruf zu machen ist (in Ebene AU und Child-AU) 
   
   # in CAU Check ob RechnerIPs oder DhcpIPs betroffen: 
   $del_objects = objects_to_delete($delip,$childauDN,$cchild_array);
   # print_r($del_objects);printf("<br><br>");
   if ( count($del_objects['hostips']) != 0 ){ 
	   printf("<br>Host IP Addresses that will be deleted: <br>");
   	foreach ($del_objects['hostips'] as $item){
   		printf("HostDN: %s &nbsp;&nbsp; IP Address: %s <br>",$item['dn'],$item['ip']);
   	}
   }
   if ( count($del_objects['dhcpranges']) != 0 ){ 
	   printf("<br>Subnet IP Ranges that will be adjusted: <br>");
	   foreach ($del_objects['dhcpranges'] as $item){
	   	printf("DhcpObjectDN: %s &nbsp;&nbsp; Zu loeschende IP Range: %s <br>",$item['dn'],$item['delrange']);
	   }
	}
   # hier kommte Abfrage ob wirklich Aenderung ausfuehren, ja dann weiter mit loeschen 
   # sonst Abbruch 
   # momentan: einfach loeschen
   if ( count($del_objects['hostips']) != 0 ){
	   foreach ($del_objects['hostips'] as $item){
	   	delete_ip_host($item['dn'],$item['auDN']);
	   }
   }
   if ( count($del_objects['dhcpranges']) != 0 ){ 
	   foreach ($del_objects['dhcpranges'] as $item){
			delete_ip_dhcprange($item['dn'],$item['auDN']);
	   } 
	}
   
   # in Child-AU: oldmipb loeschen 
   $mipb_array = get_maxipblocks_au($childauDN);
   #print_r($mipb_array);printf("<br><br>");
   foreach ($delip as $delipitem){
   	# if ( count($mipb_array) > 1 ){
   		for ($i=0; $i < count($mipb_array); $i++){
   			if ( intersect_ipranges($delipitem,$mipb_array[$i]) != 0 ){
				#$ipranges = intersect_ipranges($newmipb,$mipb_array[$i]);
				array_splice($mipb_array, $i, 1);
				}
			}
		# }else{
		# 	if ( intersect_ipranges($delipitem,$mipb_array) != 0 ){
		# 		# $ipranges = intersect_ipranges($newmipb,$mipb_array);
		# 		$mipb_array = array();
		# 	}
		# }		
	}
   # print_r($mipb_array);printf("<br><br>");
	# for ($i=0; $i < count($mipb_array); $i++){
   #	 if ($mipb_array[$i] == false){array_splice($mipb_array, $i, 1);}
   # }
   
   #print_r($mipb_array);printf("<br><br>");
   if (count($mipb_array) == 0){
   	$entry ['MaxIPBlock'] = array();
   	#print_r($entry);printf("<br><br>");
   	$results = ldap_mod_del($ds,$childauDN,$entry);	
   }else{
	   foreach ( $mipb_array as $item ){
		 	$entry ['MaxIPBlock'][] = $item;
	 	}
	 	#print_r($entry);printf("<br><br>");	
		$results = ldap_mod_replace($ds,$childauDN,$entry);
	}	  	
	
	if ($results){
		echo "<br>MIPBs in Child-AU erfolgreich geloescht!<br>" ;
		
		 # in Child-AU: FIPBs anpassen 
   	$fipb_array = get_freeipblocks_au($childauDN);
   	#print_r($fipb_array);printf("<br><br>"); 
   	foreach ($delip as $delipitem){
   		# if ( count($fipb_array) > 1 ){
			   for ($i=0; $i < count($fipb_array); $i++){
					if ( intersect_ipranges($delipitem,$fipb_array[$i]) != 0 ){
						# $ipranges = intersect_ipranges($newmipb,$fipb_array[$i]);
						array_splice($fipb_array, $i, 1);
					}		
				}
			# }
			# else{
			# 	if ( intersect_ipranges($delipitem,$fipb_array) != 0 ){
			# 		# $ipranges = intersect_ipranges($newmipb,$fipb_array);
			# 		$fipb_array = array();
			# 	}
			# }
   	}
   	# print_r($fipb_array);printf("<br><br>");
   	# for ($i=0; $i < count($fipb_array); $i++){
   	# 	if ($fipb_array[$i] == false){array_splice($fipb_array, $i, 1);}
   	# }
   	
   	#print_r($fipb_array);printf("<br><br>");
   	if (count($fipb_array) == 0){
   		$entry1 ['FreeIPBlock'] = array();
   		#print_r($entry1);printf("<br><br>");
  			$results = ldap_mod_del($ds,$childauDN,$entry1);		
   	}else{
			foreach ( $fipb_array as $item ){
			 	$entry1 ['FreeIPBlock'][] = $item;
			}
			#print_r($entry1);printf("<br><br>");	
			$results = ldap_mod_replace($ds,$childauDN,$entry1);
		}
		
		if ($results){
			echo "FIPBs in Child-AU erfolgreich geloescht!<br>" ;
			
			# in AU: Geloeschte IP Bereiche als neue FIPBs aufnehmen
   		foreach ($delip as $item){
		   	$entry2 ['FreeIPBlock'][] = $item;
   		}
   		#print_r($entry2);printf("<br><br>");
   		$results = ldap_mod_add($ds,$auDN,$entry2);
			if ($results){
				echo "FIPBs in AU erfolgreich aktualisiert!<br>" ;
				
				# IP Bloecke aufraeumen in Child-AU und AU (Merging) 	
				merge_ipranges($auDN);
				merge_ipranges($childauDN);
				return 1;
			}else{
				echo "Fehler beim aktualisieren der FIPBs in AU!<br>";
				return 0;
			}
		}else{
			echo "Fehler beim loeschen der FIPBs in Child-AU!<br>";
			return 0;
		}			
	}else{
		echo "<br>Fehler beim loeschen der MIPBs in Child-AU!<br>";
		return 0;	
   }   
}


/**
* reduce_ip_delegation($oldmipb,$newmipb,$childauDN,$auDN)  
* Einen an eine untergeordnete AU delegierten IP Bereich verkleinern. Diese Funktion wird rekursiv fuer
* alle weiter-delegierten Teilbereiche abgearbeitet. FreeIPBlocks der AU und Child-AU, sowie MaxIPBlocks
* der Child-AU werden angepasst.
*
* @param string oldmipb delegierter maximaler IP Bereich, der verkleinert werden soll
* @param string newmipb delegierter maximaler IP Bereich nach der Verkleinerung
* @param string childauDN Distinguished Name des untergeordneten (Child) LDAP AU-Objektes
* @param string auDN Distinguished Name des LDAP AU-Objektes
*
* @return boolean 1 bei Erfolg bzw. 0 bei Misserfolg
*
* @author Tarik Gasmi
*/
function reduce_ip_delegation($oldmipb,$newmipb,$childauDN,$auDN)
{
	global $ds, $suffix, $ldapError;
	
	# Durch Reduzierung zu loeschende IP Ranges (Array)
   $delip = split_iprange($newmipb,$oldmipb);
   #print_r($delip);printf("<br><br>");
	
	# Finde unter allen Child-AUs diejenigen, die von Reduzierung betroffene Child-Child-AUs haben 
	# Diese sind werden rekursiv abgearbeitet
   $cchild_array = get_childau($childauDN,array("dn","maxipblock"));
	
	$cchild_todo = array();
	foreach ($delip as $delipitem){
		foreach ($cchild_array as $item){
			if( count($item['maxipblock']) > 1 ){
				foreach ($item['maxipblock'] as $item2 ){
					if ( intersect_ipranges($delipitem,$item2) != false ){
						$cchild_todo[] = array('coldmipb' => $item2,
													'cnewmipb' => intersect_ipranges($newmipb,$item2),
													'ccauDN' => $item['dn'],
													'childauDN' => $childauDN );
					}
				}
			}
			elseif ( count($item['maxipblock']) == 1 ){		
				if ( intersect_ipranges($delipitem,$item['maxipblock']) != false ){
					$cchild_todo[] = array('coldmipb' => $item['maxipblock'],
												'cnewmipb' => intersect_ipranges($newmipb,$item['maxipblock']),
												'ccauDN' => $item['dn'],
												'childauDN' => $childauDN );
				}
			}
		}
	}	
	#print_r($cchild_todo);printf("<br><br>");
	
	######################
	# Rekursionsaufruf (für jede Child-AU, die betroffene Child-Child-AU hat)
	foreach ($cchild_todo as $item){
		if ($item['cnewmipb'] == false ){
			delete_ip_delegation($item['coldmipb'],$item['ccauDN'],$item['childauDN']);
		}
		else{
		   reduce_ip_delegation($item['coldmipb'],$item['cnewmipb'],$item['ccauDN'],$item['childauDN']);
		}
	}
	######################
	 
   
   # Ab hier: alles was bei jedem Fkt.Aufruf zu machen ist (auf Ebene AU und Child-AU) 
   
   # in CAU Check ob RechnerIPs oder DhcpIPs betroffen: 
   # - falls ja: nochmals Abfrage (Hammermethode: diese auch loeschen) ob diese zu loeschen sind
   #   -> ja, betreffende IPs loeschen
   #   -> nein, Abbruch.
   # - falls nein: fuer jedes FIPB in CAU intersect(FIPB,newmipb)-> Schnittmengen bilden die neuen FIPB
   $del_objects = objects_to_adjust($newmipb,$delip,$childauDN,$cchild_array);
   # print_r($del_objects);printf("<br><br>");
	if ( count($del_objects['hostips']) != 0 ){   
	   printf("<br>Host IP Addresses that will be deleted: <br>");
	   foreach ($del_objects['hostips'] as $item){
	   	printf("HostDN: %s &nbsp;&nbsp; IP Address: %s <br>",$item['dn'],$item['ip']);
	   }
   }
   if ( count($del_objects['dhcpranges']) != 0 ){
	   printf("<br>Subnet IP Ranges that will be adjusted: <br>");
	   foreach ($del_objects['dhcpranges'] as $item){
	   	printf("DhcpObjectDN: %s &nbsp;&nbsp; New IP Range: %s <br>",$item['dn'],$item['newrange']);
	   }
   }

   # momentan wird einfach geloescht:
   if ( count($del_objects['hostips']) != 0 ){
	   foreach ($del_objects['hostips'] as $item){
	   	delete_ip_host($item['dn'],$item['auDN']);
	   }
	}
   if ( count($del_objects['dhcpranges']) != 0 ){
	   foreach ($del_objects['dhcpranges'] as $item){
	   	if ( count($item['newrange']) >= 1 ){
				modify_ip_dhcprange($item['newrange'],$item['dn'],$item['auDN']);
			}else{
				delete_ip_dhcprange($item['dn'],$item['auDN']);
			}
	   } 
   }
   
   # in Child-AU: oldmipb -> newmipb
   $mipb_array = get_maxipblocks_au($childauDN);
   # print_r($mipb_array);printf("<br><br>");
   foreach ($delip as $delipitem){
   	for ($i=0; $i < count($mipb_array); $i++){
   		if ( intersect_ipranges($delipitem,$mipb_array[$i]) != 0 ){
			$ipranges = intersect_ipranges($newmipb,$mipb_array[$i]);
			array_splice($mipb_array, $i, 1, $ipranges);
			}
		}
	}
   # print_r($mipb_array);printf("<br><br>");
	for ($i=0; $i < count($mipb_array); $i++){
   	if ($mipb_array[$i] == false){array_splice($mipb_array, $i, 1);}
   }
   #print_r($mipb_array);printf("<br><br>");
   if (count($mipb_array) == 0){
   	$entry ['MaxIPBlock'] = array();
   	#print_r($entry);printf("<br><br>");
   	$results = ldap_mod_del($ds,$childauDN,$entry);
   }else{
	   foreach ( $mipb_array as $item ){
		 	$entry ['MaxIPBlock'][] = $item;
	 	}
	 	#print_r($entry);printf("<br><br>");	
		$results = ldap_mod_replace($ds,$childauDN,$entry);
	}
	
	if ($results){
		echo "<br>MIPBs in Child-AU erfolgreich aktualisiert!<br>" ;
	
		# in Child-AU: FIPBs anpassen 
   	$fipb_array = get_freeipblocks_au($childauDN);
   	#print_r($fipb_array);printf("<br><br>"); 
   	foreach ($delip as $delipitem){
		   for ($i=0; $i < count($fipb_array); $i++){
				if ( intersect_ipranges($delipitem,$fipb_array[$i]) != 0 ){
					$ipranges = intersect_ipranges($newmipb,$fipb_array[$i]);
					array_splice($fipb_array, $i, 1, $ipranges);
				}		
			}
   	}
   	# print_r($fipb_array);printf("<br><br>");
   	for ($i=0; $i < count($fipb_array); $i++){
   		if ($fipb_array[$i] == false){array_splice($fipb_array, $i, 1);}
   	}
   	#print_r($fipb_array);printf("<br><br>");   
		if (count($fipb_array) == 0){
   		$entry1 ['FreeIPBlock'] = array();
   		#print_r($entry1);printf("<br><br>");
  			$results = ldap_mod_del($ds,$childauDN,$entry1);
   	}else{
			foreach ( $fipb_array as $item ){
			 	$entry1 ['FreeIPBlock'][] = $item;
			}
			#print_r($entry1);printf("<br><br>");
			$results = ldap_mod_replace($ds,$childauDN,$entry1);		
		}

		if ($results){
			echo "FIPBs in Child-AU erfolgreich aktualisiert!<br>" ;
			
			# in AU: Geloeschte IP Bereiche als neue FIPBs aufnehmen
   		foreach ($delip as $item){
	   		$entry2 ['FreeIPBlock'][] = $item;
   		}
   		#print_r($entry2);printf("<br><br>");
   		$results = ldap_mod_add($ds,$auDN,$entry2);
			if ($results){
				echo "FIPBs in AU erfolgreich aktualisiert!<br>" ;
				
				# IP Bloecke aufraeumen in Child-AU und AU (Merging) 	
				merge_ipranges($auDN);
				merge_ipranges($childauDN);
				
				return 1;
			}else{
				echo "Fehler beim aktualisieren der FIPBs in AU!<br>";
				return 0;
			}	
		}else{
			echo "Fehler beim aktualisieren der FIPBs in Child-AU!<br>";
			return 0;
		}		
	}else{
		echo "<br>Fehler beim aktualisieren der MIPBs in Child-AU!<br>";
		return 0;
	}	  	
}


/**
* expand_ip_delegation($oldmipb,$newmipb,$childauDN,$auDN)  
* Einen an eine untergeordnete AU delegierten IP Bereich erweitern. Diese Funktion wird rekursiv fuer
* alle weiter-delegierten Teilbereiche abgearbeitet. FreeIPBlocks der AU und Child-AU, sowie MaxIPBlocks
* der Child-AU werden angepasst. Entspricht einer Neu-Delegierung des erweiterten IP Bereichs.
*
* @param string oldmipb delegierter maximaler IP Bereich, der erweitert werden soll
* @param string newmipb delegierter maximaler IP Bereich nach der Erweiterung
* @param string childauDN Distinguished Name des untergeordneten (Child) LDAP AU-Objektes
* @param string auDN Distinguished Name des LDAP AU-Objektes
*
* @return boolean 1 bei Erfolg bzw. 0 bei Misserfolg
*
* @author Tarik Gasmi
*/
function expand_ip_delegation($oldmipb,$newmipb,$childauDN,$auDN)
{
	global $ds, $suffix, $ldapError;
	
	$difference = split_iprange($oldmipb,$newmipb);
	if ( new_ip_delegation($difference[0],$childauDN,$auDN) ){
		return 1;
	}else{
		return 0;
	}
}


/**
* objects_to_delete($delip,$childauDN,$cchild_array)  
* Liefert die durch eine Rücknahme einer IP Delegierung betroffenen Host/DHCP-Objekte der Child-AU
* und Child-Child-AUs in einem Array. Dieses enthaelt fuer jedes Objekt dessen Distinguished Name,
* dessen IP Adresse(n)/Range(s) und den Distinguished Name der AU der das Objekt angehoert. Parameter 
* die fuer die Funktionen delete_ip_host(), delete_ip_range() Benoetigt werden.
*
* @param string delip IP Bereich der geloescht wird
* @param string childauDN Distinguished Name des untergeordneten (Child) LDAP AU-Objektes
* @param array cchild_array Array von allen Child-Child-AUs (jedes Item enthaelt DN und MaxIPBlock)
*
* @return array objects_to_delete Array aller betroffenen Objekte (DN, IP, auDN)
*
* @author Tarik Gasmi
*/
function objects_to_delete($delip,$childauDN,$cchild_array)
{
	global $ds, $suffix, $ldapError;
	
	# Hosts von child-AU, child-child-AU
	$chosts = get_hosts($childauDN,array("dn","ipaddress"));
   # print_r($chosts);printf("<br><br>");
   $cchosts = array();
   foreach ($cchild_array as $item){
   	$cchostsitem = get_hosts($item['dn'],array("dn","ipaddress"));
   	foreach ($cchostsitem as $item2){
   	  	$cchosts[] = $item2;
   	}
   }
   $chosts = array_merge($chosts,$cchosts);
   # print_r($chosts);printf("<br><br>");
   
   # Pools von child-AU, child-child-AU
   $csubnets = get_dhcppools($childauDN,array("dn","dhcprange"));
   # print_r($csubnets);printf("<br><br>");
   $ccsubnets = array();
   foreach ($cchild_array as $item){
   	$ccsubnetsitem = get_hosts($item['dn'],array("dn","dhcprange"));
   	foreach ($ccsubnetsitem as $item2){
   	  	$ccsubnets[] = $item2;
   	}
   }
   $csubnets = array_merge($csubnets,$ccsubnets);
   # print_r($csubnets);printf("<br><br>");
   
   
   # Zu loeschende Hosts bestimmen
   $chosts_todo = array();
	foreach ($delip as $delipitem){
		if ( count($chosts) != 0 ){
			foreach ($chosts as $item){
				if( count($item['ipaddress']) > 1 ){
					foreach ($item['ipaddress'] as $item2 ){
						if ( intersect_ipranges($delipitem,$item2) != false ){
							$chosts_todo[] = array('dn' => $item['dn'],
															'ip' => $item['ipaddress'],
															'auDN' => $item['auDN']);
						}
					}
				}
				elseif ( count($item['ipaddress']) == 1 ){		
					if ( intersect_ipranges($delipitem,$item['ipaddress']) != false ){
						$chosts_todo[] = array('dn' => $item['dn'],
														'ip' => $item['ipaddress'],
														'auDN' => $item['auDN']);
					}
				}
			}
		}
	}
   # print_r($chosts_todo);printf("<br><br>");
   
   # Zu loeschende Pools bestimmen, und wie IP Range anzupassen ist
   $csubnets_todo = array();
	foreach ($delip as $delipitem){
		if ( count($csubnets) != 0 ){
			foreach ($csubnets as $item){
				if( count($item['dhcprange']) > 1 ){
					foreach ($item['dhcprange'] as $item2 ){
						# print_r(intersect_ipranges($delipitem,$item2));
						if ( intersect_ipranges($delipitem,$item2) != false ){
							$csubnets_todo[] = array('dn'=> $item['dn'],
															'delrange' => $item2['dhcprange'],
															'auDN' => $item['auDN']);
						}
					}
				}
				elseif ( count($item['dhcprange']) == 1 ){		
					# print_r(intersect_ipranges($delipitem,$item['dhcprange']));
					if ( intersect_ipranges($delipitem,$item['dhcprange']) != false ){
						$csubnets_todo[] = array('dn'=> $item['dn'],
	 													'delrange' => $item['dhcprange'],
	 													'auDN' => $item['auDN']);
					}
				}
			}
		}
	}
   # print_r($csubnets_todo);printf("<br><br>");
    
   $objects_to_delete = array('hostips' => $chosts_todo,
   									'dhcpranges' => $csubnets_todo);
   return $objects_to_delete;
}


/**
* objects_to_adjust($newmipb,$delip,$childauDN,$cchild_array)  
* Liefert die durch eine Reduzierung einer IP Delegierung betroffenen Host/DHCP-Objekte der Child-AU
* und Child-Child-AUs in einem Array. Dieses enthaelt fuer jedes Objekt dessen Distinguished Name,
* dessen IP Adresse(n)/Range(s) und den Distinguished Name der AU der das Objekt angehoert. Parameter 
* die fuer die Funktionen delete_ip_host(), delete_ip_dhcprange(), modify_ip_dhcprange() benoetigt werden.
*
* @param string newmipb IP Bereich der nach Reduzierung verbleibt
* @param string delip IP Bereich der durch Reduzierung wegfaellt
* @param string childauDN Distinguished Name des untergeordneten (Child) LDAP AU-Objektes
* @param array cchild_array Array von allen Child-Child-AUs (jedes Item enthaelt DN und MaxIPBlock)
*
* @return array objects_to_adjust Array aller betroffenen Objekte (DN, IP, auDN)
*
* @author Tarik Gasmi
*/
function objects_to_adjust($newmipb,$delip,$childauDN,$cchild_array)
{
	global $ds, $suffix, $ldapError;
	
	# Hosts von child-AU, child-child-AU
	$chosts = get_hosts($childauDN,array("dn","ipaddress"));
   # print_r($chosts);printf("<br><br>");
   $cchosts = array();
   foreach ($cchild_array as $item){
   	$cchostsitem = get_hosts($item['dn'],array("dn","ipaddress"));
   	foreach ($cchostsitem as $item2){
   	  	$cchosts[] = $item2;
   	}
   }
   $chosts = array_merge($chosts,$cchosts);
   # print_r($chosts);printf("<br><br>");
   
   # Pools von child-AU, child-child-AU
   $csubnets = get_dhcppools($childauDN,array("dn","dhcprange"));
   # print_r($csubnets);printf("<br><br>");
   $ccsubnets = array();
   foreach ($cchild_array as $item){
   	$ccsubnetsitem = get_hosts($item['dn'],array("dn","dhcprange"));
   	foreach ($ccsubnetsitem as $item2){
   	  	$ccsubnets[] = $item2;
   	}
   }
   $csubnets = array_merge($csubnets,$ccsubnets);
   # print_r($csubnets);printf("<br><br>");
   
   
   # Zu loeschende Hosts bestimmen
   $chosts_todo = array();
	foreach ($delip as $delipitem){
		if ( count($chosts) != 0 ){
			foreach ($chosts as $item){
				if( count($item['ipaddress']) > 1 ){
					foreach ($item['ipaddress'] as $item2 ){
						if ( intersect_ipranges($delipitem,$item2) != false ){
							$chosts_todo[] = array('dn' => $item['dn'],
															'ip' => $item['ipaddress'],
															'auDN' => $item['auDN']);
						}
					}
				}
				elseif ( count($item['ipaddress']) == 1 ){		
					if ( intersect_ipranges($delipitem,$item['ipaddress']) != false ){
						$chosts_todo[] = array('dn' => $item['dn'],
														'ip' => $item['ipaddress'],
														'auDN' => $item['auDN']);
					}
				}
			}
		}
	}
   # print_r($chosts_todo);printf("<br><br>");
   
   # Zu loeschende Subnets bestimmen, und wie IP Range anzupassen ist
   $csubnets_todo = array();
	foreach ($delip as $delipitem){
		if ( count($csubnets) != 0 ){
			foreach ($csubnets as $item){
				if( count($item['dhcprange']) > 1 ){
					foreach ($item['dhcprange'] as $item2 ){
						# print_r(intersect_ipranges($delipitem,$item2));
						if ( intersect_ipranges($delipitem,$item2) != false ){
							$csubnets_todo[] = array('dn'=> $item['dn'],
															'newrange' => intersect_ipranges($newmipb,$item2),
															'auDN' => $item['auDN']);
						}
					}
				}
				elseif ( count($item['dhcprange']) == 1 ){		
					# print_r(intersect_ipranges($delipitem,$item['dhcprange']));
					if ( intersect_ipranges($delipitem,$item['dhcprange']) != false ){
						$csubnets_todo[] = array('dn'=> $item['dn'],
	 													'newrange' => intersect_ipranges($newmipb,$item['dhcprange']),
	 													'auDN' => $item['auDN']);
					}
				}
			}
		}
	}
   # print_r($csubnets_todo);printf("<br><br>");
   
    
   $objects_to_adjust = array('hostips' => $chosts_todo,
   									'dhcpranges' => $csubnets_todo);
   return $objects_to_adjust;
}


?>