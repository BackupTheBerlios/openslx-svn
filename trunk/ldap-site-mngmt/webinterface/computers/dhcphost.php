<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcphost.dwt";

include('computers_header.inc.php');

$mnr = 1; 
$sbmnr = -1;
$mcnr = -1;

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
                     "dhcpoptnext-server","dhcpoptmax-lease-time","dhcpoptdefault-lease-time","hw-mouse","hw-graphic","hw-monitor");
$host = get_node_data($hostDN,$attributes);
$hostip = explode('_',$host['ipaddress']);
# print_r($hostip); echo "<br><br>";
$dhcphlpcont = $host['dhcphlpcont'];
$dhcpmaxlease = $host['dhcpoptmax-lease-time'];
$dhcpdefaultlease = $host['dhcpoptdefault-lease-time'];
$objectDN = $dhcphlpcont;
$rbsDN = $host['hlprbservice'];

$rbs_dhcpopt = "";
$host_dhcpopt = "";
$dhcp_selectbox = "";

##########################################################
# DHCP Setup

# DHCP Daten
if ($dhcphlpcont == ""){
   $objecttype = "nodhcp";
   
   # DHCP Selectbox
   $altdhcp = alternative_dhcpobjects($objecttype,$objectDN,$hostip[0]);
   $dhcp_selectbox .= "<td class='tab_d'>
   	   		          <select name='dhcpcont' size='3' class='medium_form_selectbox'> 
   	   			          <option selected value='none'>----------</option>";
   if (count($altdhcp) != 0){
   	foreach ($altdhcp as $item){
   		$dhcp_selectbox .= "
   		   <option value='".$item['dn']."'>".$item['cn']." ".$item['au']."</option>";
   	}
   }
   $dhcp_selectbox .= "<option value=''>Kein DHCP</option>
           					</select></td>";
   
   $dhcp = "<td class='tab_d_ohne' colspan='2'><b>Eingebunden in DHCP Dienst: </b>&nbsp;</td>
				<td class='tab_d_ohne'>
            Rechner ist in keinem DHCP Dienst angemeldet<br></td></tr>
            <tr valign='top'><td class='tab_d' colspan='2'>
					DHCP Dienst ausw&auml;hlen: <br></td>".$dhcp_selectbox;
	
	$rbs = "<td class='tab_d_ohne' colspan='2'>
				Sie m&uuml;ssen den Rechner zuerst in einem DHCP Dienst anmelden, bevor Sie ihn
	         einem Remote Boot Dienst zuordnen k&ouml;nnen <br>(DHCP Optionen!!).<br></td>
	        </tr>
	        <input type='hidden' name='rbs' value='".$rbsDN."'>";
}else{
   # Host in Service oder Subnet?
   $objecttype = "service";
   $dhcp = "";
   
   /*$ocarray = get_node_data($dhcphlpcont,array("objectclass","dhcphlpcont"));
   #print_r($ocarray); echo "<br>";
   $sub = array_search('dhcpSubnet', $ocarray['objectclass']);
   #print_r($sub);
   if ($sub !== false ){
      $objecttype = "subnet";
      $exp0 = explode(',',$dhcphlpcont);
      $expsub = explode('=',$exp0[0]); $dhcpsub = $expsub[1];
      $dhcp .= "Subnet <b>".$dhcpsub."</b> / ";
      $dhcphlpcont = $ocarray['dhcphlpcont'];
   }*/
   
   $exp1 = explode(',',$dhcphlpcont);
   $expdhcp = explode('=',$exp1[0]); $dhcpserv = $expdhcp[1];
   $expdhcpau = explode('=',$exp1[2]); $dhcpau = $expdhcpau[1];
   
   # DHCP Selectbox
   $altdhcp = alternative_dhcpobjects($objecttype,$objectDN,$hostip[0]);
   $dhcp_selectbox .= "<td class='tab_d'>
   	   		          <select name='dhcpcont' size='3' class='medium_form_selectbox'> 
   	   			          <option selected value='none'>----------</option>";
   if (count($altdhcp) != 0){
   	foreach ($altdhcp as $item){
   		$dhcp_selectbox .= "
   		   <option value='".$item['dn']."'>".$item['cn']." ".$item['au']."</option>";
   	}
   }
   $dhcp_selectbox .= "<option value=''>Kein DHCP</option>
           					</select></td>";
   
   $dhcp .= "<td class='tab_d_ohne' colspan='2'><b>Eingebunden in DHCP Dienst: </b>&nbsp;</td>
				<td class='tab_d_ohne'>
            Service <b>".$dhcpserv."</b> / AU <b>".$dhcpau."</b><br></td></tr>
            <tr valign='top'><td class='tab_d' colspan='2'>
					DHCP Dienst &auml;ndern: <br></td>".$dhcp_selectbox;
   
   
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
      $fixedaddress = "<b>".$host['hostname']."</b><br>(Fixe IP Adresse &uuml;ber DNS aufgel&ouml;st)";
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
			         	<td class='tab_d_ohne'><b>fixed-address:</b> &nbsp;</td>
			         	<td class='tab_d_ohne'>".$fixedaddress."&nbsp;</td>
				         <td class='tab_d_ohne'>
				         <select name='fixadd' size='3' class='medium_form_selectbox'>
				            ".$fixedaddselopt."
				         </select>
				         </td>
			         </tr>";

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
           		       	"NEXTSERVER" => $host['dhcpoptnext-server'],          			      
           		       	"FILENAME" => $host['dhcpoptfilename'],
								"DEFAULTLEASE" => $dhcpdefaultlease,
								"MAXLEASE" => $dhcpmaxlease,
           		       	"HOSTLINK" => "<a href='host.php?dn=".$hostDN."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"RBSLINK" => "<a href='rbshost.php?dn=".$hostDN."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"HWLINK" => "<a href='hwhost.php?dn=".$hostDN."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"AUDN" => $auDN,
           		       	"SBMNR" => $sbmnr));



###################################################################################

include("computers_footer.inc.php");

?>