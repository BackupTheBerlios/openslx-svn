<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "new_dhcpsubnet.dwt";

include('dhcp_header.inc.php');

$mnr = 0; 
$sbmnr = -1;

###################################################################################

$mnr = $_GET['mnr'];
$sbmnr = $_GET['sbmnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$subnetcn = str_replace ( "_", " ", $_GET['subnetcn']);
$netmask = str_replace ( "_", " ", $_GET['netmask']);


# DHCP Data one scope up (Global)
$global_options = array("dhcpoptdefault-lease-time","dhcpoptmax-lease-time","dhcpoptallow",
							"dhcpoptdeny","dhcpoptignore","hlprbservice","dhcpoptnext-server","dhcpoptfilename",
							"dhcpoptdomain-name","dhcpoptdomain-name-servers",
							"dhcpoptgeneric","dhcpoptget-lease-hostnames");
$global_data = get_node_data($DHCP_SERVICE,$global_options);

$mltext = "&nbsp;";
if ( $global_data['dhcpoptmax-lease-time'] ) {
	$maxlease_select = "<option value='' selected>".$LEASE_TIMES[$global_data['dhcpoptmax-lease-time']]." &nbsp;
		[".$global_data['dhcpoptmax-lease-time']." s]</option>";
	$mltext = "<br><b>Global vom DHCP Dienst vorgegeben</b><br>
		wird nicht explizit f&uuml;r das Subnetz angelegt<br><br>
		Sie k&ouml;nnen spezifisch f&uuml;r das Subnetz eine andere <b>maximale</b> Lease-Time setzen";
}else{
	$maxlease_select = "<option value='' selected> ------- </option>";
}
foreach (array_keys($LEASE_TIMES) as $sec) {
	if ( $sec != $global_data['dhcpoptmax-lease-time'] ) {
		$maxlease_select .= "<option value='$sec'>$LEASE_TIMES[$sec] &nbsp;[$sec s]</option>";
	}
}
$maxlease_select .= "</select>";

$dltext = "&nbsp;";
if ( $global_data['dhcpoptdefault-lease-time'] ) {
	$defaultlease_select = "<option value='' selected>".$LEASE_TIMES[$global_data['dhcpoptdefault-lease-time']]." &nbsp;
		[".$global_data['dhcpoptdefault-lease-time']." s]</option>";
	$dltext = "<br><b>Global vom DHCP Dienst vorgegeben</b><br>
		wird nicht explizit f&uuml;r das Subnetz angelegt<br><br>
		Sie k&ouml;nnen spezifisch f&uuml;r das Subnetz eine andere <b>Default</b> Lease-Time setzen";
}else{
	$defaultlease_select = "<option value='' selected> ------- </option>";
}
foreach (array_keys($LEASE_TIMES) as $sec) {
	if ( $sec != $global_data['dhcpoptdefault-lease-time'] ) {
		$defaultlease_select .= "<option value='$sec'>$LEASE_TIMES[$sec] &nbsp;[$sec s]</option>";
	}
}
$defaultlease_select .= "</select>";
					
$ml_select = "<select name='dhcpoptmax-lease-time' size='4' class='small_form_selectbox'>".$maxlease_select;
$dl_select = "<select name='dhcpoptdefault-lease-time' size='4' class='small_form_selectbox'>".$defaultlease_select;

$template->assign(array("CN" => $subnetcn,
								"NETMASK" => $netmask,
								"DHCPSRVDN" => $DHCP_SERVICE,
								"DESCRIPTION" => "",
								"STATEMENTS" => "",
								"ALLOW" => "",
								"DENY" => "",
								"IGNORE" => "",
								"DDNSUPDATE" => "",
								"DEFAULTLEASE" => $dl_select,
								"MAXLEASE" => $ml_select,
								"DLTEXT" => $dltext,
								"MLTEXT" => $mltext,
								"USEHOSTDCL" => "",
								"ROUTERS" => "",
								"DOMAINNAME" => "",
								"DOMAINNAMESERVERS" => $global_data['dhcpoptdomain-name-servers'],
								"NEXTSERVER" => "",
								"FILENAME" => "",
								"SRVIDENT" => "",
								"NTPSERVERS" => "",
								"OPTGENERIC" => "",
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr,
           		       	"MCNR" => $mcnr));



$freenets = get_networks();
#print_r($freenets);
$subnets = array();
if (count($freenets) != 0){
   $template->define_dynamic("Dhcpsubnets", "Webseite");

   foreach ($freenets as $subnet){
      $netexp = explode(".",$subnet);
      $mask = array(255,255,255,255);
      for ($i=0; $i<count($netexp); $i++){
         if ($netexp[$i] == "0"){
            $mask[$i] = "0";
         }
      }
      $netmask = implode(".", $mask);
      $subnets[] = $subnet."|".$netmask;
      
      $template->assign(array("SUBNET" => $subnet."|".$netmask,
   	                  "CN" => $subnet,
   	                  "NETMASK" => $netmask));
   	$template->parse("DHCPSUBNETS_LIST", ".Dhcpsubnets");	  
   }
   #print_r($subnets);
   
# DHCP Services
#$dhcpservices = get_dhcpoffers($auDN);
#print_r($dhcpservices); echo "<br>";

$template->assign(array("DHCPSVDN" => $DHCP_SERVICE));
#if (count($dhcpservices) != 0){
#$template->define_dynamic("Dhcpservices", "Webseite");
#	foreach ($dhcpservices as $item){
#	   $exp = ldap_explode_dn($item,1);
#
#		$template->assign(array("DHCPSVDN" => $item,
#   	                  "DHCPSVCN" => $exp[0],
#   	                  "DHCPSVAU" => $exp[2]));
#   	$template->parse("DHCPSERVICES_LIST", ".Dhcpservices");	
#	} 
#}

$template->assign(array("SUBLIST" => count($freenets)+1,
								"SRVLIST" => count($dhcpservices)+1));
								

}else{
   # keine freie Netze mehr zur Verfügung
   # wird schon über das DHCP Menu abgefangen ...
}

###################################################################################

include("dhcp_footer.inc.php");

?>