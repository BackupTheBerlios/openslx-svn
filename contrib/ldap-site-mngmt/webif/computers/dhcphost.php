<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcphost.dwt";

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


# Rechner Daten
$attributes = array("hostname","domainname","ipaddress","hwaddress","hlprbservice",
                     "dhcphlpcont","dhcpoptfixed-address","dhcpopthardware","dhcpoptfilename",
                     "dhcpoptnext-server","dhcpoptmax-lease-time","dhcpoptdefault-lease-time");
$host = get_node_data($hostDN,$attributes);
$hostip = explode('_',$host['ipaddress']);
# print_r($hostip); echo "<br><br>";

$dhcphlpcont = $host['dhcphlpcont'];
$rbsDN = $host['hlprbservice'];


##########################################################
# DHCP Setup
$dhcp = "";
$host_dhcpopt = "";

if ($dhcphlpcont == ""){
   if ( $host['hwaddress'] ) {
   	$dhcp = "<td class='tab_d' width='30%'>Client-Eintrag im DHCP Dienst: </td>
					<td class='tab_d' colspan='3'>
						<input type='checkbox' name='dhcpcont' value='".$DHCP_SERVICE."'></td>";
	}else{
		$dhcp = "<td class='tab_d' colspan='4'>
					F&uuml;r Client <b>".$host['hostname']."</b> ist keine MAC Adresse eingetragen.<br> 
					Diese ist Voraussetzung f&uuml;r einen eigenen Host-Eintrag im DHCP Dienst.<br>
					Tragen Sie zun&auml;chst eine MAC Adresse f&uuml;r den Client ein<br><br>
					Jedoch kann der Client - als <i>ein dem DHCP unbekannter Host</i> - dynamisch ein IP/DHCP Setup erhalten
					<br>(Subnetz + dynamischer DHCP Pool mit Option <i>allow unknown-clients</i>)</td>";
	}
}else{
   $dhcp = "<td class='tab_d_ohne'>Client Eintrag (DHCP):</td>
				<td class='tab_d_ohne' colspan='3'>
					<input type='checkbox' name='dhcpcont' value='".$DHCP_SERVICE."' checked></td>";
   
   if ( $host['ipaddress'] )	{
   	switch ( $host['dhcpoptfixed-address'] ){
   	case "ip":
      	$fixadd_radio = "<input type='radio' name='fixadd' value='ip' checked><b>".$hostip[0]."</b> &nbsp;&nbsp;&nbsp;
      								(Fixe IP Adresse)<br>
      							<input type='radio' name='fixadd' value='hostname'><b>".$host['hostname']."</b> &nbsp;&nbsp;&nbsp;
      								(Fixe IP Adresse &uuml;ber DNS aufgel&ouml;st)";
      	break;
   	case "hostname":
      	$fixadd_radio = "<input type='radio' name='fixadd' value='ip'><b>".$hostip[0]."</b> &nbsp;&nbsp;&nbsp;
      								(Fixe IP Adresse)<br>
      							<input type='radio' name='fixadd' value='hostname' checked><b>".$host['hostname']."</b> &nbsp;&nbsp;&nbsp;
      								(Fixe IP Adresse &uuml;ber DNS aufgel&ouml;st)";
      	break;
   	}
   }else{
   	$fixadd_radio = "<b> -- </b> &nbsp;&nbsp;&nbsp;(IP Vergabe dynamisch)";
   }
   $host_dhcpopt = "<tr valign='top'>
				         <td width='30%' class='tab_d_ohne'>DHCP <b>hardware ethernet:</b>&nbsp;</td>
			        		<td width='25%' class='tab_d_ohne'><b>".$host['hwaddress']."</b>&nbsp;</td>
			        		<td width='20%' class='tab_d_ohne'>&nbsp;</td>
			        		<td width='25%' class='tab_d_ohne'>&nbsp;</td>
			         </tr>
			         <tr valign='top'>
			         	<td class='tab_d'>DHCP <b>fixed-address:</b>&nbsp;</td>
			         	<td class='tab_d' colspan='3'>".$fixadd_radio."&nbsp;</td>
			         </tr>";
}

