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

$attributes = array("hostname","domainname","ipaddress","hwaddress","description","dhcphlpcont",
					"dhcpoptfixed-address","hlprbservice","dhcpoptfilename","dhcpoptnext-server","dhcpoptmax-lease-time","dhcpoptdefault-lease-time","dhcpoptvendor-encapsulated-options");
$host = get_node_data($hostDN,$attributes);
$hostip = explode('_',$host['ipaddress']);

if ($host[ipaddress]) {
	$dns_check = "";
	$dns_check = check_ip_zone($hostip[0],$assocdom,$host['hostname'],$au_ou);
	if ($dns_check){
		$dns_feedback .= "<br><code class='red_font_object_fin'>$dns_check</code>";
	}
	
// 	echo "IP: $hostip[0] <br>";
// 	$iplong = ip2long($hostip[0]);
// 	$iplongbin = decbin($iplong);
// 	echo "LB: $iplongbin <br>";
// 	$ip_chunks = explode('.',$hostip[0]);
// 	foreach ($ip_chunks as $chunk) {
// // 		echo "$chunk => ";
// 		$pack = $pack.pack('C*',$chunk);
// // 		echo "$pack<br>";
// // 		$bin = unpack( 'N*', $pack );
// // 		print_r($bin);
// 		$chbin = decbin($chunk);
// 		$ipbin .= sprintf("%08s",$chbin);
// 	}
// 	$pack = pack('A4',$ip_chunks[1]);
// 	echo "CB: $ipbin<br>";
// 	print unpack( 'B8', "aaa" );
// // 	print_r($bin);
	
}


##########################################
# DHCP Setup
$dhcphlpcont = $host['dhcphlpcont'];
$dhcp = "";
$host_dhcpopt = "";

if ($dhcphlpcont == ""){
   if ( $host['hwaddress'] ) {
//    	$dhcp = "<td class='tab_d' width='30%'>Client Eintrag DHCP: </td>
   	$dhcp = "<td class='tab_d_ohne' colspan='4'>
				<input type='checkbox' name='dhcpcont' value='".$DHCP_SERVICE."'></td></tr>
			<tr><td class='tab_d' colspan='4'>
				Setzen Sie das H&auml;kchen, um den Client einzutragen&nbsp;</td></tr>";
	}else{
		$dhcp = "<tr><td class='tab_d' colspan='4'>
					F&uuml;r Client <b>".$host['hostname']."</b> ist keine MAC Adresse eingetragen.<br> 
					Diese ist Voraussetzung f&uuml;r einen eigenen Host-Eintrag im DHCP Dienst.<br>
					Tragen Sie zun&auml;chst eine MAC Adresse f&uuml;r den Client ein<br><br>
					Jedoch kann der Client - als <i>ein dem DHCP unbekannter Host</i> - dynamisch ein IP/DHCP Setup erhalten
					<br>(Subnetz + dynamischer DHCP Pool mit Option <i>allow unknown-clients</i>)</td></tr>";
	}
}else{
//    $dhcp = "<td class='tab_d_ohne'>Client Eintrag (DHCP):</td>
   $dhcp = "<td class='tab_d_ohne' colspan='2'>
				<input type='checkbox' name='dhcpcont' value='".$DHCP_SERVICE."' checked>
				&nbsp;&nbsp;<b><code class='red_font_object'>aktiv</code></b>&nbsp;&nbsp;
				 (Entfernen Sie das H&auml;kchen, um den Client auszutragen)</td>";
   
	if ( $host['ipaddress'] ) {
		switch ( $host['dhcpoptfixed-address'] ) {
			case "ip":
			$fixadd_radio = "<input type='radio' name='fixadd' value='ip' checked><b>".$hostip[0]."</b> &nbsp;&nbsp;&nbsp;(Fixe IP Adresse)<br>
			<input type='radio' name='fixadd' value='hostname'><b>".$host['hostname']."</b> &nbsp;&nbsp;&nbsp;(Fixe IP Adresse &uuml;ber DNS aufgel&ouml;st)";
			break;
			case "hostname":
			$fixadd_radio = "<input type='radio' name='fixadd' value='ip'><b>".$hostip[0]."</b>&nbsp;&nbsp;&nbsp;(Fixe IP Adresse)<br>
					<input type='radio' name='fixadd' value='hostname' checked><b>".$host['hostname']."</b> &nbsp;&nbsp;&nbsp;
				(Fixe IP Adresse &uuml;ber DNS aufgel&ouml;st)";
			break;
		}
	}else{
		$fixadd_radio = "<b> -- </b> &nbsp;&nbsp;&nbsp;(IP Vergabe dynamisch)";
	}
	$host_dhcpopt = "<tr valign='top'>
					<td width='30%' class='tab_d_ohne'>DHCP <b>hardware ethernet:</b>&nbsp;</td>
					<td width='10%' class='tab_d_ohne'><b>".$host['hwaddress']."</b>&nbsp;</td>
					<td width='60%' class='tab_d_ohne'>&nbsp;</td>
				</tr>
				<tr valign='top'>
					<td class='tab_d'>DHCP <b>fixed-address:</b>&nbsp;</td>
					<td class='tab_d' colspan='2'>".$fixadd_radio."&nbsp;</td>
				</tr>";
}

