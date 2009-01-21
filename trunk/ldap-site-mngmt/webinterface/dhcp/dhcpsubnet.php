<?php
include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "DHCP Service Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 5;
$mnr = 0; 
$sbmnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcpsubnet.dwt";

include("../class.FastTemplate.php");

include('dhcp_header.inc.php');

###################################################################################

$mnr = $_GET['mnr'];
$sbmnr = $_GET['sbmnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$template->assign(array("SUBNETDN" => "",
								"CN" => "",
								"NETMASK" => "",
								"RANGE1" => "",
								"RANGE2" => "",
								"DESCRIPTION" => "",
								"STATEMENTS" => "",
								"ALLOW" => "",
								"DENY" => "",
								"IGNORE" => "",
								"DDNSUPDATE" => "",
								"DEFAULTLEASE" => "",
								"MAXLEASE" => "",
								"USEHOSTDCL" => "",
								"BROADCAST" => "",
								"ROUTERS" => "",
								"DOMAINNAME" => "",
								"DOMAINNAMESERVERS" => "",
								"NEXTSERVER" => "",
								"FILENAME" => "",
								"SRVIDENT" => "",
								"NTPSERVERS" => "",
								"OPTGENERIC" => "",
								"DHCPOFFERNOWDN" => "",
								"DHCPSVNOW" => "",
								"DHCPSVNOWAU" => "",
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr,
           		       	"MCNR" => $mcnr));

# DHCP Subnet Daten						
$dhcpsubnetDN = $_GET['dn'];
$attributes = array("dn","cn","dhcpoptnetmask","dhcphlpcont","dhcprange","description","dhcpstatements","dhcpoptallow",
							"dhcpoptddns-update-style","dhcpoptdefault-lease-time","dhcpoptdeny","dhcpoptfilename",
							"dhcpoptignore","dhcpoptmax-lease-time","dhcpoptnext-server","dhcpoptserver-identifier",
							"dhcpoptuse-host-decl-names","dhcpoptbroadcast-address","dhcpoptdhcp-max-message-size",
							"dhcpoptdomain-name","dhcpoptdomain-name-servers","dhcpoptgeneric","dhcpoptntp-servers",
							"dhcpoptroot-path","dhcpoptrouters");
$subnet_data = get_node_data($dhcpsubnetDN, $attributes);
#print_r($subnet_data);

# momentane DHCP Service Zuordnung
$dhcpsvnowdn = ldap_explode_dn($subnet_data['dhcphlpcont'], 1);

# DHCP Range
$iprange = explode('_',$subnet_data['dhcprange']);

$template->assign(array("SUBNETDN" => $dhcpsubnetDN,
								"CN" => $subnet_data['cn'],
								"NETMASK" => $subnet_data['dhcpoptnetmask'],
								"RANGE1" => $iprange[0],
								"RANGE2" => $iprange[1],
								"DESCRIPTION" => $subnet_data['description'],
								"STATEMENTS" => $subnet_data['dhcpstatements'],
								"ALLOW" => $subnet_data['dhcpoptallow'],
								"DENY" => $subnet_data['dhcpoptdeny'],
								"IGNORE" => $subnet_data['dhcpoptignore'],
								"DDNSUPDATE" => $subnet_data['dhcpoptddns-update-style'],
								"DEFAULTLEASE" => $subnet_data['dhcpoptdefault-lease-time'],
								"MAXLEASE" => $subnet_data['dhcpoptmax-lease-time'],
								"USEHOSTDCL" => $subnet_data['dhcpoptuse-host-decl-names'],
								"BROADCAST" => $subnet_data['dhcpoptbroadcast-address'],
								"ROUTERS" => $subnet_data['dhcpoptrouters'],
								"DOMAINNAME" => $subnet_data['dhcpoptdomain-name'],
								"DOMAINNAMESERVERS" => $subnet_data['dhcpoptdomain-name-servers'],
								"NEXTSERVER" => $subnet_data['dhcpoptnext-server'],
								"FILENAME" => $subnet_data['dhcpoptfilename'],
								"SRVIDENT" => $subnet_data['dhcpoptserver-identifier'],
								"NTPSERVERS" => $subnet_data['dhcpoptntp-servers'],
								"OPTGENERIC" => $subnet_data['dhcpoptgeneric'],
								"DHCPOFFERNOWDN" => $subnet_data['dhcphlpcont'],
								"DHCPSVNOW" => $dhcpsvnowdn[0],
								"DHCPSVNOWAU" => $dhcpsvnowdn[2],
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr,
           		       	"MCNR" => $mcnr));


# alternative DHCP Services
$altdhcp = alternative_dhcpservices($subnet_data['dhcphlpcont']);

$template->assign(array("DHCPSVDN" => "",
   	                  "DHCPSVCN" => "",
   	                  "DHCPSVAU" => ""));
if (count($altdhcp) != 0){
$template->define_dynamic("Dhcpservices", "Webseite");
	foreach ($altdhcp as $item){
		$template->assign(array("DHCPSVDN" => $item['dn'],
   	                  "DHCPSVCN" => $item['cn'],
   	                  "DHCPSVAU" => $item['au']));
   	$template->parse("DHCPSERVICES_LIST", ".Dhcpservices");	
	} 
}

###################################################################################

include("dhcp_footer.inc.php");

?>