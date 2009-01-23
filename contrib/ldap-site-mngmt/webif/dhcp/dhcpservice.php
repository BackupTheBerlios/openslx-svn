<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcpservice.dwt";

include('dhcp_header.inc.php');

$mnr = 0; 
$sbmnr = -1;

###################################################################################

$mnr = $_GET['mnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

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

# LEASE Times Select
$leasetimes = array(array("600","10 min"),
						  array("900","15 min"),
						  array("1800","30 min"),
						  array("3600","1 h"),
						  array("7200","2 h"),
						  array("18000","5 h"),
						  array("36000","10 h"),
						  array("86400","1 Tag"),
						  array("172800","2 Tage"),
						  array("345600","4 Tage"));

# DHCP Service Daten						
$dhcpsv_array = get_dhcpservices($auDN,array("dn","cn"));
$dhcpserviceDN = $dhcpsv_array[0]['dn'];
$attributes = array("dn","cn","dhcpprimarydn","dhcpsecondarydn","description","dhcpofferdn","dhcpstatements","dhcpfailoverpeer",
                     "dhcpoptallow","dhcpoptddns-update-style","dhcpoptdefault-lease-time","dhcpoptdeny","dhcpoptfilename",
							"dhcpoptignore","dhcppermittedclients","dhcpoptmax-lease-time","dhcpoptnext-server","optiondefinition",
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

############################################## 
# max lease time
$maxleasetimes = $leasetimes;
$maxlease_select = "<select name='attribs[dhcpoptmax-lease-time]' size='4' class='small_form_selectbox'>";
if ( !$dhcpsv_data['dhcpoptmax-lease-time'] ) {
	$maxlease_select .= "<option value='' selected> ------- </option>";
	foreach ($maxleasetimes as $sec) {
		$maxlease_select .= "<option value='$sec[0]'>$sec[1] &nbsp;[$sec[0] s]</option>";
	}
}
else{
	for ($i=0; $i < count($maxleasetimes); $i++){ 
		if ( $maxleasetimes[$i][0] == $dhcpsv_data['dhcpoptmax-lease-time'] ){
			$maxlease_select .= "
				<option value='".$maxleasetimes[$i][0]."' selected>".$maxleasetimes[$i][1]." &nbsp;[".$maxleasetimes[$i][0]." s]</option>
				<option value=''> ------- </option>";			
			array_splice($maxleasetimes, $i, 1);
			break;
		}
	}
	foreach ($maxleasetimes as $sec) {
		$maxlease_select .= "<option value='$sec[0]'>$sec[1] &nbsp;[$sec[0] s]</option>";
	}
}
$maxlease_select .= "</select>
	<input type='hidden' name='oldattribs[dhcpoptmax-lease-time]' value='".$dhcpsv_data['dhcpoptmax-lease-time']."'>";

# default lease time
$defaultleasetimes = $leasetimes;
$defaultlease_select = "<select name='attribs[dhcpoptdefault-lease-time]' size='4' class='small_form_selectbox'>";
if ( !$dhcpsv_data['dhcpoptdefault-lease-time'] ) {
	$defaultlease_select .= "<option value='' selected> ------- </option>";
	foreach ($defaultleasetimes as $sec) {
		$defaultlease_select .= "<option value='$sec[0]'>$sec[1] &nbsp;[$sec[0] s]</option>";
	}
}
else{
	for ($i=0; $i < count($defaultleasetimes); $i++){ 
		if ( $defaultleasetimes[$i][0] == $dhcpsv_data['dhcpoptdefault-lease-time'] ){
			$defaultlease_select .= "
				<option value='".$defaultleasetimes[$i][0]."' selected>".$defaultleasetimes[$i][1]." &nbsp;[".$defaultleasetimes[$i][0]." s]</option>
				<option value=''> ------- </option>";			
			array_splice($defaultleasetimes, $i, 1);
			break;
		}
	}
	foreach ($defaultleasetimes as $sec) {
		$defaultlease_select .= "<option value='$sec[0]'>$sec[1] &nbsp;[$sec[0] s]</option>";
	}
}
$defaultlease_select .= "</select>
	<input type='hidden' name='oldattribs[dhcpoptdefault-lease-time]' value='".$dhcpsv_data['dhcpoptdefault-lease-time']."'>";	

############################################
# Permitted Clients
$pcl = "";
#echo $dhcpsv_data['dhcppermittedclients'];
if ($dhcpsv_data['dhcppermittedclients'] == "deny unknown-clients") {
	$pcl = $dhcpsv_data['dhcppermittedclients'];
	$pcl_select .= "<input type='radio' name='pcl' value='$pcl' checked>&nbsp; <b>deny unknown-clients &nbsp;&nbsp;(Nur im DHCP eingetragene Clients)</b><br>";
	$pcl_select .= "<input type='radio' name='pcl' value=''>&nbsp; allow unknown-clients &nbsp;&nbsp;(Beliebige Clients)";
}
else {
	$pcl_select .= "<input type='radio' name='pcl' value='' checked>&nbsp; <b>allow unknown-clients &nbsp;&nbsp;(Beliebige Clients - default)</b><br>";
	$pcl_select .= "<input type='radio' name='pcl' value='deny unknown-clients'>&nbsp; deny unknown-clients &nbsp;&nbsp;(Nur im DHCP eingetragene Clients)";
}
#################

$template->assign(array("DHCPDN" => $dhcpsv_data['dn'],
								"DHCPDN" => $DHCP_SERVICE,
								"CN" => $dhcpcn,
								"PRIMARY" => $dhcpsv_data['dhcpprimarydn'],
								"SECONDARY" => $dhcpsv_data['dhcpsecondarydn'],
								"DESCRIPTION" => $dhcpsv_data['description'],
								"STATEMENTS" => $dhcpsv_data['dhcpstatements'],
								"FAILOVERPEER" => $dhcpsv_data['dhcpfailoverpeer'],
								"PCLSELECT" => $pcl_select,
								"PCL" => $pcl,
								"ALLOW" => $dhcpsv_data['dhcpoptallow'],
								"DENY" => $dhcpsv_data['dhcpoptdeny'],
								"IGNORE" => $dhcpsv_data['dhcpoptignore'],
								"DDNSUPDATE" => $dhcpsv_data['dhcpoptddns-update-style'],
								"DEFAULTLEASE" => $defaultlease_select,
								"MAXLEASE" => $maxlease_select,
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
$dhcpobjects = get_service_subnets($dhcpserviceDN, array("dn","cn","dhcpoptnetmask","description"));
#print_r($dhcpobjects);
$dhcpobjects = array_natsort($dhcpobjects, "cn", "cn");
$template->define_dynamic("Dhcpsubnets", "Webseite");
foreach ($dhcpobjects as $subnet){
	$template->assign(array("SUBNET" => $subnet['cn'],
									"NETMASK" => $subnet['dhcpoptnetmask'],
									"SUBNETAU" => $subnet['auDN'],
									"SUBNETDESC" => $subnet['description']));
	$template->parse("DHCPSUBNETS_LIST", ".Dhcpsubnets");
}

# alle DHCP Objekte auf sich als DHCP Service setzen
$altdhcpservices = alternative_dhcpservices($DHCP_SERVICE);
$template->define_dynamic("Altdhcpsrv", "Webseite");
$dhcp_selectbox = "";
foreach ($altdhcpservices as $altsrv){
	$dhcp_selectbox .= "
   		   <option value='".$altsrv['dn']."'>".$altsrv['cn']." </option>";
	$template->assign(array("ALTDHCPSRV" => $dhcp_selectbox));
}

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