#####################################
# RBS Setup
$rbsDN = $host['hlprbservice'];
$rbs = "";
$altrbs = alternative_rbservices($rbsDN);

if ($rbsDN != "") {
	$selectsize = count($altrbs) + 2;
	$exprbs = ldap_explode_dn($rbsDN, 1);
	$rbs_selectbox = " &nbsp;<b>Auswahl verf&uuml;gbarer Remote Boot Services:</b><br><select name='rbs' size='$selectsize' class='form_400_selectbox'> 
						<option selected value='".$rbsDN."'>$exprbs[0] &nbsp;&nbsp;[ Abt.: $exprbs[2] ] <b>(AKTIV)</b></option>
						<option value=''>---- Kein RBS (deaktiviert) ----</option>";
} else {
	$selectsize = count($altrbs) + 1;
	$rbs_selectbox = " &nbsp;<b>Auswahl verf&uuml;gbarer Remote Boot Services:</b><br><select name='rbs' size='$selectsize' class='form_400_selectbox'> 
						<option selected value=''>---- Kein RBS (deaktiviert) ----</option>";
}

if (count($altrbs) != 0){
   foreach ($altrbs as $item){
      $rbs_selectbox .= "<option value='".$item['dn']."'>".$item['cn']." ".$item['au']."</option>";
   }
}
$rbs_selectbox .= "</select>";

# RBS Daten
if ( !$dhcphlpcont ){
	$rbs .= "<tr>
				<td class='tab_d' colspan='3'>
				  Client <b>".$host['hostname']."</b> ist nicht im DHCP Dienst eingetragen.<br>
				  Dies ist Voraussetzung f&uuml;er eine Client-spezifische Zuordnung zu einem Remote Boot Dienst.<br><br>
				</td>
			</tr>
			<input type='hidden' name='rbs' value='$rbsDN'>";	        
}
elseif ( $rbsDN == "" ) {
   	$rbs .= "	<td class='tab_d' rowspan='2'>".$rbs_selectbox."</td>
			</tr>
			<tr valign='top'>
			   <td class='tab_d'>Um Client <b>".$host['hostname']."</b> einzutragen w&auml;hlen Sie einen Remote Boot Dienst aus der Liste:<br></td>
			   <td class='tab_d'>&nbsp;</td>
            </tr>";
}
else {
   	$rbs .= "	<td class='tab_d' rowspan='3'>".$rbs_selectbox."</td>
			<tr valign='top'>
				<td width='30%' class='tab_d_ohne'>DHCP <b>next-server:</b>&nbsp;</td>
				<td width='10%' class='tab_d_ohne'><b>".$host['dhcpoptnext-server']."</b>&nbsp;</td>
			</tr>
			<tr valign='top'>
				<td class='tab_d'>DHCP <b>filename:</b>&nbsp;</td>
				<td class='tab_d'><b>".$host['dhcpoptfilename']."</b>&nbsp;</td>
			</tr>";
}


