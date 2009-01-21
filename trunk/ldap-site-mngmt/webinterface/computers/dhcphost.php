<?php

include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Computers Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 3;
$mnr = 1; 
$sbmnr = -1;
$mcnr = -1;
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcphost.dwt";

include("../class.FastTemplate.php");

include('computers_header.inc.php');

###################################################################################

$sbmnr = $_GET['sbmnr']; 

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createComputersMenu($rollen, $mnr, $auDN, $sbmnr, $mcnr);

###################################################################################

$hostDN = $_GET['dn'];

# Rechner Daten
$attributes = array("hostname","domainname","ipaddress","hwaddress","description","hlprbservice",
                     "dhcphlpcont","dhcpoptfixed-address","dhcpopthardware","dhcpoptfilename",
                     "dhcpoptnext-server","hw-mouse","hw-graphic","hw-monitor");
$host = get_node_data($hostDN,$attributes);
$hostip = explode('_',$host['ipaddress']);
# print_r($hostip); echo "<br><br>";
$dhcphlpcont = $host['dhcphlpcont'];
$objectDN = $dhcphlpcont;
$rbsDN = $host['hlprbservice'];

$rbs_dhcpopt = "";
$host_dhcpopt = "";

# DHCP Daten
if ($dhcphlpcont == ""){
   $dhcp = "Rechner ist in keinem DHCP Dienst angemeldet<br></td></tr>
            <tr valign='top'><td class='tab_d' colspan='2'>
					DHCP Dienst ausw&auml;hlen: ";
	$objecttype = "nodhcp";
	$rbs = "<td class='tab_d_ohne' colspan='2'>
				Sie m&uuml;ssen den Rechner zuerst in einem DHCP Dienst anmelden, bevor Sie ihn
	         einem Remote Boot Dienst zuordnen k&ouml;nnen <br>(DHCP Optionen!!).<br></td>
	        </tr>
	        <input type='hidden' name='rbs' value='".$rbsDN."'>";
}else{
   # Subnet?
   $objecttype = "service";
   $dhcp = "";
   $ocarray = get_node_data($dhcphlpcont,array("objectclass","dhcphlpcont"));
   #print_r($ocarray); echo "<br>";
   $sub = array_search('dhcpSubnet', $ocarray['objectclass']);
   #print_r($sub);
   if ($sub !== false ){
      $objecttype = "subnet";
      $exp0 = explode(',',$dhcphlpcont);
      $expsub = explode('=',$exp0[0]); $dhcpsub = $expsub[1];
      $dhcp .= "Subnet <b>".$dhcpsub."</b> / ";
      $dhcphlpcont = $ocarray['dhcphlpcont'];
   }
   $exp1 = explode(',',$dhcphlpcont);
   $expdhcp = explode('=',$exp1[0]); $dhcpserv = $expdhcp[1];
   $expdhcpau = explode('=',$exp1[2]); $dhcpau = $expdhcpau[1];
   $dhcp .= "Service <b>".$dhcpserv."</b> / AU <b>".$dhcpau."</b><br></td></tr>
            <tr valign='top'><td class='tab_d' colspan='2'>
					DHCP Dienst &auml;ndern: ";
   
   
   $fixedaddselopt = "<option selected value='none'>------------</option>";
   switch ( $host['dhcpoptfixed-address'] ){
   case "":
      $fixedaddress = "<b> - </b> <br>(dynamische Vergabe)";
      if ( $hostip[0] != "" ){
         $fixedaddselopt .= "<option value='ip'>".$hostip[0]." &nbsp;(IP Adresse)</option>";
      }
      $fixedaddselopt .= "<option value='hostname'>".$host['hostname']." &nbsp;(Hostname)</option>";
      break;
   case "ip":
      $fixedaddress = "<b>".$hostip[0]."</b><br>(Fixe IP Adresse)";
      $fixedaddselopt .= "<option value='hostname'>".$host['hostname']." &nbsp;(Hostname)</option>
                           <option value=''>kein Eintrag &nbsp;(dynamische IP Vergabe)</option>";
      break;
   case "hostname":
      $fixedaddress = "<b>".$host['hostname']."</b><br>(Fixe IP Adresse &uuml;ber Hostnamen aufgel&ouml;st)";
      if ( $hostip[0] != "" ){
         $fixedaddselopt .= "<option value='ip'>".$hostip[0]." &nbsp;(IP Adresse)</option>";
      }
      $fixedaddselopt .= "<option value=''>kein Eintrag (dynamisch)</option>";
      break;
   }
   
   
   $host_dhcpopt = "<tr><td class='tab_d_ohne' colspan='2'><b>DHCP Optionen:</b></td></tr>
                  <tr valign='top'>
				         <td class='tab_d_ohne'><b>hardware ethernet: </b>&nbsp;</td>
				         <td class='tab_d_ohne'><b>".$host['hwaddress']."</b>&nbsp;</td>
				         <td class='tab_d_ohne'>&nbsp;</td>
			         </tr>
			         <tr valign='top'>
			         	<td class='tab_d'><b>fixed-address:</b> &nbsp;</td>
			         	<td class='tab_d'>".$fixedaddress."&nbsp;</td>
				         <td class='tab_d'>
				         <select name='fixadd' size='3' class='medium_form_selectbox'>
				            ".$fixedaddselopt."
				         </select>
				         </td>
			         </tr>";
   
   ###########################################################
   # RBS Setup
   $rbs_selectbox = "";
   $rbs_dhcpopt = "";
   $altrbs = alternative_rbservices($rbsDN);
   
   
      $rbs_selectbox .= "<td class='tab_d'>
		   		            <select name='rbs' size='4' class='medium_form_selectbox'> 
		   			            <option selected value='none'>----------</option>";
   if (count($altrbs) != 0){
      foreach ($altrbs as $item){
         $rbs_selectbox .= "
         <option value='".$item['dn']."'>".$item['cn']." ".$item['au']."</option>";
      }
   }
   $rbs_selectbox .= "<option value=''>Kein RBS</option>
           					</select></td>";

   # RBS Daten
   if ($rbsDN == ""){
      
      $rbs = "<td class='tab_d_ohne'><b>Remote Boot Dienst: </b>&nbsp;</td>
              <td class='tab_d_ohne'>
               Rechner ist in keinem Remote Boot Dienst angemeldet<br></td></tr>
              <tr valign='top'><td class='tab_d'>
   			   RBS ausw&auml;hlen: <br></td>".$rbs_selectbox;
   }else{
      
      $rbs = "";
      $rbsdata = get_node_data($rbsDN,array("tftpserverip"));
      #print_r($rbsdata); echo "<br>";
      $exp2 = explode(',',$host['hlprbservice']);
      $exprbs = explode('=',$exp2[0]); $rbserv = $exprbs[1];
      $exprbsau = explode('=',$exp2[2]); $rbsau = $exprbsau[1];
      $rbs .= "<td class='tab_d_ohne'><b>Remote Boot Dienst: </b>&nbsp;</td>
               <td class='tab_d_ohne'>
                  Remote Boot Service <b>".$rbserv."</b> / AU <b>".$rbsau."</b><br>
                  TFTP (Boot) Server: <b>".$rbsdata['tftpserverip']."</b><br></td></tr>
               <tr valign='top'><td class='tab_d'>
   					RBS &auml;ndern: <br></td>".$rbs_selectbox;
   	
   	$rbs_dhcpopt = "<tr><td class='tab_d_ohne' colspan='2'><b>DHCP Optionen:</b></td></tr>
   	      <tr>
				   <td class='tab_d_ohne'><b>next-server</b> &nbsp;(TFTP Server):</td>
				   <td class='tab_d_ohne'>".$host['dhcpoptnext-server']."&nbsp;</td>
			   </tr>
			   <tr>
				   <td class='tab_d'><b>filename</b> &nbsp;(initiale remote Bootdatei):</td>
				   <td class='tab_d'>".$host['dhcpoptfilename']."&nbsp;</td>
			   </tr>";
   }

}

