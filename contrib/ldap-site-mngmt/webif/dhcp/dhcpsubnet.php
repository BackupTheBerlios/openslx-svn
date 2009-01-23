<?php

include('../standard_header.inc.php');

$dhcpsubnetDN = $_GET['dn'];
# Dateiname und evtl. Pfad des Templates für die Webseite
#$subexpdn = array_slice(ldap_explode_dn($dhcpsubnetDN , 1),3);
$subexpdn_atts = array_slice(ldap_explode_dn($dhcpsubnetDN , 0),3);
$subnetaudn = implode(",",$subexpdn_atts);
#$auexpdn = array_slice(ldap_explode_dn($auDN , 1),1);
#print_r($subnetaudn);echo"<br>";
#print_r($subexpdn);echo"<br>";
#print_r($auexpdn);echo"<br>";
#print_r($all_roles[$subnetaudn]['roles']);
$subnetadmin = 0;
if ($all_roles[$subnetaudn]['roles']) {
	foreach ($all_roles[$subnetaudn]['roles'] as $role) {
		switch ($role){ 
		case 'MainAdmin':
			$subnetadmin = 1;
			break;
		case 'DhcpAdmin':
			$subnetadmin = 1;
			break;
		}
	}
}
#if (count($subexpdn) < count($auexpdn)){
if ($subnetadmin){
	#echo "ADMIN<br>";
	$webseite = "dhcpsubnet.dwt";
	$form_element = "";
}else{
	# readonly
	#echo "NOADMIN<br>";
	$webseite = "dhcpsubnet_ro.dwt";
	$form_element = "disabled";
}

include('dhcp_header.inc.php');

$mnr = -1; 
$sbmnr = -1;

###################################################################################
					

$mnr = $_GET['mnr'];	
#$sbmnr = $_GET['sbmnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$template->assign(array("SUBNETDN" => "",
								"CN" => "",
								"NETMASK" => "",
								"DHCPADDON" => "",
								"DESCRIPTION" => "",
								"ALLOW" => "",
								"DENY" => "",
								"IGNORE" => "",
								"DEFAULTLEASE" => "",
								"MAXLEASE" => "",
								"BROADCAST" => "",
								"ROUTERS" => "",
								"DOMAINNAME" => "",
								"DOMAINNAMESERVERS" => "",
								"UCSELECT",
								"NEXTSERVER" => "",
								"FILENAME" => "",
								"OPTGENERIC" => "",
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr,
           		       	"MCNR" => $mcnr));

# DHCP Subnet Daten
$attributes = array("dn","cn","dhcpoptnetmask","dhcphlpcont","description",
							"dhcpoptdefault-lease-time","dhcpoptmax-lease-time","dhcpoptallow",
							"dhcpoptdeny","dhcpoptignore","hlprbservice","dhcpoptnext-server","dhcpoptfilename",
							"dhcpoptbroadcast-address","dhcpoptdomain-name","dhcpoptdomain-name-servers",
							"dhcpoptgeneric","dhcpoptrouters","dhcpoptget-lease-hostnames","dhcppermittedclients");
$subnet_data = get_node_data($dhcpsubnetDN, $attributes);
#print_r($subnet_data);

# DHCP Data one scope up (Global)
$global_options = array("dhcpoptdefault-lease-time","dhcpoptmax-lease-time","dhcpoptallow",
							"dhcpoptdeny","dhcpoptignore","hlprbservice","dhcpoptnext-server","dhcpoptfilename",
							"dhcpoptdomain-name","dhcpoptdomain-name-servers",
							"dhcpoptgeneric","dhcpoptget-lease-hostnames","dhcppermittedclients");
$global_data = get_node_data($subnet_data['dhcphlpcont'],$global_options);

# DHCP Service Eintrag
if ($subnet_data['dhcphlpcont']){
	$dhcpsrv_checkbox = "<input type='checkbox' name='dhcpservice' value= '".$DHCP_SERVICE."'checked $form_element>";
	$dhcpsrv_radio = "<input type='radio' name='dhcpservice' value='".$DHCP_SERVICE."' checked> ja &nbsp;&nbsp;&nbsp;
							<input type='radio' name='dhcpservice' value=''> nein";
}else{
	$dhcpsrv_checkbox = "<input type='checkbox' name='dhcpservice' value= '".$DHCP_SERVICE."' $form_element>";
   $dhcpsrv_radio = "<input type='radio' name='dhcpservice' value='".$DHCP_SERVICE."'> ja &nbsp;&nbsp;&nbsp;
							<input type='radio' name='dhcpservice' value='' checked> nein";
}

