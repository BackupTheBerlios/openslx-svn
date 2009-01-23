<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "host.dwt";

include('computers_header.inc.php');

$mnr = 0; 
$sbmnr = -1;
$mcnr = -1;

###################################################################################

$sbmnr = $_GET['sbmnr']; 

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################

$hostDN = "HostName=".$_GET['host'].",cn=computers,".$auDN;
#$hostDN = $_GET['dn'];

$attributes = array("hostname","domainname","ipaddress","hwaddress","description","dhcphlpcont",
							"dhcpoptfixed-address","hw-mouse","hw-graphic","hw-monitor");
$host = get_node_data($hostDN,$attributes);
$hostip = explode('_',$host['ipaddress']);

if ($host[ipaddress]) {
		$dns_check = "";
		$dns_check = check_ip_zone($hostip[0],$assocdom,$host['hostname'],$au_ou);
		if ($dns_check){
			$dns_feedback .= "<code class='red_font_object_fin'>$dns_check</code>";
		}
	}

$template->assign(array("HOSTDN" => $hostDN,
								"HOSTNAME" => $host['hostname'],
								"DNSCHECK" => $dns_feedback,
           			      "DOMAINNAME" => $host['domainname'],
           			      "HWADDRESS" => $host['hwaddress'],
           			      "IPADDRESS" => $hostip[0],
           			      "DESCRIPTION" => $host['description'],           			      
           		       	"DHCPCONT" => $host['dhcphlpcont'],        			      
           		       	"DHCPTYPE" => $dhcptype,
           		       	"FIXADD" => $host['dhcpoptfixed-address'] ,			      
           		       	"MOUSE" => $host['hw-mouse'],          			      
           		       	"GRAPHIC" => $host['hw-graphic'],
           		       	"MONITOR" => $host['hw-monitor'],
           		       	"DHCPLINK" => "<a href='dhcphost.php?host=".$host['hostname']."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	#"RBSLINK" => "<a href='rbshost.php?host=".$host['hostname']."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"RBSLINK" => "",
           		       	"HWLINK" => "<a href='hwhost.php?host=".$host['hostname']."&sbmnr=".$sbmnr."' class='headerlink'>",
           		        	"AUDN" => $auDN,
           		       	"SBMNR" => $sbmnr));


###################################################################################

include("computers_footer.inc.php");

?>