$template->assign(array("HOSTDN" => $hostDN,
								"HOSTNAME" => $host['hostname'],
           			      "DOMAINNAME" => $host['domainname'],
           			      "HWADDRESS" => $host['hwaddress'],
           			      "IPADDRESS" => $hostip[0],
           			      "DESCRIPTION" => $host['description'],
           			      "OLDDHCP" => $objectDN,
           			      "OLDFIXADD" => $host['dhcpoptfixed-address'],
           			      "OLDRBS" => $rbsDN,         			      
           		       	"DHCPCONT" => $dhcp,
           		       	"HOST_DHCPOPT" => $host_dhcpopt,
           		       	"RBS" => $rbs,
           		       	"RBS_DHCPOPT" => $rbs_dhcpopt,        			      
           		       	"NEXTSERVER" => $host['dhcpoptnext-server'],          			      
           		       	"FILENAME" => $host['dhcpoptfilename'],
           		       	"HOSTLINK" => "<a href='host.php?dn=".$hostDN."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"HWLINK" => "<a href='hwhost.php?dn=".$hostDN."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"AUDN" => $auDN,
           		       	"SBMNR" => $sbmnr));


##########################################################
# DHCP Setup

$altdhcp = alternative_dhcpobjects($objecttype,$objectDN,$hostip[0]);
#echo "<br><br>";print_r($altdhcp);