# Subnet Domain Zuordnung
$all_childs = get_childau_sub($auDN,array("dn","ou","maxipblock","associateddomain"));
$childs = get_subnet_childaus($all_childs,$subnet_data['cn']);
foreach ($childs as $au){
	$subnet_domains [] = $au['zone'];
}
$subnet_domains = array_unique($subnet_domains);
#print_r($subnet_domains);

# Domainnameservers, globale Option des Dienstes
$domainnameservers = $global_data['dhcpoptdomain-name-servers'];



# Globale Optionen anzeigen falls Subnet Option nicht gesetzt
if (!$subnet_data['dhcpoptget-lease-hostnames']) {
	$get_lease_hostnames = $global_data['dhcpoptget-lease-hostnames'];
}else{
	$get_lease_hostnames = $subnet_data['dhcpoptget-lease-hostnames'];
}
$dhcpoptallow = "";
if ( $subnet_data['dhcpoptallow'] != "unknown-clients") {
	$dhcpoptallow = $subnet_data['dhcpoptallow'];
}
$dhcpoptdeny = "";
if ( $subnet_data['dhcpoptdeny'] != "unknown-clients") {
	$dhcpoptdeny = $subnet_data['dhcpoptdeny'];
}
$dhcpoptignore = "";
if ( $subnet_data['dhcpoptignore'] != "unknown-clients") {
	$dhcpoptignore = $subnet_data['dhcpoptignore'];
}



###################################
# EXTRA Settings aus File Struktur
$dhcp_dir = implode("/",array_reverse(array_slice(ldap_explode_dn($subnet_data[dn],1),1,-3)));
$dhcp_file = $DHCP_FS_ROOT."/".$dhcp_dir."/dhcp.settings";
#print $dhcp_file; echo "<br>";
#$fh = fopen ($dhcp_file, "r");
#while (!feof($fh)) {
#	$buffer = fgets($fh, 4096);
#	echo nl2br(str_replace(" ","&nbsp;",$buffer));
#}
#fclose ($fh);
$string = file_get_contents($dhcp_file);
if ($string) {
	$dhcp_addon = "<tr>
  			<td colspan='2'>
	  		<table cellpadding='7' cellspacing='0' border='1' align='left' width='90%' style='border-width: 3 3 3 3;'>
				<tr>
					<td class='tab_dgrey'><b>Aktive Extra DHCP Settings</b> von Subnetz $subnet_data[cn] &nbsp;&nbsp; <b>(File Struktur)</b></td>
				</tr>	
				<tr valign='top'>
				<td class='tab_dgrey'>";
	$dhcp_addon .= nl2br(str_replace(" ","&nbsp;",$string));
	$dhcp_addon .= "</td>
				</tr>
			</table>
			</td>
  		</tr>
  		<tr>
			<td height='20' colspan='2'></td>
		</tr>";
}
#####################################
						  
############################################
# max lease time
$subnet_ml = $subnet_data['dhcpoptmax-lease-time'];
$global_ml = $global_data['dhcpoptmax-lease-time'];
$mldata = "&nbsp;";
$ml_ro = "&nbsp;";
$maxleasetimes = $LEASE_TIMES;
$maxlease_select = "<select name='attribs[dhcpoptmax-lease-time]' size='4' class='small_form_selectbox'>";
if ( !$subnet_data['dhcpoptmax-lease-time'] ) {
	if ( !$global_data['dhcpoptmax-lease-time'] ) {
		$maxlease_select .= "<option value='' selected> ------- </option>";
		foreach (array_keys($maxleasetimes) as $sec) {
			$maxlease_select .= "<option value='$sec'>$maxleasetimes[$sec] &nbsp;[$sec s]</option>";
		}
	}else{
		$maxlease_select .= "
					<option value='' selected>".$maxleasetimes[$global_data['dhcpoptmax-lease-time']]." &nbsp;[".$global_data['dhcpoptmax-lease-time']." s]</option>
					<option value=''> ------- </option>";			
		foreach (array_keys($maxleasetimes) as $sec) {
			if ( $sec != $global_data['dhcpoptmax-lease-time'] ){
				$maxlease_select .= "<option value='$sec'>$maxleasetimes[$sec] &nbsp;[$sec s]</option>";
			}
		}
		$mldata = "<br><b>Global vom DHCP Dienst vorgegeben</b><br>
			Sie k&ouml;nnen spezifisch f&uuml;r das Subnetz eine andere <b>maximale</b> Lease-Time setzen";
		$ml_ro = $global_ml." (Global vom DHCP Dienst vorgegeben)";
	}
}
else{
	$maxlease_select .= "
					<option value='$subnet_ml' selected>".$maxleasetimes[$subnet_data['dhcpoptmax-lease-time']]." &nbsp;[".$subnet_data['dhcpoptmax-lease-time']." s]</option>
					<option value=''> ------- </option>";
	foreach (array_keys($maxleasetimes) as $sec) {
		if ( $sec != $subnet_data['dhcpoptmax-lease-time'] ){
			if ( $sec == $global_data['dhcpoptmax-lease-time'] ) {
				# nur anzeigen zur auswahl, aber value leer da schon globale option (muss nicht eingetragen werden)
				$maxlease_select .= "<option value=''>$maxleasetimes[$sec] &nbsp;[$sec s]</option>";
			}else{
				$maxlease_select .= "<option value='$sec'>$maxleasetimes[$sec] &nbsp;[$sec s]</option>";
			}
		}
	}
	$ml_ro = $subnet_ml;	
}
$maxlease_select .= "</select>
	<input type='hidden' name='oldattribs[dhcpoptmax-lease-time]' value='".$subnet_data['dhcpoptmax-lease-time']."'>";

