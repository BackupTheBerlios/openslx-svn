<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dns_error_hosts.dwt";

include('dns_header.inc.php');

$mnr = 2;

###################################################################################

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDNSMenu($rollen, $mnr);

###################################################################################

$template->assign(array("DN" => "",
								"HOSTNAME" => "Alle Clients haben korrekte DNS Eintr&auml;ge",
           			      "DOMAINNAME" => "",
           			      "HWADDRESS" => "",
           			      "IPADDRESS" => "",
           			      "HOSTAU" => ""));

$attributes = array("dn","hostname","domainname","hwaddress","ipaddress");
$host_array = get_dnshosts_subtree($attributes);
#print_r($host_array);

$template->define_dynamic("Rechner", "Webseite");


foreach ($host_array as $host){

	$hostip = explode('_',$host['ipaddress']);
	$host_audn = get_audn_of_objectdn($host['dn']);
	$host_au = get_rdn_value($host_audn);
	
	$dns_check = "";
	$dns_check = check_ip_zone($hostip[0],$host['domainname'],$host['hostname'],$host_au);
	if ($dns_check){
		$hostname = $host['hostname']."<br><code class='red_font_object_fin'>$dns_check</code>";
		$ip = $hostip[0];
		$dnszone = $host['domainname'];
		$mac = $host['hwaddress'];
	
		$template->assign(array("DN" => $host['dn'],
									"HOSTNAME" => $hostname,
	           			      "DOMAINNAME" => $dnszone,
	           			      "HWADDRESS" => $mac,
	           			      "IPADDRESS" => $ip,
	           		       	"HOSTAU" => $host_au,
	           		       	"AUDN" => $auDN ));
		$template->parse("RECHNER_LIST", ".Rechner");
	}
}



###################################################################################

include("dns_footer.inc.php");

?>