#####################################
# RBS Setup
$rbs = "";
$altrbs = alternative_rbservices($rbsDN);

if ($rbsDN != "") {
	$selectsize = count($altrbs) + 2;
   $exprbs = ldap_explode_dn($rbsDN, 1);
	$rbs_selectbox = "<select name='rbs' size='$selectsize' class='medium_form_selectbox'> 
	   			            <option selected value='".$rbsDN."'>$exprbs[0] / $exprbs[2]</option>
	   			            <option value=''>--- Kein RBS ---</option>";
} else {
	$selectsize = count($altrbs) + 1;
	$rbs_selectbox = "<select name='rbs' size='$selectsize' class='medium_form_selectbox'> 
	   			            <option selected value=''>--- Kein RBS ---</option>";
}

if (count($altrbs) != 0){
   foreach ($altrbs as $item){
      $rbs_selectbox .= "<option value='".$item['dn']."'>".$item['cn']." ".$item['au']."</option>";
   }
}
$rbs_selectbox .= "</select>";

# RBS Daten
if (!$dhcphlpcont){
	$rbs .= "<tr>
				<td class='tab_d' colspan='4'>
				Client <b>".$host['hostname']."</b> ist nicht im DHCP Dienst eingetragen.<br>
				Ein DHCP Host-Eintrag ist Voraussetzung, um den Client spezifisch einem Remote Boot Dienst 
				zuzuweisen.<br><br>
				Jedoch ist nicht ausgeschlossen, dass der Client dynamisch per DHCP 
				eine RBS Zuweisung erh&auml;lt <br>(dynamischer DHCP Pool mit Option <i>allow unknown-clients</i> und RBS Optionen)</td>
				</tr>
				<input type='hidden' name='rbs' value='$rbsDN'>";	        
}else{
	if ($rbsDN == "" && $dhcphlpcont ){
   	$rbs .= "
   			<tr>
            	<td class='tab_d_ohne' colspan='4'>Um Client <b>".$host['hostname']."</b> einzutragen w&auml;hlen Sie einen Remote Boot Dienst aus der Liste:<br></td>
            </tr>
            <tr valign='top'>
			   	<td class='tab_d' colspan='4'>".$rbs_selectbox."</td>
			   </tr>";
	}else{
   	$rbs .= "
            <tr valign='top'>
            	<td class='tab_d' colspan='2'>".$rbs_selectbox."</td>
				   <td class='tab_d'><br>
				   	DHCP <b>next-server: &nbsp;</b> <br>
				   	DHCP <b>filename: &nbsp;</b>
				   </td>
				   <td class='tab_d'><br>
				   	&nbsp;".$host['dhcpoptnext-server']."</b> <br>
				   	&nbsp;".$host['dhcpoptfilename']."</b>
				   </td>
			   </tr>";
	}
}


$template->assign(array("HOSTDN" => $hostDN,
								"HOSTNAME" => $host['hostname'],
           			      "IPADDRESS" => $hostip[0],
           		       	"DHCPCONT" => $dhcp,
           			      "OLDDHCP" => $dhcphlpcont,
           			      "OLDFIXADD" => $host['dhcpoptfixed-address'],
           		       	"HOST_DHCPOPT" => $host_dhcpopt,
           		       	"RBS" => $rbs,
           			    "OLDRBS" => $rbsDN,
           		       	"HOSTLINK" => "<a href='host.php?host=".$host['hostname']."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	#"RBSLINK" => "<a href='rbshost.php?host=".$host['hostname']."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"RBSLINK" => "",
           		       	"HWLINK" => "<a href='hwhost.php?host=".$host['hostname']."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"AUDN" => $auDN,
           		       	"SBMNR" => $sbmnr));


###################################################################################

include("computers_footer.inc.php");

?>