############################################
# default lease time
$subnet_dl = $subnet_data['dhcpoptdefault-lease-time'];
$global_dl = $global_data['dhcpoptdefault-lease-time'];
$dldata = "&nbsp;";
$dl_ro = "&nbsp;";
$defaultleasetimes = $LEASE_TIMES;
$defaultlease_select = "<select name='attribs[dhcpoptdefault-lease-time]' size='4' class='small_form_selectbox'>";
if ( !$subnet_data['dhcpoptdefault-lease-time'] ) {
	if ( !$global_data['dhcpoptdefault-lease-time'] ) {
		$defaultlease_select .= "<option value='' selected> ------- </option>";
		foreach (array_keys($defaultleasetimes) as $sec) {
			$defaultlease_select .= "<option value='$sec'>$defaultleasetimes[$sec] &nbsp;[$sec s]</option>";
		}
	}else{
		$defaultlease_select .= "
					<option value='' selected>".$defaultleasetimes[$global_data['dhcpoptdefault-lease-time']]." &nbsp;[".$global_data['dhcpoptdefault-lease-time']." s]</option>
					<option value=''> ------- </option>";			
		foreach (array_keys($defaultleasetimes) as $sec) {
			if ( $sec != $global_data['dhcpoptdefault-lease-time'] ){
				$defaultlease_select .= "<option value='$sec'>$defaultleasetimes[$sec] &nbsp;[$sec s]</option>";
			}
		}
		$dldata = "<br><b>Globale Option des DHCP Dienstes</b><br>
			Sie k&ouml;nnen spezifisch f&uuml;r das Subnetz eine andere <b>Default</b> Lease-Time setzen";
		$dl_ro = $global_dl." (Globale Option des DHCP Dienstes)";
	}
}
else{
	$defaultlease_select .= "
					<option value='$subnet_dl' selected>
						".$defaultleasetimes[$subnet_data['dhcpoptdefault-lease-time']]." &nbsp;[".$subnet_data['dhcpoptdefault-lease-time']." s]</option>
					<option value=''> ------- </option>";
	foreach (array_keys($defaultleasetimes) as $sec) {
		if ( $sec != $subnet_data['dhcpoptdefault-lease-time'] ){
			if ( $sec == $global_data['dhcpoptdefault-lease-time'] ) {
				# nur anzeigen zur auswahl, aber value leer da schon globale option (muss nicht eingetragen werden)
				$defaultlease_select .= "<option value=''>$defaultleasetimes[$sec] &nbsp;[$sec s]</option>";
			}else{
				$defaultlease_select .= "<option value='$sec'>$defaultleasetimes[$sec] &nbsp;[$sec s]</option>";
			}
		}
	}
	$dl_ro = $subnet_dl;	
}
$defaultlease_select .= "</select>
	<input type='hidden' name='oldattribs[dhcpoptdefault-lease-time]' value='".$subnet_data['dhcpoptdefault-lease-time']."'>";	