$template->assign(array("ALTDN" => "",
   	                  "ALTCN" => "",
   	                  "ALTAU" => ""));
if (count($altdhcp) != 0){
$template->define_dynamic("Altdhcp", "Webseite");
	foreach ($altdhcp as $item){
		
		$template->assign(array("ALTDN" => $item['dn'],
   	                        "ALTCN" => $item['cn'],
   	                        "ALTAU" => $item['au'],));
   	$template->parse("ALTDHCP_LIST", ".Altdhcp");	
	} 
}


###########################################################
# RBS Setup

/*$altrbs = alternative_rbservices($rbsDN);
#print_r($altrbs); echo "<br><br>";
$template->assign(array("ALTRBSDN" => "",
   	                  "ALTRBSCN" => "",
   	                  "ALTRBSAU" => ""));
if (count($altrbs) != 0){
$template->define_dynamic("Altrbs", "Webseite");
	foreach ($altrbs as $item){
		$template->assign(array("ALTRBSDN" => $item['dn'],
   	                        "ALTRBSCN" => $item['cn'],
   	                        "ALTRBSAU" => $item['au'],));
   	$template->parse("ALTRBS_LIST", ".Altrbs");	
	} 
}*/ 


###################################################################################

include("computers_footer.inc.php");



/*
<tr height='50'>
				<td class='tab_d'><b>DHCP Option hardware ethernet: </b>&nbsp;</td>
				<td class='tab_d'>{HWADDRESS} &nbsp;
				</td>
			</tr>
			<tr height='50'>
				<td class='tab_d'><b>DHCP Option fixed-address: &nbsp;</td>
				<td class='tab_d'>{IPADDRESS} &nbsp;
				</td>
			</tr>

<td class='tab_d'>
					<select name='rbs' size='4' class='medium_form_selectbox'> 
						<option selected value='none'>----------</option>
						
						<!-- BEGIN DYNAMIC BLOCK: Altrbs -->
						<option value='{ALTRBSDN}'>{ALTRBSCN} {ALTRBSAU}</option>
						<!-- END DYNAMIC BLOCK: Altrbs -->
						
						<option value=''>Kein RBS</option>
						
					</select>
				</td>
	<tr height='50'>
				<td class='tab_d'><b>TFTP Server <br>DHCP Option next-server: </b>&nbsp;</td>
				<td class='tab_d'>{NEXTSERVER} &nbsp;
				</td>
			</tr>
			<tr height='50'>
				<td class='tab_d'><b>PXE initiale Bootdatei <br>DHCP Option filename: </b>&nbsp;</td>
				<td class='tab_d'>{FILENAME} &nbsp;
				</td>
			</tr>

				
				*/
?>