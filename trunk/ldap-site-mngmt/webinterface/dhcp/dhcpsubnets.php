<?php

include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "DHCP Service Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 5;
$mnr = -1; 
$sbmnr = -1;
$mcnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcpsubnets.dwt";

include("../class.FastTemplate.php");

include('dhcp_header.inc.php');

###################################################################################

$mnr = $_GET['mnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

include("ip_blocks.inc.php");

###################################################################################

$template->assign(array("SUBNETDN" => "",
								"SUBNETCN" => "Noch keine Subnets angelegt",
								"NETMASK" => "",
								"DHCP" => "",
								"POOLS" => ""));

# rbservice und pxe daten (voerst nur ein rbs)
$subnet_array = get_dhcpsubnets($auDN,array("dn","cn","dhcpoptnetmask","dhcprange","dhcphlpcont"));

$template->define_dynamic("Subnets", "Webseite");
$template->define_dynamic("Pools", "Webseite");

foreach ($subnet_array as $subnet){
   # Pools des Subnetzes
   $pools = get_dhcppools_subnet($subnet['dn'],array("dhcprange","dhcpoptallow","dhcpoptdeny","dhcpoptignore"));
   #print_r($pools); echo "<br><br>";
   $poollist = "<ul>";
   foreach ($pools as $pool){
      $poollist .= "<li>";
      if (count($pool['dhcprange']) >1){
         for ($i=0; $i<count($pool['dhcprange']); $i++){
            $range = explode('_',$pool['dhcprange'][$i]);
            $poollist .= $range[0]." - ".$range[1];
            if ($i+1 != count($pool['dhcprange'])){
               $poollist .= "<br>";
            }
         }
      }else{
         $range = explode('_',$pool['dhcprange']);
         $poollist .= $range[0]." - ".$range[1];
      }
      if ($pool['dhcpoptallow'] != ""){
         $poollist .= "<br>ALLOW ".$pool['dhcpoptallow'];
      }
      if ($pool['dhcpoptignore'] != ""){
         $poollist .= "<br>IGNORE ".$pool['dhcpoptignore'];
      }
      if ($pool['dhcpoptdeny'] != ""){
         $poollist .= "<br>DENY ".$pool['dhcpoptdeny'];
      }
      $poollist .= " &nbsp;[Abt.: ".$pool['poolAU']."]</li><br>";
   }
   $poollist .= "</ul>";
   
   # Dienstzuordnung des Subnetzes 
   $dhcpservice = "";
   if ($subnet['dhcphlpcont'] != ""){
      $exp = ldap_explode_dn($subnet['dhcphlpcont'],1);
      $dhcpservice = $exp[0]." &nbsp;[".$exp[2]."]";
   }
   
   $subnetcn = "<a href='dhcpsubnet.php?dn=".$subnet['dn']."&mnr=".$mnr."' class='headerlink'><b>".$subnet['cn']."</b></a>";
	$template->assign(array("SUBNETDN" => $subnet['dn'],
									"SUBNETCN" => $subnetcn,
	   	        		      "NETMASK" => $subnet['dhcpoptnetmask'],
	   	        		      "DHCP" => $dhcpservice,
	   	        			   "POOLS" => $poollist));
	$template->parse("SUBNETS_LIST", ".Subnets");
}


###################################################################################

include("dhcp_footer.inc.php");

?>