#####################
# Extra DHCP Optionen
$dhcp_extra = "";
$mainadmin = 0;
if ($all_roles[$auDN]['roles']) {
	foreach ($all_roles[$auDN]['roles'] as $role) {
		if ($role == 'MainAdmin') {
			$mainadmin = 1;
			break;
		}
	}
}
if ($mainadmin) {
$dhcp_extra = "
<tr valign='top'>
	<td class='tab_d_ohne' colspan='3'><b>Weitere DHCP Optionen: </b>&nbsp;(Host-spezifischer Scope)</td>
</tr>
<tr>
	<td class='tab_d_ohne'><b>Max Lease Time:</b>&nbsp;</td>
	<td class='tab_d_ohne' colspan='2'>
		<input type='Text' name='attribs[dhcpoptmax-lease-time]' value='".$host['dhcpoptmax-lease-time']."' size='15' maxlength='7' class='medium_form_field'>
		<input type='hidden' name='oldattribs[dhcpoptmax-lease-time]' value='".$host['dhcpoptmax-lease-time']."'> &nbsp;
	</td>
</tr>
<tr>
	<td class='tab_d'><b>Default Lease Time:</b></td>
	<td class='tab_d' colspan='2'>
		<input type='Text' name='attribs[dhcpoptdefault-lease-time]' value='".$host['dhcpoptdefault-lease-time']."' size='15' maxlength='7' class='medium_form_field'>
		<input type='hidden' name='oldattribs[dhcpoptdefault-lease-time]' value='".$host['dhcpoptdefault-lease-time']."'> &nbsp;
	</td>
</tr>
<tr>
	<td class='tab_d'><b>Vendor Encapsulated Options: </b>&nbsp;</td>
	<td class='tab_d' colspan='2'>
		<input type='Text' name='attribs[dhcpoptvendor-encapsulated-options]' value='".$host['dhcpoptvendor-encapsulated-options']."' size='70' class='medium_form_field'>
		<input type='hidden' name='oldattribs[dhcpoptvendor-encapsulated-options]' value='".$host['dhcpoptvendor-encapsulated-options']."'> &nbsp;
	</td>
</tr>
";
}

$template->assign(array("HOSTDN" => $hostDN,
						"HOSTNAME" => $host['hostname'],
						"DNSCHECK" => $dns_feedback,
						"DOMAINNAME" => $host['domainname'],
						"HWADDRESS" => $host['hwaddress'],
						"IPADDRESS" => $hostip[0],
						"DESCRIPTION" => $host['description'],
						# DHCP
						"DHCPCONT" => $host['dhcphlpcont'],
						"DHCP" => $dhcp,
						"OLDDHCP" => $dhcphlpcont,
						"OLDFIXADD" => $host['dhcpoptfixed-address'],
						"HOST_DHCPOPT" => $host_dhcpopt,
						"DHCP_EXTRA" => $dhcp_extra,
						# RBS
						"RBS" => $rbs,
						"OLDRBS" => $rbsDN,
						# HTML-Links zu anderen Reitern
						"DHCPLINK" => "<a href='host_dhcp.php?host=".$host['hostname']."&sbmnr=".$sbmnr."' class='headerlink'>",
						#"RBSLINK" => "<a href='rbshost.php?host=".$host['hostname']."&sbmnr=".$sbmnr."' class='headerlink'>",
						"RBSLINK" => "",
						"HWLINK" => "<a href='hwhost.php?host=".$host['hostname']."&sbmnr=".$sbmnr."' class='headerlink'>",
						"AUDN" => $auDN,
						"SBMNR" => $sbmnr
					));

###################################################################################

include("computers_footer.inc.php");

?>