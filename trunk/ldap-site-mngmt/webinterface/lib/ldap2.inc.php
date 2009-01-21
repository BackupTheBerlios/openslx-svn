<?php
/**
* ldap2.inc.php - LDAP-Bibliothek
* Diese Bibliothek enthält weitere LDAP Hilfs-Funktionen
*
* @param string ldapError
* @param resource ds
*
* @author Tarik Gasmi
* @copyright Tarik Gasmi
*/
//Konfiguration laden
require_once("config.inc.php");

$ldapError = null;


# Liefert Array aller Child-Knoten mit bestimmten ausgwählten Attributen
function get_childs($baseDN,$attributes)
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $baseDN, "(objectclass=*)", $attributes, "", "list", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";  
  		die;
	} 
	else {
		$result = ldapArraySauber($result); 
	
		$childau_array = array();
   	foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$childau_array[] = $atts;
   	} 
		if($attributes != false ){return $childau_array;}
		else{return $result;}
   }
} 

# Liefert die RDNs aller Child-Knoten
function get_childs_rdn($baseDN){

	$childs = get_childs($baseDN,array("dn"));
	# print_r($childs); echo "<br><br>";

	$childs_rdn = array();
	foreach ($childs as $item){
		$exp = explode(',',$item['dn']);
		$rdn = $exp[0];
		$childs_rdn[] = $rdn;
	}

	# print_r($childs_rdn);
	return $childs_rdn;
}


# Attribute eines Knotens (Vorsicht Array enthält noch DN und COUNT)
# in einem Array wie er z.B. von ldap_add verwendet wird
function get_node_attributes($nodeDN){
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $nodeDN, "(objectclass=*)", array(), "", "one", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";  
  		die;
	}
	$result = ldapArraySauber($result); 
	# print_r($result);
	foreach ($result as $item){
		foreach (array_keys($item) as $merkmal)
		$attrs[$merkmal] = $item[$merkmal];
	} 
	return $attrs;
}

# Rekursives Kopieren
function dive_into_tree_cp($baseDN,$new_baseDN){

 	global $ds, $suffix, $ldapError;
  
  	$expldn = ldap_explode_dn($new_baseDN,0);
  	$new_node_rdn = $expldn[0];
	$exp = explode('=',$new_node_rdn);
	$new_node_rdn_merk = $exp[0];
	$new_node_rdn_val = $exp[1];
	$new_node_rdn_merk = strtolower($new_node_rdn_merk);
		
  	$childs_rdn = get_childs_rdn($baseDN);
 	
  	$attrs = get_node_attributes($baseDN);
  	# print_r($attrs); echo "<br>";
  	unset($attrs['dn']);
  	unset($attrs['count']);
  	$attrs["$new_node_rdn_merk"] = $new_node_rdn_val; 
  	# print_r($attrs); echo "<br>";
  	
  	$result = ldap_add($ds,$new_baseDN,$attrs);
	

  	//recursivly do dive for each child
  	foreach($childs_rdn as $rdn){
  		dive_into_tree_cp( $rdn.",".$baseDN , $rdn.",".$new_baseDN);
  	}
   return $result;
}


# 
# Rekursives Loeschen
function dive_into_tree_del($baseDN,$except){

  global $ds, $suffix, $ldapError;
  
  $childs_rdn = get_childs_rdn($baseDN);
  //recursivly do dive for each child
  foreach($childs_rdn as $rdn){
  		dive_into_tree_del( $rdn.",".$baseDN , $except);
  	}
  if($baseDN != $except){
    $result = ldap_delete($ds,$baseDN);
  }
  
  return $result;
}

# Rekursives Verschieben
function move_subtree($oldDN,$newDN){

  if(dive_into_tree_cp($oldDN,$newDN))
  {
    dive_into_tree_del($oldDN,"");
    echo "Moved subtree<br>";
    return 1;
  }
  else echo "Moving subtree not possible!!!<br>";
}


