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
                        "RBSCONT" => "",
                        "DNSCONT" => "",
                        "FIXADD" => "",
                        "HOSTNAME" => "Noch keine Rechner angelegt",
                        "HOSTDN" => ""));

$host_array = get_hosts($auDN,array("dn","hostname","hwaddress","ipaddress","dhcphlpcont","dhcpoptfixed-address","hlprbservice"),$sort);
# print_r ($host_array);

if ($sort == "ipaddress"){
	$host_array = array_natsort($host_array, "ipaddress", "ipaddress");
}

$template->define_dynamic("Hosts", "Webseite");

$i = 0;
foreach ($host_array as $host){
	$hostip = explode('_',$host['ipaddress']);
	
	$fixadd = "";
	if ( $host['hwaddress'] ) {
		if ( $host['ipaddress'] ) {
			if ( count($host['dhcphlpcont']) != 0 && $host['dhcpoptfixed-address'] == "ip") {
				$dhcp_radio = "
					<input type='radio' name='dhcp[$i]' value='fix' checked> fix &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;			
					<input type='radio' name='dhcp[$i]' value=''> kein <br>
					<input type='radio' name='dhcp[$i]' value='fixdns'> fix DNS
					<input type='hidden' name='olddhcp[]' value='fix'>";
				$fixadd = $host['dhcpoptfixed-address'];
			}
			elseif ( count($host['dhcphlpcont']) != 0 && $host['dhcpoptfixed-address'] == "hostname") {
				$dhcp_radio = "					
					<input type='radio' name='dhcp[$i]' value='fix'> fix &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;			
					<input type='radio' name='dhcp[$i]' value=''>  kein <br>
					<input type='radio' name='dhcp[$i]' value='fixdns' checked> fix DNS 
					<input type='hidden' name='olddhcp[]' value='fixdns'>";
				$fixadd = $host['dhcpoptfixed-address'];
			}else{
				$dhcp_radio = "
					<input type='radio' name='dhcp[$i]' value='fix'> fix &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;			
					<input type='radio' name='dhcp[$i]' value='' checked> kein <br>
					<input type='radio' name='dhcp[$i]' value='fixdns'> fix DNS
					<input type='hidden' name='olddhcp[]' value=''>";
			}
		}else{
			if ( count($host['dhcphlpcont']) != 0 ){
				$dhcp_radio = "
					<input type='radio' name='dhcp[$i]' value='dyn' checked> dyn &nbsp;&nbsp;&nbsp;			
					<input type='radio' name='dhcp[$i]' value=''> kein
					<input type='hidden' name='olddhcp[]' value='dyn'>";
			}else{
				$dhcp_radio = "
					<input type='radio' name='dhcp[$i]' value='dyn'> dyn &nbsp;&nbsp;&nbsp;			
					<input type='radio' name='dhcp[$i]' value='' checked> kein
					<input type='hidden' name='olddhcp[]' value=''>";
			}
		}	
	}else{
		$dhcp_radio = "Keine MAC Adresse<br>DHCP nicht nutzbar.
			<input type='hidden' name='dhcp[]' value=''>
			<input type='hidden' name='olddhcp[]' value=''>";
	}
	#if ( count($host['dhcphlpcont']) != 0 ){  #&& $host['ipaddress'] == "" ){
	#	$dhcpcont = " dynamisch";
		#$fixadd = $host['dhcpoptfixed-address'];
	#}elseif( count($host['dhcphlpcont']) != 0 && $host['ipaddress'] != "" ){
	#	if ( $host['dhcpoptfixed-address'] == "ip") {
	#		$dhcpcont = " fix";
	#
	#	}
	#	if ( $host['dhcpoptfixed-address'] == "hostname") {
	#		$dhcpcont = " fix (&uuml;ber DNS Name)";
	#	}
	#	$fixadd = $host['dhcpoptfixed-address'];
	#}
	
	# RBS
	$rbs_selectbox = "";
	$rbsDN = $host['hlprbservice'];
	$altrbs = alternative_rbservices($rbsDN);
	$rbs_selectbox .= "<select name='rbs[]' size='3' class='small_form_selectbox2'>";
	if ( $rbsDN ) {
		$rbscn = ldap_explode_dn($rbsDN,1);
		$rbs_selectbox .= "<option selected value='".$rbsDN."' selected>$rbscn[0]</option>
								 <option value=''>----- Kein RBS -----</option>";
	}else{
		$rbs_selectbox .= "<option selected value=''>----- Kein RBS -----</option>";	
	}	
	if (count($altrbs) != 0){
   	foreach ($altrbs as $item){
      	$rbs_selectbox .= "<option value='".$item['dn']."'>".$item['cn']."</option>";
   	}
	}
	$rbs_selectbox .= "</select>
							<input type='hidden' name='oldrbs[]' value='".$rbsDN."'>";
	
	# DNS 
	#if ( DNS true ) {
	#	$dns_checkbox = "<input type='checkbox' name='dnscont' value='' checked>";
	#}else{
		$dns_checkbox = "<input type='checkbox' name='dnscont' value=''>";
	#}
	
	$template->assign(array("IP" => $hostip[0],
                           "OLDIP" => $hostip[0],
                           "DHCPCONT" => $dhcp_radio,
                           "DHCPSRVDN" => $DHCP_SERVICE,
                           "RBSCONT" => $rbs_selectbox,
                           "DNSCONT" => $dns_checkbox,
                           "FIXADD" => $fixadd,
                           "HOSTNAME" => $host['hostname'],
                           "HOSTDN" => $host['dn'],
                           "AUDN" => $auDN ));
   $template->parse("HOSTS_LIST", ".Hosts");
   
   $i++;
}


#####################################################################################

include("computers_footer.inc.php");

?>
