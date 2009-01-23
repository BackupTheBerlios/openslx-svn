<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcppool_one.dwt";

include('dhcp_header.inc.php');

$mnr = 3; 
$sbmnr = -1;

###################################################################################

$mnr = $_GET['mnr'];
$sbmnr = $_GET['sbmnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

$poolDN = $_GET['dn'];
$backurl = $_GET['url'];

$template->assign(array("POOLDN" => $poolDN,
								"CN" => "",
								"POOLAU" => "",
								"DHCPADDON" => "",
								"SUBNETDN" => "",
								"SUBNET" => "",
								"SUBNETAU" => "",
								"RANGE1" => "",
								"RANGE2" => "",
								"DESCRIPTION" => "",
								"STATEMENTS" => "",
								"ALLOW" => "",
								"DENY" => "",
								"IGNORE" => "",
								"RBS" => "",
								"RBSSELECT" => "",
								"DEFAULTLEASE" => "",
								"MAXLEASE" => "",								
								"DLDATA" => $dldata,
								"MLDATA" => $mldata,
								"BACKURL" => $backurl,
           		       	"MNR" => $mnr));
#$template->define_dynamic("Dhcpranges", "Webseite");

# DHCP Pools Daten holen				
$attributes = array("dn","cn","dhcphlpcont","dhcprange","description","dhcpstatements","dhcpoptallow",
							"dhcpoptdefault-lease-time","dhcpoptdeny","dhcpoptignore","dhcpoptmax-lease-time","dhcpoptdomain-name",
							"dhcpoptgeneric","hlprbservice","dhcpoptfilename","dhcpoptnext-server","dhcppermittedclients");
#$pools = get_dhcppools($auDN, $attributes);
$pool = get_node_data($poolDN, $attributes);
$pooldnexp = ldap_explode_dn($poolDN, 1);
$poolauexp = array_slice($pooldnexp, 3);
$poolau = $poolauexp[0];
$exppooldn = ldap_explode_dn($poolDN,0);
$exppooldn = array_slice($exppooldn, 3);
$poolaudn = implode(',',$exppooldn);

$scope_attributes = array("dn","cn","dhcphlpcont","dhcpstatements","dhcpoptallow","dhcpoptdeny",
							"dhcpoptignore","dhcpoptdefault-lease-time","dhcpoptmax-lease-time",
							"dhcpoptgeneric","hlprbservice","dhcpoptfilename","dhcpoptnext-server","dhcppermittedclients");
							
$subnet_data = get_pool_subnet_data($pool['dhcprange'],$scope_attributes);
#print_r($subnet_data);
#$subnet_data = get_node_data($pool['dhcphlpcont'], $scope_attributes);
$global_data = get_node_data($DHCP_SERVICE, $scope_attributes);


###################
# DHCP Ranges
if (count($pool['dhcprange']) != 0){
   #$template->define_dynamic("Dhcpranges", "Webseite");
   if (count($pool['dhcprange']) > 1){
	foreach ($pool['dhcprange'] as $dhcprange){
	   $iprange = explode('_',$dhcprange);
		$template->assign(array(
								"RANGE1" => $iprange[0],
								"RANGE2" => $iprange[1],
                        "RPOOLDN" => $pool['dn']));
   	#$template->parse("DHCPRANGES_LIST", ".Dhcpranges");
	}
	}else{
	   $iprange = explode('_',$pool['dhcprange']);
	   $template->assign(array(
								"RANGE1" => $iprange[0],
								"RANGE2" => $iprange[1],
								"RPOOLDN" => $pool['dn']));
   	#$template->parse("DHCPRANGES_LIST", ".Dhcpranges");
	}
}

#######################################
# Option Domain Name
$opt_domain = "";
if ($pool['dhcpoptdomain-name']) {
$opt_domain = "<tr valign='top'>
				<td class='tab_d'><b>Domain Name</b></td>
				<td class='tab_d' colspan='2'>".
				      $pool['dhcpoptdomain-name']."
				</td>
			</tr>";
}


#######################################
# DHCP Subnet des Pools 
$subnet = ldap_explode_dn($subnet_data[dn],1);
$subnetdnexp = ldap_explode_dn($subnet_data[dn], 0);
$subnetauexp_atts = array_slice($subnetdnexp, 3);
$subnetauexp = array_slice($subnet, 3);

$subnetaudn = implode(',',$subnetauexp_atts);	
$rbsDN = $pool['hlprbservice'];

$subnetau = $subnetauexp[0];
#if ($subnetau != $poolau) {
	#$subnetau = "Subnet Administration - AU <code class=\"font_object\">$subnetauexp[0] </code>";
#}

# DHCP Subnet Eintrag
$subnet_aktiv = "";
if (!$subnet_data['dhcphlpcont']){
	$subnet_aktiv = " &nbsp; DHCP Subnet momentan nicht aktiv!"; 
}
if ($pool['dhcphlpcont']){
	$dhcpsrv_checkbox = "<input type='checkbox' name='subnetdn' value= '".$subnet_data[dn]."'checked $form_element> $subnet_aktiv";
}else{
	$dhcpsrv_checkbox = "<input type='checkbox' name='subnetdn' value= '".$subnet_data[dn]."' $form_element> $subnet_aktiv";
}


########################################
# EXTRA DHCP Settings aus Filestruktur
$dhcp_dir = implode("/",array_reverse(array_slice(ldap_explode_dn($poolDN,1),1,-3)));
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
					<td class='tab_dgrey'><b>Aktive Extra DHCP Settings</b> von Pool $iprange[0] - $iprange[1] &nbsp;&nbsp; <b>(File Struktur)</b></td>
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


############################################
# Permitted Clients

if (!$global_data['dhcppermittedclients']) {
	
	if (!$subnet_data['dhcppermittedclients']) {
	
		if ($pool['dhcppermittedclients']) {
			$pcl = "deny unknown-clients";
			$pcl_select .= "<input type='radio' name='pcl' value='$pcl' checked>
								&nbsp; <b>Im DHCP eingetragene Clients (deny unknown-clients)</b><br>";
			$pcl_select .= "<input type='radio' name='pcl' value=''>&nbsp; Beliebige Clients (allow unknown-clients)";
		}
		else{
			$pcl = "";
			$pcl_select .= "<input type='radio' name='pcl' value='$pcl' checked>
								&nbsp; <b>Beliebige Clients (allow unknown-clients)</b><br>";
			$pcl_select .= "<input type='radio' name='pcl' value='deny unknown-clients'>
								&nbsp; Im DHCP eingetragene Clients (deny unknown-clients)";
		}
		$pcl_select .= "<input type='hidden' name='oldpcl' value='$pcl'>";
		
	}
	else{
		$pcl_select = "<b>Nur im DHCP eingetragene Clients (deny unknown-clients)</b><br>Option des DHCP Subnets";
	}
}
else{
	$pcl_select = "<b>Nur im DHCP eingetragene Clients (deny unknown-clients)</b><br>Globale Option des DHCP Dienstes";
}

/*
$pcl = "";
$pclself = "";
$pcldata = "";
#echo $pool['dhcppermittedclients'];
if ($pool['dhcppermittedclients']) {
	$pcl = $pool['dhcppermittedclients'];
	$pclself = $pcl;
}
#elseif ($subnet_data['dhcppermittedclients']) {
#	$pcl = $subnet_data['dhcppermittedclients'];
#	$pcldata = "<br><b>Option des DHCP Subnets</b><br>
#			Sie k&ouml;nnen spezifisch f&uuml;r den Pool einen anderen Wert setzen";
#}
elseif ($global_data['dhcppermittedclients']) {
	$pcl = $global_data['dhcppermittedclients'];
	$pcldata = "<br><b>Globale Option des DHCP Dienstes</b><br>
			Sie k&ouml;nnen spezifisch f&uuml;r das Pool einen anderen Wert setzen";
}
else{
	# default wert
	$pcl = "allow unknown-clients";
}
#if ( $subnet_data['dhcppermittedclients'] ) {
#	$next_scope_pcl = $subnet_data['dhcppermittedclients'];
#}else{
	$next_scope_pcl = $global_data['dhcppermittedclients'];
#}

if ($pcl == "deny unknown-clients") {
	$pcl_select .= "<input type='radio' name='pcl' value='$pclself' checked>&nbsp; <b>Im DHCP eingetragene Clients (deny unknown-clients)</b></option><br>";
	if ($next_scope_pcl == "" || $next_scope_pcl == "allow unknown-clients" ) {
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
	if ( $next_scope_pcl == "deny unknown-clients" ) {
		$pcl_select .= "<input type='radio' name='pcl' value=''>&nbsp; Im DHCP eingetragene Clients (deny unknown-clients)</option>";
	}else{
		$pcl_select .= "<input type='radio' name='pcl' value='deny unknown-clients'>&nbsp; Im DHCP eingetragene Clients (deny unknown-clients)</option>";
	}
}
*/

############################################
# default lease time
$defaultleasetimes = $LEASE_TIMES;
$defaultlease_select = "<select name='attribs[dhcpoptdefault-lease-time]' size='4' class='small_form_selectbox'>";
$dl = "";
$dlself = "";
$dldata = "&nbsp;";

if ($pool['dhcpoptdefault-lease-time']) {
	$dl = $pool['dhcpoptdefault-lease-time'];
	$dlself = $dl;
}
elseif ($subnet_data['dhcpoptdefault-lease-time']) {
	$dl = $subnet_data['dhcpoptdefault-lease-time'];
	$dldata = "<br><b>Option des DHCP Subnets</b><br>
			Sie k&ouml;nnen spezifisch f&uuml;r den Pool eine andere <b>default</b> Lease-Time setzen";
}
elseif ($global_data['dhcpoptdefault-lease-time']) {
	$dl = $global_data['dhcpoptdefault-lease-time'];
	$dldata = "<br><b>Globale Option des DHCP Dienstes</b><br>
			Sie k&ouml;nnen spezifisch f&uuml;r das Pool eine andere <b>default</b> Lease-Time setzen";
}
#echo "$dlself <br><br>";
if ($dl) {
	$defaultlease_select .= "<option value='$dlself' selected>".$defaultleasetimes[$dl]." &nbsp;[".$dl." s]</option>";
	$defaultlease_select .= "<option value=''> ------- </option>";
}else{
	$defaultlease_select .= "<option selected value=''> ------- </option>";
}
# resliche Werte für Auswahlliste, allerdings dabei Werte die im nächst höheren
# geltenden Scope entsprechen, erhalten value='' da sie nicht gesetzt werden müssen ... 
if ( $subnet_data['dhcpoptdefault-lease-time'] ) {
	$next_scope_dl = $subnet_data['dhcpoptdefault-lease-time'];
}else{
	$next_scope_dl = $global_data['dhcpoptdefault-lease-time'];
}
foreach (array_keys($defaultleasetimes) as $sec) {
	if ( $sec != $dl ){
		if ( $sec == $next_scope_dl ) {
			$defaultlease_select .= "<option value=''>$defaultleasetimes[$sec] &nbsp;[$sec s]</option>";
		}else{
			$defaultlease_select .= "<option value='$sec'>$defaultleasetimes[$sec] &nbsp;[$sec s]</option>";
		}
	}
}
$defaultlease_select .= "</select>
	<input type='hidden' name='oldattribs[dhcpoptdefault-lease-time]' value='".$dlself."'>";

################## 
# max lease time
$maxleasetimes = $LEASE_TIMES;
$maxlease_select = "<select name='attribs[dhcpoptmax-lease-time]' size='4' class='small_form_selectbox'>";
$mlself = "";
$mldata = "&nbsp;";

if ($pool['dhcpoptmax-lease-time']) {
	$ml = $pool['dhcpoptmax-lease-time'];
	$mlself = $ml;
}
elseif ($subnet_data['dhcpoptmax-lease-time']) {
	$ml = $subnet_data['dhcpoptmax-lease-time'];
	$mldata = "<br><b>Option des DHCP Subnets</b><br>
			Sie k&ouml;nnen spezifisch f&uuml;r den Pool eine andere <b>maximale</b> Lease-Time setzen";
}
elseif ($global_data['dhcpoptmax-lease-time']) {
	$ml = $global_data['dhcpoptmax-lease-time'];
	$mldata = "<br><b>Globale Option des DHCP Dienstes</b><br>
			Sie k&ouml;nnen spezifisch f&uuml;r das Pool eine andere <b>maximale</b> Lease-Time setzen";
}
else{
	$ml = "";
}

if ($ml) {
	$maxlease_select .= "<option value='".$mlself."' selected>".$maxleasetimes[$ml]." &nbsp;[".$ml." s]</option>";
	$maxlease_select .= "<option value=''> ------- </option>";
}else{
	$maxlease_select .= "<option selected value=''> ------- </option>";
}
# resliche Werte für Auswahlliste, allerdings dabei Werte die im nächst höheren
# geltenden Scope entsprechen, erhalten value='' da sie nicht gesetzt werden müssen ... 
if ( $subnet_data['dhcpoptmax-lease-time'] ) {
	$next_scope_ml = $subnet_data['dhcpoptmax-lease-time'];
}else{
	$next_scope_ml = $global_data['dhcpoptmax-lease-time'];
}
foreach (array_keys($maxleasetimes) as $sec) {
	if ( $sec != $ml ){
		if ( $sec == $next_scope_ml ) {
			$maxlease_select .= "<option value=''>$maxleasetimes[$sec] &nbsp;[$sec s]</option>";
		}else{
			$maxlease_select .= "<option value='$sec'>$maxleasetimes[$sec] &nbsp;[$sec s]</option>";
		}
	}
}
$maxlease_select .= "</select>
	<input type='hidden' name='oldattribs[dhcpoptmax-lease-time]' value='".$mlself."'>";


#################################
# RBS Setup
$rbsDN = "";
$rbs_data = "&nbsp;";
$rbsself = "";

if ($pool['hlprbservice']) {
	$rbsDN = $pool['hlprbservice'];
	$nextserver = $pool['dhcpoptnext-server'];
	$filename = $pool['dhcpoptfilename'];
	$rbsself = $rbsDN;
}else{
	if ($subnet_data['hlprbservice']) {
		$rbsDN = $subnet_data['hlprbservice'];
		$rbs_data = "<b>RBS-Option des DHCP Subnets</b><br>";
		$nextserver = $subnet_data['dhcpoptnext-server'];
		$filename = $subnet_data['dhcpoptfilename'];
	}
	elseif ($global_data['hlprbservice']) {
		$rbsDN = $global_data['hlprbservice'];
		$rbs_data = "<b>Globale RBS Option des DHCP Dienstes</b><br>";
		$nextserver = $global_data['dhcpoptnext-server'];
		$filename = $global_data['dhcpoptfilename'];
	}
}

$altrbs = alternative_rbservices($rbsDN);
$selectsize = count($altrbs) + 2;
$rbs_selectbox = "<select name='rbs' size='$selectsize' class='form_200_selectbox'>";
if ($rbsDN) {
   $exprbs = ldap_explode_dn($rbsDN, 1);
   $rbs_data .= "<br>DHCP <b>next-server</b>: $nextserver<br>DHCP <b>filename</b>: $filename";
	$rbs_selectbox .= "<option selected value='".$rbsself."'>$exprbs[0] / $exprbs[2]</option>";
	$rbs_selectbox .= "<option value=''>--- Kein RBS ---</option>";
}else{
 $rbs_selectbox .= "<option selected value=''>--- Kein RBS ---</option>";
}

# resliche Werte für Auswahlliste, allerdings dabei Werte die im nächst höheren
# geltenden Scope entsprechen, erhalten value='' da sie nicht gesetzt werden müssen ... 
if ( $subnet_data['hlprbservice'] ) {
	$next_scope_rbs = $subnet_data['hlprbservice'];
}else{
	$next_scope_rbs = $global_data['hlprbservice'];
}
if (count($altrbs) != 0){
   foreach ($altrbs as $item){
   	if ( $item['dn'] == $next_scope_rbs ) {
   		$rbs_selectbox .= "<option value=''>".$item['cn']." ".$item['au']."</option>";
   	}else{
      	$rbs_selectbox .= "<option value='".$item['dn']."'>".$item['cn']." ".$item['au']."</option>";
      }
   }
}
$rbs_selectbox .= "<input type='hidden' name='oldrbs' value='".$rbsself."'></select>";



$template->assign(array("POOLDN" => $pool['dn'],
								"CN" => $pool['cn'],
								"POOLAU" => $poolau,
								"POOLAUDN" => $poolaudn,
								"DHCPADDON" => $dhcp_addon,
								"DHCPSRV_CHECK" => $dhcpsrv_checkbox,
								"POOLHLPCONT" => $pool['dhcphlpcont'],
								"SUBNET" => $subnet[0],
								"SUBNETAU" => $subnetau,
								"SUBNETAUDN" => $subnetaudn,
								"DHCPNOW" => $subnet_data['dhcphlpcont'],
								"DESCRIPTION" => "",
								"STATEMENTS" => $pool['dhcpstatements'],
								"PCLSELECT" => $pcl_select,
								"ALLOW" => $pool['dhcpoptallow'],
								"DENY" => $pool['dhcpoptdeny'],
								"IGNORE" => $pool['dhcpoptignore'],
								"RBS" => $rbs,
								"RBSSELECT" => $rbs_selectbox,
								"RBSDATA" => $rbs_data,
								"OLDRBS" => $rbsDN,
								"DEFAULTLEASE" => $defaultlease_select,
								"MAXLEASE" => $maxlease_select,													
								"DLDATA" => $dldata,
								"MLDATA" => $mldata,
								"OPTDOMAIN" => $opt_domain));




###################################################################################

include("dhcp_footer.inc.php");

?>