<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcppool.dwt";

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

# DHCP Pools Daten holen						
$attributes = array("dn","cn","dhcphlpcont","dhcprange","description","dhcpstatements","dhcpoptallow",
							"dhcpoptdefault-lease-time","dhcpoptdeny","dhcpoptignore","dhcpoptmax-lease-time",
							"dhcpoptgeneric","hlprbservice","dhcpoptfilename","dhcpoptnext-server");
$pools = get_dhcppools($auDN, $attributes);

if (count($pools) == 0){
	redirect(0, "dhcpnopool.php?mnr=".$mnr, "", $addSessionId = TRUE);
	die;
}

$template->assign(array("POOLDN" => "",
								"CN" => "",
								"SUBNETDN" => "",
								"SUBNET" => "",
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
           		       	"MNR" => $mnr));


$template->define_dynamic("Dhcppools", "Webseite");
$template->define_dynamic("Dhcpranges", "Webseite");

# Für jeden Pool ...
foreach ($pools as $pool){
	
   # DHCP Subnet des Pools 
   $subnet = ldap_explode_dn($pool['dhcphlpcont'],1);
	$subnetdnexp = ldap_explode_dn( $pool['dhcphlpcont'], 0);
	$subnetauexp = array_slice($subnetdnexp, 3);
	$subnetau = implode(',',$subnetauexp);	
	$rbsDN = $pool['hlprbservice'];

	
   $template->clear_parse("DHCPRANGES_LIST");
   
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
      	$template->parse("DHCPRANGES_LIST", ".Dhcpranges");
         $template->clear_dynamic("Dhcpranges");
   	}
   	}else{
   	   $iprange = explode('_',$pool['dhcprange']);
   	   $template->assign(array(
   								"RANGE1" => $iprange[0],
   								"RANGE2" => $iprange[1],
   								"RPOOLDN" => $pool['dn']));
      	$template->parse("DHCPRANGES_LIST", ".Dhcpranges");
         $template->clear_dynamic("Dhcpranges");	
   	}
   }
   
   # Unknown-Clients
   if ($pool['dhcpoptallow'] == "unknown-clients"){
      $unknownclients = "allow";
      $ucselectbox = "<option selected value='allow'> ALLOW </option>
                        <option value='deny'> DENY </option>
                        <option value='ignore'> IGNORE </option>";
   }
   elseif ($pool['dhcpoptignore'] == "unknown-clients") {
      $unknownclients = "ignore";
      $ucselectbox = "<option selected value='ignore'> IGNORE </option>
                        <option value='allow'> ALLOW </option>
                        <option value='deny'> DENY </option>";
   }
   else{
      $unknownclients = "deny";
      $ucselectbox = "<option selected value='deny'> DENY </option>
                        <option value='allow'> ALLOW </option>
                        <option value='ignore'> IGNORE </option>";
   }

	# RBS Setup
	$rbs_selectbox = "";
	$rbs_addselectbox = "";
	$altrbs = alternative_rbservices($rbsDN);
	
	$rbs_selectbox .= "<select name='rbs[]' size='4' class='tftp_form_selectbox'>
									<option selected value='none'>----------</option>";
	$rbs_addselectbox = "<select name='rbs' size='3' class='tftp_form_selectbox'>
									<option selected value='none'>----------</option>";
	if (count($altrbs) != 0){
		foreach ($altrbs as $item){
			$rbs_selectbox .= "<option value='".$item['dn']."'>".$item['cn']." ".$item['au']."</option>";
			$rbs_addselectbox .= "<option value='".$item['dn']."'>".$item['cn']." ".$item['au']."</option>";
		}
	}
	$rbs_selectbox .= "<option value=''>Kein RBS</option></select>";
	$rbs_addselectbox .= "</select>";
	
	if ($rbsDN == ""){
		$rbs = "Keine Einbindung";
	}else{
		$rbsdnexp = ldap_explode_dn($pool['hlprbservice'],1);
		$rbs = $rbsdnexp[0]."<br>DHCP Next-Server: ".$pool['dhcpoptnext-server']."<br>DHCP Filename: ".$pool['dhcpoptfilename'];
   }


   $template->assign(array("POOLDN" => $pool['dn'],
   								"CN" => $pool['cn'],
   								"SUBNETDN" => $pool['dhcphlpcont'],
   								"SUBNET" => $subnet[0],
   								"SUBNETAU" => $subnetau,
   								"DESCRIPTION" => $pool['description'],
   								"STATEMENTS" => $pool['dhcpstatements'],
   								"UCSELECT" => $ucselectbox,
   								"UCNOW" => $unknownclients,
   								"ALLOW" => $pool['dhcpoptallow'],
   								"DENY" => $pool['dhcpoptdeny'],
   								"IGNORE" => $pool['dhcpoptignore'],
									"RBS" => $rbs,
									"RBSSELECT" => $rbs_selectbox,
									"RBSADD" => $rbs_addselectbox,
									"OLDRBS" => $rbsDN,
   								"DEFAULTLEASE" => $pool['dhcpoptdefault-lease-time'],
   								"MAXLEASE" => $pool['dhcpoptmax-lease-time'],
              		       	"MNR" => $mnr));
   $template->parse("DHCPPOOLS_LIST", ".Dhcppools");

}

###################################################################################

include("dhcp_footer.inc.php");

?>