############################################
# Get-Lease-Hostnames - Radio Buttons
if ( $get_lease_hostnames == "on") {
	$glhost_radio = "<input type='radio' name='attribs[dhcpoptget-lease-hostnames]' value='on' checked $form_element> on &nbsp;&nbsp;&nbsp;
							<input type='radio' name='attribs[dhcpoptget-lease-hostnames]' value='off' $form_element> off
							<input type='hidden' name='oldattribs[dhcpoptget-lease-hostnames]' value='on'>";
}else{
	$glhost_radio = "<input type='radio' name='attribs[dhcpoptget-lease-hostnames]' value='on' $form_element> on &nbsp;&nbsp;&nbsp;
							<input type='radio' name='attribs[dhcpoptget-lease-hostnames]' value='off' checked $form_element> off
							<input type='hidden' name='oldattribs[dhcpoptget-lease-hostnames]' value='off'>";
}

############################################
# Permitted Clients
if (!$global_data['dhcppermittedclients']) {
	
	if ($subnet_data['dhcppermittedclients']) {
		$pcl = "deny unknown-clients";
		$pcl_select .= "<input type='radio' name='pcl' value='$pcl' checked>
							&nbsp; <b>Nur im DHCP eingetragene Clients (deny unknown-clients)</b><br>";
		$pcl_select .= "<input type='radio' name='pcl' value=''>&nbsp; Beliebige Clients (allow unknown-clients)";
	}
	else{
		$pcl = "";
		$pcl_select .= "<input type='radio' name='pcl' value='$pcl' checked>
							&nbsp; <b>Beliebige Clients (allow unknown-clients)</b><br>";
		$pcl_select .= "<input type='radio' name='pcl' value='deny unknown-clients'>
							&nbsp; Nur im DHCP eingetragene Clients (deny unknown-clients)";
	}
	$pcl_select .= "<input type='hidden' name='oldpcl' value='$pcl'>";
	
}
else{
	$pcl_select = "<b>Nur im DHCP eingetragene Clients (deny unknown-clients)</b><br>Globale Option des DHCP Dienstes";
}
/*
if ($global_data['dhcppermittedclients'] == 'deny unknown-clients') {

}
else{

}

$pcl = "";
$pclself = "";
$pcldata = "";

echo "Subnet PCL: ".$subnet_data['dhcppermittedclients']."<br>";
echo "GLOBAL PCL: ".$global_data['dhcppermittedclients']."<br>";
if ($subnet_data['dhcppermittedclients']) {
	$pcl = $subnet_data['dhcppermittedclients'];
	$pclself = $pcl;
}
elseif ($global_data['dhcppermittedclients']) {
	$pcl = $global_data['dhcppermittedclients'];
	$pcldata = "<br><b>Globale Option des DHCP Dienstes</b><br>
			Sie k&ouml;nnen spezifisch f&uuml;r das Pool einen anderen Wert setzen";
}
else{
	# default wert
	$pcl = "allow unknown-clients";
}
echo "PCL: ".$pcl."<br>";
echo "PCLSELF: ".$pclself."<br>";
if ($pcl == "deny unknown-clients") {
	$pcl_select .= "<input type='radio' name='pcl' value='$pclself' checked>&nbsp; <b>Im DHCP eingetragene Clients (deny unknown-clients)</b></option><br>";
	if ($global_data['dhcppermittedclients'] == "" || $global_data['dhcppermittedclients'] == "allow unknown-clients" ) {
		$pcl_select .= "<input type='radio' name='pcl' value=''>&nbsp; Beliebige Clients (allow unknown-clients)</option>";
	}else{
		$pcl_select .= "<input type='radio' name='pcl' value='allow unknown-clients'>&nbsp; Beliebige Clients (allow unknown-clients)</option>";
	}
}
#elseif ($pcl == "allow members of \"$au_ou\"") {
#	$pcl_select .= "<option value='$pclself' selected>Nur Clients eigener AU (allow members of \"$au_ou\")</option>";
#}
else {
	$pcl_select .= "<input type='radio' name='pcl' value='$pclself' checked>&nbsp; <b>Beliebige Clients (allow unknown-clients)</b></option><br>";
	if ( $global_data['dhcppermittedclients'] == "deny unknown-clients" ) {
		$pcl_select .= "<input type='radio' name='pcl' value=''>&nbsp; Im DHCP eingetragene Clients (deny unknown-clients)</option>";
	}else{
		$pcl_select .= "<input type='radio' name='pcl' value='deny unknown-clients'>&nbsp; Im DHCP eingetragene Clients (deny unknown-clients)</option>";
	}
}
*/

