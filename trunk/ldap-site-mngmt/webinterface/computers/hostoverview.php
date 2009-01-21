<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "hostoverview.dwt";

include('computers_header.inc.php');

$mnr = 1; 
$sbmnr = -1;
$mcnr = -1;

###################################################################################

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################

$template->assign(array("DN" => "",
								"HOSTNAME" => "Noch keine Rechner angelegt",
           			      "DOMAINNAME" => "",
           			      "HWADDRESS" => "",
           			      "IPADDRESS" => "",            			      
           		       	"DHCPCONT" => "",
           		       	"FIXADD" => "",
           		       	"RBSCONT" => "",
           		       	"NXTSRV" => ""));

$attributes = array("dn","hostname","domainname","hwaddress","ipaddress","dhcphlpcont","dhcpoptfixed-address","hlprbservice","dhcpoptnext-server");
$host_array = get_hosts($auDN,$attributes);

$template->define_dynamic("Rechner", "Webseite");

$i = 0;
foreach ($host_array as $host){
	
	$hostname = "<a href='host.php?dn=".$host['dn']."&sbmnr=".$i."' class='headerlink'>".$host['hostname']."</a>";
	$hostip = explode('_',$host['ipaddress']);
	
	$dhcpcont = "";
	$dhcpfixadd = "";
	if ( count($host['dhcphlpcont']) != 0 ){
	   $dhcpexpdn = ldap_explode_dn($host['dhcphlpcont'],1);
	   $dhcpcn = $dhcpexpdn[0];
	   #$ocarray = get_node_data($host['dhcphlpcont'],array("objectclass","dhcphlpcont"));
	   #$sub = array_search('dhcpSubnet', $ocarray['objectclass']);
	   #if ($sub !== false ){
	   #   $dhcpcont = "Subnet ".$dhcpexpdn[0]." <br>[".$dhcpexpdn[2]."]";
	   #}else{
	   $dhcpcont = $dhcpexpdn[0]." <br>[".$dhcpexpdn[2]."]";
	   #}
	   $dhcpfixadd = "dyn";
	   if ( $host['dhcpoptfixed-address'] == "ip" ){
			$dhcpfixadd = "fix";
		}
	   if ( $host['dhcpoptfixed-address'] == "hostname" ){
			$dhcpfixadd = "fix (DNS)";
		}  
	}
	
	
	
	$rbscont = "";
	$dhcpnxtsrv = "";
	if ( count($host['hlprbservice']) != 0 ){
	   $rbsexpdn = ldap_explode_dn($host['hlprbservice'],1);
	   $rbscont = $rbsexpdn[0]." <br>[".$rbsexpdn[2]."]";
	   
	   $dhcpnxtsrv = $host['dhcpoptnext-server'];
	}
	
	$template->assign(array("DN" => $host['dn'],
								"HOSTNAME" => $hostname,
           			      "DOMAINNAME" => $host['domainname'],
           			      "HWADDRESS" => $host['hwaddress'],
           			      "IPADDRESS" => $hostip[0],            			      
           		       	"DHCPCONT" => $dhcpcont,
           		       	"FIXADD" => $dhcpfixadd,
           		       	"RBSCONT" => $rbscont,
           		       	"NXTSRV" => $dhcpnxtsrv,
           		       	"AUDN" => $auDN ));
	$template->parse("RECHNER_LIST", ".Rechner");
	
	$i++;
}

###################################################################################

include("computers_footer.inc.php");

?>