<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "dhcpsubnets.dwt";

include('dhcp_header.inc.php');


$mnr = -1; 
$sbmnr = -1;
$mcnr = -1;

###################################################################################

$mnr = $_GET['mnr'];

# Menuleisten erstellen
createMainMenu($rollen, $mainnr);
createDhcpMenu($rollen, $mnr, $auDN, $sbmnr);

###################################################################################

include('dhcp_class_box.php');

$template->assign(array("SUBNETDN" => "",
								"SUBNETCN" => "Noch keine Subnets angelegt",
								"NETMASK" => "",
								"DHCP" => "",
								"SUBNETIP" => "",
								"POOLS" => "",
								"GLOBALPCL" => ""));

# rbservice und pxe daten (voerst nur ein rbs)
$admin_subnets = get_dhcpsubnets($auDN,array("dn","cn","dhcpoptnetmask","dhcprange","dhcphlpcont","dhcppermittedclients"));
#print_r($admin_subnets); echo "<br>";
$nets = get_max_networks();
foreach ($admin_subnets as $snet) {
	$index = array_search($snet[cn],$nets);
	if ( $index !== false ){
		array_splice($nets,$index,1);
	}
}
if ( $nets ) {
	#print_r($nets); echo "<br>";
	$ro_subnets = get_dhcpsubnets_from_nets($nets,array("dn","cn","dhcpoptnetmask","dhcprange","dhcphlpcont","dhcppermittedclients"));
	#print_r($ro_subnets); echo "<br>";
	$subnet_array = array_merge($admin_subnets,$ro_subnets);
}else{
	$subnet_array = $admin_subnets;
}


##############
# Global DHCP Data
$global_options = array("dhcpoptdefault-lease-time","dhcpoptmax-lease-time","dhcpoptdomain-name",
							"dhcpoptdomain-name-servers","dhcpoptgeneric","dhcppermittedclients");
$global_data = get_node_data($DHCP_SERVICE,$global_options);
if ($global_data['dhcppermittedclients']){
	$global_pcl = $global_data['dhcppermittedclients'];
}else{
	$global_pcl = "Beliebige Clients";
}
$template->assign(array("GLOBALPCL" => $global_pcl));

############### 

$subnet_array = array_natsort($subnet_array, "cn", "cn");

$template->define_dynamic("Subnets", "Webseite");
$template->define_dynamic("Pools", "Webseite");