function adjust_dn_entries($oldDN,$newDN){

	global $ds, $suffix, $ldapError;
	
	# single Attributes:
	if(!($result = uniLdapSearch($ds, $newDN, "(objectclass=host)", array("dn","dhcphlpcont"), "", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}
	$result = ldapArraySauber($result);
	#print_r($result); echo "<br><br>";
	foreach ($result as $item){
		if (strpos($item['dhcphlpcont'],$oldDN) != false){
			$newvalue = str_replace($oldDN,$newDN,$item['dhcphlpcont']);
			$entry['dhcphlpcont'] = $newvalue;
			ldap_mod_replace($ds,$item['dn'],$entry);
		}
	}
	
	if(!($result = uniLdapSearch($ds, $newDN, "(objectclass=PXEConfig)", array("dn","rbservicedn"), "", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}
	$result = ldapArraySauber($result);
	#print_r($result); echo "<br><br>";
	foreach ($result as $item2){
		if (strpos($item2['rbservicedn'],$oldDN) != false){
			$newvalue = str_replace($oldDN,$newDN,$item2['rbservicedn']);
			$entry2['rbservicedn'] = $newvalue;
			ldap_mod_replace($ds,$item2['dn'],$entry2);
		}
	}
	
	if(!($result = uniLdapSearch($ds, $newDN, "(objectclass=dhcpService)", array("dn","dhcpprimarydn","dhcpsecondarydn"), "", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}
	$result = ldapArraySauber($result);
	#print_r($result); echo "<br><br>";
	foreach ($result as $item3){
		if (strpos($item3['dhcpprimarydn'],$oldDN) != false){
			$newvalue = str_replace($oldDN,$newDN,$item3['dhcpprimarydn']);
			$entry3['dhcpprimarydn'] = $newvalue;
			ldap_mod_replace($ds,$item3['dn'],$entry3);
		}
		if (strpos($item3['dhcpsecondarydn'],$oldDN) != false){
			$newvalue = str_replace($oldDN,$newDN,$item3['dhcpsecondarydn']);
			$entry4['dhcpsecondarydn'] = $newvalue;
			ldap_mod_replace($ds,$item3['dn'],$entry4);
		}
	}
	
	if(!($result = uniLdapSearch($ds, $newDN, "(objectclass=MenuEntry)", array("dn","genericmenuentrydn","ldapuri"), "", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}
	$result = ldapArraySauber($result);
	#print_r($result); echo "<br><br>";
	foreach ($result as $item4){
		if (strpos($item4['genericmenuentrydn'],$oldDN) != false){
			$newvalue = str_replace($oldDN,$newDN,$item4['genericmenuentrydn']);
			$entry5['genericmenuentrydn'] = $newvalue;
			ldap_mod_replace($ds,$item4['dn'],$entry5);
		}
		if (strpos($item4['ldapuri'],$oldDN) != false){
			$newvalue = str_replace($oldDN,$newDN,$item4['ldapuri']);
			$entry6['ldapuri'] = $newvalue;
			ldap_mod_replace($ds,$item4['dn'],$entry6);
		}
	}
	
	# Multi-Attribut member
	if(!($result = uniLdapSearch($ds, $newDN, "(objectclass=groupOfComputers)", array("dn","member","dhcphlpcont"), "", "sub", 0, 0))) {
 			# redirect(5, "", $ldapError, FALSE);
  			echo "no search"; 
  			die;
	}
	$result = ldapArraySauber($result);
	#print_r($result); echo "<br><br>";
	foreach ($result as $item5){
		for ($i=0; $i<count($item5['member']); $i++){
			if (strpos($item5['member'][$i],$oldDN) != false){
				$newvalue = str_replace($oldDN,$newDN,$item5['member'][$i]);
				$entry7['member'][$i] = $newvalue;
			}else{
				$entry7['member'][$i] = $item5['member'][$i];
			}
			ldap_mod_replace($ds,$item5['dn'],$entry7);
		}
		if (strpos($item5['dhcphlpcont'],$oldDN) != false){
			$newvalue = str_replace($oldDN,$newDN,$item5['dhcphlpcont']);
			$entry8['dhcphlpcont'] = $newvalue;
			ldap_mod_replace($ds,$item5['dn'],$entry8);
		}
		
	}
	
	# Attribut AssociatedName in DNS Teilbaum
	if(!($result = uniLdapSearch($ds, "ou=DNS,".$suffix , "(associatedname=$oldDN)", array("dn","associatedname"), "", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}
	$result = ldapArraySauber($result);
	#print_r($result); echo "<br><br>";
	foreach ($result as $item6){
		$newvalue = str_replace($oldDN,$newDN,$item6['associatedname']);
		$entry9['associatedname'] = $newvalue;
		ldap_mod_replace($ds,$item6['dn'],$entry9);
	}
	
	# Attribut RelativeDomainName in DNS Teilbaum ... noch nicht fertig
	$hostdnexpold = ldap_explode_dn($oldDN, 0);
	$hostdnexpnew = ldap_explode_dn($newDN, 0);
	$oldhostname = $hostdnexpold[0]; 
	$newhostname = $hostdnexpnew[0];
	if(!($result = uniLdapSearch($ds, "ou=DNS,".$suffix , "(relativedomainname=$oldhostname)", array("dn","relativedomainname"), "", "sub", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search"; 
  		die;
	}
	$result = ldapArraySauber($result);
	#print_r($result); echo "<br><br>";
	foreach ($result as $item7){
		$newvalue = str_replace($oldhostname,$newhostname,$item7['relativedomainname']);
		$entry10['relativedomainname'] = $newvalue;
		ldap_mod_replace($ds,$item7['dn'],$entry10);
	}

}



function check_for_dc($dn, $dc){
	global $ds, $suffix, $ldapError;
	if(!($result = uniLdapSearch($ds, $dn, "(dc=$dc)", array("dc"), "", "list", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";  
  		die;
	}
	$result = ldapArraySauber($result);
	if (count($result[0]['dc']) == 0 ) {return 0;}
	elseif ($result[0]['dc'] == $dc){return 1;}
}


function get_dc_childs($baseDN,$attributes)
{
	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $baseDN, "(objectclass=dnsdomain)", $attributes, "", "list", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";  
  		die;
	} 
	else {
		$result = ldapArraySauber($result); 
	
		$childau_array = array();
   	foreach ($result as $item){
			foreach ($attributes as $att){
   			$atts[$att] = $item[$att];
   		}
   		$childau_array[] = $atts;
   	} 
		if($attributes != false ){return $childau_array;}
		else{return $result;}
   }
} 

# Liefert die RDNs aller dc-Child-Knoten
function get_dc_childs_rdn($baseDN){
	
	global $ds, $suffix, $ldapError;
	
	$childs = get_dc_childs($baseDN,array("dn"));
	# print_r($childs); echo "<br><br>";

	$childs_rdn = array();
	foreach ($childs as $item){
		$exp = explode(',',$item['dn']);
		$rdn = $exp[0];
		$childs_rdn[] = $rdn;
	}

	# print_r($childs_rdn);
	return $childs_rdn;
}

function get_entry_number($entryDN,$entryobjectclass){

	global $ds, $suffix, $ldapError;
	
	if(!($result = uniLdapSearch($ds, $entryDN, "(objectclass=machineconfig)", array("count"), "", "one", 0, 0))) {
 		# redirect(5, "", $ldapError, FALSE);
  		echo "no search";  
  		die;
	}
	$result = ldapArraySauber($result); 
	print_r ($result);

}

?>