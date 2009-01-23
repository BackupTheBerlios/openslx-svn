<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcppools.dwt";

include('dhcp_header.inc.php');

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
							"dhcpoptgeneric","hlprbservice","dhcpoptfilename","dhcpoptnext-server","dhcppermittedclients");
$pools = get_dhcppools($auDN, $attributes);

$scope_attributes = array("dn","cn","dhcphlpcont","dhcpstatements","dhcpoptallow","dhcpoptdeny",
							"dhcpoptignore","dhcpoptdefault-lease-time","dhcpoptmax-lease-time",
							"dhcpoptgeneric","hlprbservice","dhcpoptfilename","dhcpoptnext-server","dhcppermittedclients");

$global_data = get_node_data($DHCP_SERVICE, $scope_attributes);					

#print_r($pools);
if (count($pools) == 0){
	redirect(0, "dhcpnopool.php?mnr=".$mnr, "", $addSessionId = TRUE);
	die;
}

$template->assign(array("POOLDN" => "",
								"CN" => "",
								"SUBNETDN" => "",
								"SUBNET" => "",
								"IPRANGES" => "",
								"DESCRIPTION" => "",
								"STATEMENTS" => "",
								"ALLOW" => "",
								"DENY" => "",
								"IGNORE" => "",
								"RBS" => "",
								"RBSRV" => "",
								"RBSSELECT" => "",
								"DEFAULTLEASE" => "",
								"MAXLEASE" => "",
           		       	"MNR" => $mnr));


$template->define_dynamic("Dhcppools", "Webseite");

$pools = array_natsort($pools, "dhcphlpcont", "dhcphlpcont");

# Für jeden Pool ...
foreach ($pools as $pool){

	$subnet_data = get_node_data($pool['dhcphlpcont'], $scope_attributes);

   # DHCP Subnet des Pools
   if ($pool['dhcphlpcont']) {
	   $subnetexp = ldap_explode_dn($pool['dhcphlpcont'],1);
		$subnetdnexp = ldap_explode_dn( $pool['dhcphlpcont'], 0);
		$subnetauexp = array_slice($subnetdnexp, 3);
		$subnetau = implode(',',$subnetauexp);
		$subnet = $subnetexp[0];
	}else{
		$subnet = "<b>Pool nicht aktiv!</b>";
	}
	
	$poollink = "<a href='dhcppool_one.php?dn=".$pool[dn]."&mnr=".$mnr."&url=dhcppools.php' class='headerlink'><b>>> Pool verwalten</b></a> ";
   
   
	
   # DHCP Ranges
   $ipranges = "";
   if (count($pool['dhcprange']) != 0){
      if (count($pool['dhcprange']) > 1){
      	natsort($pool['dhcprange']);
   		for ($i=0; $i<count($pool['dhcprange']); $i++){
     	   	$exprange = explode('_',$pool['dhcprange'][$i]);
     	   	$r1 = explode('.',$exprange[0]);
     	   	$r2 = explode('.',$exprange[1]);
     	   	$ipranges .= "<b>$r1[3] - $r2[3]</b>";
     	   	if ($i+1 != count($pool['dhcprange'])){
     		      $ipranges .= "<br>";
   	  	   }
	     	}
   	}else{
      	$exprange = explode('_',$pool['dhcprange']);
        	$r1 = explode('.',$exprange[0]);
        	$r2 = explode('.',$exprange[1]);
        	$ipranges .= "<b>$r1[3] - $r2[3]</b>";
   	}
   }

	# Permitted Clients
	if (!$global_data['dhcppermittedclients']) {
		if (!$subnet_data['dhcppermittedclients']) {
			if ($pool['dhcppermittedclients']) {
				$pcl = "<b>Im DHCP eingetragene Clients</b><br>(deny unknown-clients)";
			}else{
				$pcl = "<b>Beliebige Clients</b>";
			}
		}else{
			$pcl = "<b>Im DHCP eingetragene Clients</b><br>(deny unknown-clients)<br>Option des DHCP Subnets";
		}
	}else{
		$pcl = "<b>Nur im DHCP eingetragene Clients</b><br>(deny unknown-clients)<br>Globale Option des DHCP Dienstes";
	}


   
   
	# RBS Setup
	$rbservice = "";
	$rbs = "";
	$scope_info = "";
	$nextserver = "";
	$filename = "";
	if ($pool['hlprbservice']) {
		$rbsDN = $pool['hlprbservice'];
		$nextserver = $pool['dhcpoptnext-server'];
		$filename = $pool['dhcpoptfilename'];
	}
	elseif ($subnet_data['hlprbservice']) {
		$rbsDN = $subnet_data['hlprbservice'];
		$scope_info = "<br>aus DHCP Subnet";
		$nextserver = $subnet_data['dhcpoptnext-server'];
		$filename = $subnet_data['dhcpoptfilename'];
	}
	elseif ($global_data['hlprbservice']) {
		$rbsDN = $global_data['hlprbservice'];
		$scope_info = "<br>Globale DHCP Option";
		$nextserver = $global_data['dhcpoptnext-server'];
		$filename = $global_data['dhcpoptfilename'];
	}
	if ($rbsDN != "") {
		$rbsdnexp = ldap_explode_dn($rbsDN,1);		
   	$rbservice = "$rbsdnexp[0] <br>($rbsdnexp[2])".$scope_info;
		$rbs = $rbsdnexp[0]."<br>DHCP Next-Server: ".$nextserver."<br>DHCP Filename: ".$filename;
	}
	
	# RBS für Pool Neueintrag
	$rbs_addselectbox = "";
	/*
	$add_rbs = alternative_rbservices("");
	$rbs_addselectbox = "<select name='rbs' size='3' class='tftp_form_selectbox'>
									<option selected value='none'>----------</option>";
	if (count($add_rbs) != 0){
		foreach ($add_rbs as $item){
			$rbs_addselectbox .= "<option value='".$item['dn']."'>".$item['cn']." ".$item['au']."</option>";
		}
	}
	$rbs_addselectbox .= "</select>";
	*/

   $template->assign(array("POOLDN" => $pool['dn'],
   								"CN" => $pool['cn'],
   								"SUBNETDN" => $pool['dhcphlpcont'],
   								"SUBNET" => $subnet,
   								"SUBNETAU" => $subnetau,
   								"POOLINK" => $poollink,
   								"DESCRIPTION" => $pool['description'],
   								"STATEMENTS" => $pool['dhcpstatements'],
   								"IPRANGES" => $ipranges,
   								"PCL" => $pcl,
   								"UCSELECT" => $ucselectbox,
   								"UCNOW" => $unknownclients,
   								"ALLOW" => $pool['dhcpoptallow'],
   								"DENY" => $pool['dhcpoptdeny'],
   								"IGNORE" => $pool['dhcpoptignore'],
									"RBSRV" => $rbservice,
									"RBS" => $rbs,
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