#####################################
# RBS Setup
$rbsDN = $subnet_data['hlprbservice'];
$rbs_data = "&nbsp;";
$rbs_ro = "&nbsp;";
if ($rbsDN != "") {
	$altrbs = alternative_rbservices($rbsDN);
	$selectsize = count($altrbs) + 2;
	$rbs_selectbox = "<select name='rbs' size='$selectsize' class='form_200_selectbox'>";
   $exprbs = ldap_explode_dn($rbsDN, 1);
	$nextserver = $subnet_data['dhcpoptnext-server'];
	$filename = $subnet_data['dhcpoptfilename'];
   $rbs_data = "<br>DHCP <b>next-server</b>: $nextserver<br>DHCP <b>filename</b>: $filename";
	$rbs_selectbox .= "<option selected value='".$rbsDN."'>$exprbs[0] / $exprbs[2]</option>
	   			        <option value=''>--- Kein RBS ---</option>";
	$rbs_ro = "$exprbs[0] / $exprbs[2]";
} else {
	
	if ( $global_data['hlprbservice'] ) {
	   $altrbs = alternative_rbservices($global_data['hlprbservice']);
	   $selectsize = count($altrbs) + 2;
	   $rbs_selectbox = "<select name='rbs' size='$selectsize' class='form_200_selectbox'>";
		$nextserver = $global_data['dhcpoptnext-server'];
		$filename = $global_data['dhcpoptfilename'];
		$exprbs = ldap_explode_dn($global_data['hlprbservice'], 1);
   	$rbs_data = "<b>Globale RBS Option des DHCP Dienstes:</b><br>
   		DHCP <b>next-server</b>: $nextserver<br>DHCP <b>filename</b>: $filename";
		$rbs_selectbox .= "<option selected value=''>$exprbs[0] / $exprbs[2]</option>
	   			        <option value=''>--- Kein RBS ---</option>";
	   $rbs_ro = "$exprbs[0] / $exprbs[2]";
	}else{
		$altrbs = alternative_rbservices($rbsDN);
		$selectsize = count($altrbs) + 1;
		$rbs_selectbox .= "<select name='rbs' size='$selectsize' class='form_200_selectbox'> 
	   			            <option selected value=''>--- Kein RBS ---</option>";
	}
}

if (count($altrbs) != 0){
   foreach ($altrbs as $item){
      $rbs_selectbox .= "<option value='".$item['dn']."'>".$item['cn']." ".$item['au']."</option>";
   }
}
$rbs_selectbox .= "<input type='hidden' name='oldrbs' value='$rbsDN'></select>";


$template->assign(array("SUBNETDN" => $dhcpsubnetDN,
								"SUBNETAUDN" => $subnetaudn,
								"CN" => $subnet_data['cn'],
								"NETMASK" => $subnet_data['dhcpoptnetmask'],
								"DHCPADDON" => $dhcp_addon,
								"DESCRIPTION" => $subnet_data['description'],
								"DHCPSVDN" => $DHCP_SERVICE,
								"DHCPSRV_RADIO" => $dhcpsrv_checkbox,
								"DHCPNOW" => $subnet_data['dhcphlpcont'],
								"BROADCAST" => $subnet_data['dhcpoptbroadcast-address'],
								"ROUTERS" => $subnet_data['dhcpoptrouters'],
								"DOMAINNAME" => $subnet_data['dhcpoptdomain-name'],
								"DOMAINNAMESERVERS" => $domainnameservers,
								"DEFAULTLEASE" => $defaultlease_select,
								"MAXLEASE" => $maxlease_select,								
								"DLDATA" => $dldata,
								"MLDATA" => $mldata,
								"DLRO" => $dl_ro,
								"MLRO" => $ml_ro,					
								"GETLEASEHN" => $glhost_radio,
								"PCLSELECT" => $pcl_select,
								"PCLSELF" => $pclself,
								"PCLDATA" => $pcldata,
								"UCSELECT" => $ucselectbox,
								"UCTEXT" => $uctext,
								"UCNOW" => $unknownclients,
								"ALLOW" => $dhcpoptallow,
								"DENY" => $dhcpoptdeny,
								"IGNORE" => $dhcpoptignore,
								"RBSSELECT" => $rbs_selectbox,
								"RBSDATA" => $rbs_data,
								"RBSRO" => $rbs_ro,
								"OPTGENERIC" => $subnet_data['dhcpoptgeneric'],
           		       	"MNR" => $mnr,
           		       	"SBMNR" => $sbmnr,
           		       	"MCNR" => $mcnr,
           		       	"ADMINCONTACT" => $ADMIN_EMAIL));

###################################################################################

include("dhcp_footer.inc.php");

?>