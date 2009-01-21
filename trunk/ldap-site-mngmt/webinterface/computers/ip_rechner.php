<?php

include('../standard_header.inc.php');
 
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "ip_rechner.dwt";

include('computers_header.inc.php');

#############################################################################

$mnr = 1;
$sbmnr = -1;
$mcnr = -1;

# Menuleiste erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

#############################################################################

$sort = "hostname";
$sort = $_GET['sort'];

$template->assign(array("IP" => "",
                        "OLDIP" => "",
                        "DHCPCONT" => "",
                        "FIXADD" => "",
                        "HOSTNAME" => "Noch keine Rechner angelegt",
                        "HOSTDN" => ""));

$host_array = get_hosts($auDN,array("dn","hostname","ipaddress","dhcphlpcont","dhcpoptfixed-address"),$sort);
# print_r ($host_array);

if ($sort == "ipaddress"){
	$host_array = array_natsort($host_array, "ipaddress", "ipaddress");
}

$template->define_dynamic("Hosts", "Webseite");

foreach ($host_array as $host){
	$hostip = explode('_',$host['ipaddress']);
	
	$dhcpcont = "";
	$fixadd = "";
	if ( count($host['dhcphlpcont']) != 0 ){  #&& $host['ipaddress'] == "" ){
		$dhcpcont = " dynamisch";
		#$fixadd = $host['dhcpoptfixed-address'];
	#}elseif( count($host['dhcphlpcont']) != 0 && $host['ipaddress'] != "" ){
		if ( $host['dhcpoptfixed-address'] == "ip") {
			$dhcpcont = " fix";
			#$fixadd = $host['dhcpoptfixed-address'];
		}
		if ( $host['dhcpoptfixed-address'] == "hostname") {
			$dhcpcont = " fix (&uuml;ber DNS Name)";
			#$fixadd = $host['dhcpoptfixed-address'];
		}
		$fixadd = $host['dhcpoptfixed-address'];
	}
	
	$template->assign(array("IP" => $hostip[0],
                           "OLDIP" => $hostip[0],
                           "DHCPCONT" => $dhcpcont,
                           "FIXADD" => $fixadd,
                           "HOSTNAME" => $host['hostname'],
                           "HOSTDN" => $host['dn'],
                           "AUDN" => $auDN ));
   $template->parse("HOSTS_LIST", ".Hosts");			
}


#####################################################################################

include("computers_footer.inc.php");

?>
