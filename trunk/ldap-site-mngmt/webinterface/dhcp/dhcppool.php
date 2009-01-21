<?php
include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "DHCP Service Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 5;
$mnr = 3; 
$sbmnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcppool.dwt";

include("../class.FastTemplate.php");

include('dhcp_header.inc.php');


###################################################################################

$mnr = $_GET['mnr'];
$sbmnr = $_GET['sbmnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

include("ip_blocks.inc.php");

###################################################################################

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

# DHCP Subnet Daten						
#$dhcppoolDN = $_GET['dn'];
$attributes = array("dn","cn","dhcphlpcont","dhcprange","description","dhcpstatements","dhcpoptallow",
							"dhcpoptdefault-lease-time","dhcpoptdeny","dhcpoptignore","dhcpoptmax-lease-time",
							"dhcpoptgeneric");
$pools = get_dhcppools($auDN, $attributes);
#print_r($pools);
$template->define_dynamic("Dhcppools", "Webseite");
$template->define_dynamic("Dhcpranges", "Webseite");

foreach ($pools as $pool){

   $template->clear_parse("DHCPRANGES_LIST");
   
   # DHCP Range
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
   
   # DHCP Subnet
   $subnet = ldap_explode_dn($pool['dhcphlpcont'],1);
   
   
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
   #$template->clear_dynamic("Dhcppools");


}

###################################################################################

include("dhcp_footer.inc.php");

?>