<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcppool.dwt";

include('dhcp_header.inc.php');

$mnr = 3; 
$sbmnr = -1;

###################################################################################

$mnr = $_GET['mnr'];
$sbmnr = $_GET['sbmnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

# DHCP Pools Daten holen						
$attributes = array("dn","cn","dhcphlpcont","dhcprange","description","dhcpstatements","dhcpoptallow",
							"dhcpoptdefault-lease-time","dhcpoptdeny","dhcpoptignore","dhcpoptmax-lease-time",
							"dhcpoptgeneric");
$pools = get_dhcppools($auDN, $attributes);
#print_r($pools);
if (count($pools) == 0){
	redirect(0, "dhcpnopool.php?mnr=".$mnr, "", $addSessionId = TRUE);
	die;
}

$template->assign(array("POOLDN" => "",
								"CN" => "",
								"SUBNETDN" => "",
								"SUBNET" => "",
								"RANGE1" => "",
								"RANGE2" => "",
								"DESCRIPTION" => "",
								"STATEMENTS" => "",
								"ALLOW" => "",
								"DENY" => "",
								"IGNORE" => "",
								"DEFAULTLEASE" => "",
								"MAXLEASE" => "",
           		       	"MNR" => $mnr));


$template->define_dynamic("Dhcppools", "Webseite");
$template->define_dynamic("Dhcpranges", "Webseite");

# Für jeden Pool ...
foreach ($pools as $pool){
	
   # DHCP Subnet des Pools 
   $subnet = ldap_explode_dn($pool['dhcphlpcont'],1);
	$subnetdnexp = ldap_explode_dn( $pool['dhcphlpcont'], 0);
	$subnetauexp = array_slice($subnetdnexp, 3);
	$subnetau = implode(',',$subnetauexp);	
	
	
   $template->clear_parse("DHCPRANGES_LIST");
   
   # DHCP Ranges
   if (count($pool['dhcprange']) != 0){
      #$template->define_dynamic("Dhcpranges", "Webseite");
      if (count($pool['dhcprange']) > 1){
   	foreach ($pool['dhcprange'] as $dhcprange){
   	   $iprange = explode('_',$dhcprange);
   		$template->assign(array(
   								"RANGE1" => $iprange[0],
   								"RANGE2" => $iprange[1],
                           "RPOOLDN" => $pool['dn']));
      	$template->parse("DHCPRANGES_LIST", ".Dhcpranges");
         $template->clear_dynamic("Dhcpranges");
   	}
   	}else{
   	   $iprange = explode('_',$pool['dhcprange']);
   	   $template->assign(array(
   								"RANGE1" => $iprange[0],
   								"RANGE2" => $iprange[1],
   								"RPOOLDN" => $pool['dn']));
      	$template->parse("DHCPRANGES_LIST", ".Dhcpranges");
         $template->clear_dynamic("Dhcpranges");	
   	}
   }
   
   # Unknown-Clients
   if ($pool['dhcpoptallow'] == "unknown-clients"){
      $unknownclients = "allow";
      $ucselectbox = "<option selected value='allow'> ALLOW </option>
                        <option value='deny'> DENY </option>
                        <option value='ignore'> IGNORE </option>";
   }
   elseif ($pool['dhcpoptignore'] == "unknown-clients") {
      $unknownclients = "ignore";
      $ucselectbox = "<option selected value='ignore'> IGNORE </option>
                        <option value='allow'> ALLOW </option>
                        <option value='deny'> DENY </option>";
   }
   else{
      $unknownclients = "deny";
      $ucselectbox = "<option selected value='deny'> DENY </option>
                        <option value='allow'> ALLOW </option>
                        <option value='ignore'> IGNORE </option>";
   }  
   
   $template->assign(array("POOLDN" => $pool['dn'],
   								"CN" => $pool['cn'],
   								"SUBNETDN" => $pool['dhcphlpcont'],
   								"SUBNET" => $subnet[0],
   								"SUBNETAU" => $subnetau,
   								"DESCRIPTION" => $pool['description'],
   								"STATEMENTS" => $pool['dhcpstatements'],
   								"UCSELECT" => $ucselectbox,
   								"UCNOW" => $unknownclients,
   								"ALLOW" => $pool['dhcpoptallow'],
   								"DENY" => $pool['dhcpoptdeny'],
   								"IGNORE" => $pool['dhcpoptignore'],
   								"DEFAULTLEASE" => $pool['dhcpoptdefault-lease-time'],
   								"MAXLEASE" => $pool['dhcpoptmax-lease-time'],
              		       	"MNR" => $mnr));
   $template->parse("DHCPPOOLS_LIST", ".Dhcppools");

}

###################################################################################

include("dhcp_footer.inc.php");

?>