$i = 0;
foreach ($subnet_array as $subnet){
	
	$subnetcn = "<a href='dhcpsubnet.php?dn=".$subnet['dn']."&mnr=".$mnr."' class='headerlink'><b>".$subnet['cn']."<br>$subnet[access]</b></a>";
	
	# Dienstzuordnung des Subnetzes
	$dhcpservice = "&nbsp;";
   if ($subnet['dhcphlpcont'] != ""){
		#$dhcpservice = "<code class='red_font_object'>X</code>";
		#$dhcpservice = "<code class='red_font_object'>@</code>";
		$dhcpservice = "<code class='red_font_object'>aktiv</code>";
      #$dhcpservice = "<input type='checkbox' readonly name='dhcpsrv[]' value='".$subnet['dn']."' checked>
   	#					<input type='hidden' name='olddhcpsrv[]' value='".$subnet['dn']."'>";
   #}else{
   	#$dhcpservice = "<input type='checkbox' name='dhcpsrv[]' value='".$subnet['dn']."'>
   	#					<input type='hidden' name='olddhcpsrv[]' value='".$subnet['dn']."'>";
   }
   #$dhcpservice .= "<input type='hidden' name='subnetdn[]' value='".$subnet['dn']."'>";
   
   # AU des Subnetzes
   $exp = ldap_explode_dn($subnet['dn'],1);
   $exp = array_slice($exp, 3);
   $subnetau = $exp[0];
   
   # Subnetz Aufteilung (AUs, Zonen, delegierte IPs, dyn. Pools)
	$subnetip = "<table cellpadding='3' cellspacing='0' border='0' align='left' width='100%' style='border-width: 0 0 0 0;'>";
	
	$all_childs = get_childau_sub($auDN,array("dn","ou","maxipblock","associateddomain"));
	$childs = get_subnet_childaus($all_childs,$subnet['cn']);
	
	foreach ($childs as $au) {
		
		# AUs die Subnet administrieren in rot
		$red = "";	
		$red_end = "";
		if ($au[netadmin]) {
			$red = "<code class='red_font_object'>";
			$red_end = "</code>";
		}
		
		$subnetip .= "
			<tr valign='top'>
				<td width='19%' class='tab_dgrey'>$red $au[au] $red_end</td>
				<td width='24%' class='tab_dgrey'>$au[zone]&nbsp;</td>
				<td width='17%' class='tab_dgrey'>";		
		
		$subnetip .= "<table cellpadding='0' cellspacing='0' border='0' align='right' width='100%'>";
		if (is_array($au[mipb]) ) {
			foreach ($au[mipb] as $item) {
				$subnetip .= "<tr valign='top'>
									$red $item $red_end
								</tr>";
			}
					
		}else{
			$subnetip .= "<tr valign='top'>
								$red $au[mipb] $red_end
							  </tr>";
		}
		$subnetip .= "</table>
						</code></td>
						<td class='tab_dgrey'>
						<table cellpadding='0' cellspacing='0' border='0' align='right' width='100%'>";

   	# Pools des Subnetzes
   	$pools = get_dhcppools_subnet_au($subnet['dn'],$au['dn'],array("dn","dhcprange","dhcpoptallow","dhcpoptdeny","dhcpoptignore","dhcppermittedclients"));
		if ($pools) {   
		
		$poolnr = 1;
   	foreach ($pools as $pool){
   		$subnetip .= "<tr valign='top'><td>";
      	if (count($pool['dhcprange']) > 1){
         	for ($i=0; $i<count($pool['dhcprange']); $i++){
         		
         	   $exprange = explode('_',$pool['dhcprange'][$i]);
         	   $r1 = explode('.',$exprange[0]);
         	   $r2 = explode('.',$exprange[1]);
	         	$nr = "&nbsp;&nbsp;&nbsp; ";
	         	if ($i == 0) {$nr = "($poolnr) ";}
         		
         	   $subnetip .= "$nr<a href='dhcppool_one.php?dn=".$pool[dn]."&mnr=".$mnr."&url=dhcpsubnets.php' class='headerlink'><b>$r1[3] - $r2[3]</b></a> ";
         	   if ($i+1 != count($pool['dhcprange'])){
         	      $subnetip .= "<br>";
         	   }
         	}
      	}else{
      		$exprange = explode('_',$pool['dhcprange']);
         	$r1 = explode('.',$exprange[0]);
         	$r2 = explode('.',$exprange[1]);
         	$subnetip .= "($poolnr) <a href='dhcppool_one.php?dn=".$pool[dn]."&mnr=".$mnr."&url=dhcpsubnets.php' class='headerlink'><b>$r1[3] - $r2[3]</b></a> ";
      	}
      	$subnetip .= "</td><td>";
      	$prm_clients = "";
      	if ($global_data['dhcppermittedclients']){
         	$prm_clients = " &nbsp; - &nbsp; ".$global_data['dhcppermittedclients'];
      	}
      	elseif ($subnet['dhcppermittedclients']){
         	$prm_clients = " &nbsp; - &nbsp; ".$subnet['dhcppermittedclients'];
      	}
      	elseif ($pool['dhcppermittedclients']){
         	$prm_clients = " &nbsp; - &nbsp; ".$pool['dhcppermittedclients'];
      	}
      	$subnetip .= $prm_clients;
      	
      	$subnetip .= "</td></tr>";
      	$poolnr++;
   	}
   	
   	}else{
   		$subnetip .= "<tr valign='top'><td>&nbsp;</td></tr>";
   	}
   	$subnetip .= "</table>
   					</td></tr>";
	}
	$subnetip .= "</table>";   
      
   $template->assign(array("SUBNETDN" => $subnet['dn'],
									"SUBNETCN" => $subnetcn,
	   	        		      "NETMASK" => $subnet['dhcpoptnetmask'],
	   	        		      "DHCP" => $dhcpservice,	   	        		      
	   	        		      "SUBNETIP" => $subnetip,
	   	        		      "MNR" => $mnr,));
	$template->parse("SUBNETS_LIST", ".Subnets");
	
}


###################################################################################

include("dhcp_footer.inc.php");

?>
