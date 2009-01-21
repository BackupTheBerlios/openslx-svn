<?php
include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "DHCP Service Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 5;
$mnr = 0; 
$sbmnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcpservice.dwt";

include("../class.FastTemplate.php");

include('dhcp_header.inc.php');

###################################################################################

$mnr = $_GET['mnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

include("ip_blocks.inc.php");

###################################################################################

$template->assign(array("DHCPDN" => "",
								"CN" => "",
								"PRIMARY" => "",
								"SECONDARY" => "",
								"DESCRIPTION" => "",
								"STATEMENTS" => "",
								"FAILOVERPEER" => "",
								"ALLOW" => "",
								"DENY" => "",
								"IGNORE" => "",
								"DDNSUPDATE" => "",
								"DEFAULTLEASE" => "",
								"MAXLEASE" => "",
								"USEHOSTDCL" => "",
								"DOMAINNAME" => "",
								"DOMAINNAMESERVERS" => "",
								"MAXMESSIZE" => "",
								"NTPSERVERS" => "",
								"OPTGENERIC" => "",
								"OPTDEF" => "",
								"OPTDEFINITION" => "",
								"DHCPOFFERNOWDN" => "",
								"DHCPOFFERNOW" => "",
								"SUBNET" => "keine Subnetze zugewiesen",
								"NETMASK" => "",
								"SUBNETAU" => ""));

# DHCP Service Daten						
$dhcpsv_array = get_dhcpservices($auDN,array("dn","cn"));
$dhcpserviceDN = $dhcpsv_array[0]['dn'];
$attributes = array("dn","cn","dhcpprimarydn","dhcpsecondarydn","description","dhcpofferdn","dhcpstatements","dhcpfailoverpeer",
                     "dhcpoptallow","dhcpoptddns-update-style","dhcpoptdefault-lease-time","dhcpoptdeny","dhcpoptfilename",
							"dhcpoptignore","dhcpoptmax-lease-time","dhcpoptnext-server","optiondefinition",
							"dhcpoptuse-host-decl-names","dhcpoptbroadcast-address","dhcpoptdhcp-max-message-size",
							"dhcpoptdomain-name","dhcpoptdomain-name-servers","dhcpoptgeneric","dhcpoptntp-servers",
							"dhcpoptroot-path","dhcpoptrouters");
$dhcpsv_data = get_node_data($dhcpserviceDN, $attributes);
#print_r($dhcpsv_data);

# DHCP Service Anbieten
# momentanes Offer
# todo: falls dhcpofferDN leer dann standardwert AU teilbaum
$offerexp = ldap_explode_dn($dhcpsv_data['dhcpofferdn'], 1);
$dhcpoffernow = $offerexp[0];
# alternative Offers
$expdn = ldap_explode_dn($auDN, 0); # Mit Merkmalen
$expdn = array_slice($expdn, 1); 
$expou = ldap_explode_dn($auDN, 1); # nur Werte 
$expou = array_slice($expou, 1, -3);
#print_r($expou); echo "<br>";
#print_r($expdn); echo "<br>"; 
for ($i=0; $i<count($expou); $i++){
	$dhcpoffers[$i]['ou'] = $expou[$i];
	$dhcpoffers[$i]['dn'] = implode(',',$expdn);
	$expdn = array_slice($expdn, 1);
}
#print_r($dhcpoffers);

$expcn = explode('_',$dhcpsv_data['cn']);
$name = array_slice($expcn,1);
$dhcpcn = implode('_',$name);

$optdef = "";
if (count($dhcpsv_data['optiondefinition']) == 1){
    $dhcpsv_data['optiondefinition'] = array($dhcpsv_data['optiondefinition']);  
}
if (count($dhcpsv_data['optiondefinition']) > 0){
   foreach ($dhcpsv_data['optiondefinition'] as $optdefinition){
      $optdef .= "
      			<tr>
      				<td style='border-color: black; border-style: solid; border-width: 0 0 0 0;'>&nbsp;</td>
      				<td style='border-color: black; border-style: solid; border-width: 0 0 0 0;'>
      					<input type='Text' name='dhcpoptdefinition[]' value='".$optdefinition."' size='40' class='medium_form_field'>
      					<input type='hidden' name='olddhcpoptdefinition[]' value='".$optdefinition."'> &nbsp;
      				</td>
      			</tr>";
   }
}

$template->assign(array("DHCPDN" => $dhcpsv_data['dn'],
								"CN" => $dhcpcn,
								"PRIMARY" => $dhcpsv_data['dhcpprimarydn'],
								"SECONDARY" => $dhcpsv_data['dhcpsecondarydn'],
								"DESCRIPTION" => $dhcpsv_data['description'],
								"STATEMENTS" => $dhcpsv_data['dhcpstatements'],
								"FAILOVERPEER" => $dhcpsv_data['dhcpfailoverpeer'],
								"ALLOW" => $dhcpsv_data['dhcpoptallow'],
								"DENY" => $dhcpsv_data['dhcpoptdeny'],
								"IGNORE" => $dhcpsv_data['dhcpoptignore'],
								"DDNSUPDATE" => $dhcpsv_data['dhcpoptddns-update-style'],
								"DEFAULTLEASE" => $dhcpsv_data['dhcpoptdefault-lease-time'],
								"MAXLEASE" => $dhcpsv_data['dhcpoptmax-lease-time'],
								"USEHOSTDCL" => $dhcpsv_data['dhcpoptuse-host-decl-names'],
								"MAXMESSIZE" => $dhcpsv_data['dhcpoptdhcp-max-message-size'],
								"DOMAINNAME" => $dhcpsv_data['dhcpoptdomain-name'],
								"DOMAINNAMESERVERS" => $dhcpsv_data['dhcpoptdomain-name-servers'],
								"NEXTSERVER" => $dhcpsv_data['dhcpoptnext-server'],
								"FILENAME" => $dhcpsv_data['dhcpoptfilename'],
								"NTPSERVERS" => $dhcpsv_data['dhcpoptntp-servers'],
								"DHCPOFFERNOWDN" => $dhcpsv_data['dhcpofferdn'],
								"DHCPOFFERNOW" => $dhcpoffernow,
								"OPTDEF" => $optdef,
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr));

$template->define_dynamic("Dhcpoffers", "Webseite");
foreach ($dhcpoffers as $offer){
	$template->assign(array("DHCPOFFER" => $offer['dn'],
									"DHCPOFFEROU" => $offer['ou'],));
	$template->parse("DHCPOFFERS_LIST", ".Dhcpoffers");
}


# Subnetze und Hosts des Dienstes
$dhcpobjects = get_service_subnets($dhcpserviceDN, array("dn","cn","dhcpoptnetmask"));
#print_r($dhcpobjects);
$template->define_dynamic("Dhcpsubnets", "Webseite");
foreach ($dhcpobjects as $subnet){
	$template->assign(array("SUBNET" => $subnet['cn'],
									"NETMASK" => $subnet['dhcpoptnetmask'],
									"SUBNETAU" => $subnet['auDN']));
	$template->parse("DHCPSUBNETS_LIST", ".Dhcpsubnets");
}

### Rechner
#$hostorgroup = $exp[0];
#$hosts_array = get_hosts($auDN,array("dn","hostname","ipaddress"));
#
#$template->define_dynamic("TftpHosts", "Webseite");
#$template->define_dynamic("NfsHosts", "Webseite");
#$template->define_dynamic("NbdHosts", "Webseite");
#foreach ($hosts_array as $item){
#	$template->assign(array("HDN" => $item['dn'],
#                           "HN" => $item['hostname'],
#                           "IP" => $item['ipaddress']));
#   $template->parse("TFTPHOSTS_LIST", ".TftpHosts");
#   $template->assign(array("HDN" => $item['dn'],
#                           "HN" => $item['hostname'],
#                           "IP" => $item['ipaddress']));
#   $template->parse("NFSHOSTS_LIST", ".NfsHosts");	
#   $template->assign(array("HDN" => $item['dn'],
#                           "HN" => $item['hostname'],
#                           "IP" => $item['ipaddress']));
#   $template->parse("NBDHOSTS_LIST", ".NbdHosts");	
#}

################################################
# DHCP Generator Skript Config
$template->assign(array("DHCPGENLDAP" => LDAP_HOST,
   	                  "DHCPGENBASE" => "ou=RIPM,".$suffix,
   	                  "DHCPGENUDN" => $userDN,
   	                  "DHCPGENPW" => $userPassword,
   	                  "DHCPGENSVDN" => $dhcpserviceDN));


###################################################################################

include("dhcp_footer.inc.php");

?>