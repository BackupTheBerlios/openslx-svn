<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "hostoverview.dwt";

include('computers_header.inc.php');

$mnr = 0;
$sbmnr = -1;
$mcnr = -1;

###################################################################################

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################
#session_unregister( 'entries' );
$sort = "hostname";
$sort = $_GET['sort'];

$template->assign(array("DN" => "",
								"HOSTNAME" => "Noch keine Rechner angelegt",
           			      "DOMAINNAME" => "",
           			      "HWADDRESS" => "",
           			      "IPADDRESS" => "",
           		       	"DHCPCONT" => "",
           		       	"FIXADD" => "",
           		       	"DSC" => "",
           	 			"GEOLOC" => "",
           	 			"GEOATT" => "",
           	 			"HWINV" => "",
           	 			"UNINV" => "",
           		       	"RBSCONT" => "",
           		       	"CHECK" => ""));

$attributes = array("dn","hostname","domainname","hwaddress","ipaddress","description","dhcphlpcont","dhcpoptfixed-address","hlprbservice","dhcpoptnext-server","inventarnr","hwinventarnr","geolocation","geoattribut");
$host_array = get_hosts($auDN,$attributes,$sort);
#print_r($host_array);
#natsort($host_array);

$_SESSION['hosts_array'] = $host_array;
// echo "<pre>";
// var_dump($_SESSION['hosts_array']);
// echo "</pre>";
// echo "<pre>";
// var_dump($_POST["choice"]);
// var_dump($_POST["ip"]);
// var_dump($_POST["host"]);
// echo "</pre>";

// if ($sort == "ipaddress"){
// 	$host_array = array_natsort($host_array, "ipaddress", "ipaddress");
// }else{
// 	$host_array = array_natsort($host_array, "hostname", "hostname");
// }

switch ( $sort ) {
  case "ipaddress": $host_array = array_natsort($host_array, "ipaddress", "ipaddress"); break;
  case "hwaddress": $host_array = array_natsort($host_array, "hwaddress", "hwaddress"); break;
  case "description": $host_array = array_natsort($host_array, "description","description"); break;
  default: $host_array = array_natsort($host_array, "hostname", "hostname"); break;
}

$template->define_dynamic("Rechner", "Webseite");

$modentry ['domainname'] = $assocdom;

$i = 0;
foreach ($host_array as $host){

	ldap_mod_replace($ds,$host['dn'],$modentry);
	
	$hostname = "<b><a href='host.php?host=".$host['hostname']."&sbmnr=".$i."' class='headerlink'>".$host['hostname']."</a></b>";
	#$hostname = "<a href='host.php?dn=".$host['dn']."&sbmnr=".$i."' class='headerlink'>".$host['hostname']."</a>";
	$hostip = explode('_',$host['ipaddress']);
	
	if ($host[ipaddress]) {
		$dns_check = "";
		$dns_check = check_ip_zone($hostip[0],$assocdom,$host['hostname'],$au_ou);
		if ($dns_check){
			$hostname .= "<br><code class='red_font_object_fin'>$dns_check</code>";
		}
	}
	
	$dhcpcont = "";
	$dhcpfixadd = "-";
	if ( count($host['dhcphlpcont']) != 0 ){
	   $dhcpexpdn = ldap_explode_dn($host['dhcphlpcont'],1);
	   #$dhcpcn = $dhcpexpdn[0];
	   $dhcpcont = $dhcpexpdn[0]." <br>[".$dhcpexpdn[2]."]";
	   $dhcpfixadd = "dyn";
	   if ( $host['dhcpoptfixed-address'] == "ip" ){
			$dhcpfixadd = "fix";
		}
	   if ( $host['dhcpoptfixed-address'] == "hostname" ){
			//$dhcpfixadd = "fix (DNS)";
			$dhcpfixadd = "fix";
		}  
	}
	
	
	$rbscont = "-";
	$dhcpnxtsrv = "";
	if ( count($host['hlprbservice']) != 0 ){
	   $rbsexpdn = ldap_explode_dn($host['hlprbservice'],1);
		$dhcpnxtsrv = $host['dhcpoptnext-server'];
	   $rbscont = $rbsexpdn[0]; #."<br>[".$dhcpnxtsrv."]";
	   
	   
	}
	
	$checkbox_move  = "<input type='checkbox' name='hostsmove[]' value='$host[hostname]' disabled>";
	$checkbox_print = "<input type='checkbox' name='choice[$i]' ";
	
	$template->assign(array("DN" => $host['dn'],
							"CHECK" => $checkbox_print,
						"HOSTNAME" => $hostname,
           				"DOMAINNAME" => $host['domainname'],
           				"HWADDRESS" => $host['hwaddress'],
           				"IPADDRESS" => $hostip[0],
           				"DHCPCONT" => $dhcpcont,
           				"FIXADD" => $dhcpfixadd,
           				"RBSCONT" => $rbscont,
           	 			"DSC" => $host['description'],
           	 			"GEOLOC" => $host['geolocation'],
           	 			"GEOATT" => $host['geoattribut'],
           	 			"HWINV" => $host['hwinventarnr'],
           	 			"UNINV" => $host['inventarnr'],
           		       	"AUDN" => $auDN ));
	$template->parse("RECHNER_LIST", ".Rechner");
	
	$i++;
}

#echo "all roles: "; print_r($all_roles); echo "<br>";
$selectsize = count($all_roles) + 1;
$move_select = "<select name='automove' size='$selectsize' class='form_250_selectbox'> 
	   			            <option selected value=''> --------------- </option>";
foreach (array_keys($all_roles) as $au) {
	if ($au != $auDN) {
		$ou = ldap_explode_dn($au, 1);
		$zone = $all_roles[$au][zone];
		$value = $au."_".$zone;
		$move_select .= "<option value='$value'>$ou[0] ($zone)</option>";
	}
} 
$move_select .= "</select>";
$template->assign(array("SELECT" => $move_select));

###################################################################################

include("computers_footer.inc.php");

?>