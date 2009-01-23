<?php

include('../standard_header.inc.php');

# Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "rbshost.dwt";

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
$attributes = array("hostname","domainname","ipaddress","hwaddress","description","hlprbservice",
                     "dhcphlpcont","dhcpoptfixed-address","dhcpopthardware","dhcpoptfilename",
                     "dhcpoptnext-server","hw-mouse","hw-graphic","hw-monitor");
$host = get_node_data($hostDN,$attributes);
$rbsDN = $host['hlprbservice'];

if ( $rbsDN ) {
	$exprbs = ldap_explode_dn($rbsDN, 1);

	# Rechnerspezifische PXEs
	$hostpxeconfigs = get_pxeconfigs2($hostDN, array("dn","cn","description","timerange"));
	
	$pxehost = "<tr>
						<td colspan='3' width='50%' class='tab_h'>
						<b>Client <code class='font_object'> ".$host['hostname']." 
						</code> - spezifische PXE Konfigurationen (Bootmen&uuml;s)</b></td>
					</tr>";
	if (count($hostpxeconfigs) != 0){
   	for ($i=0;$i<count($hostpxeconfigs);$i++){
   	   $pxelink = "<a href='pxe.php?dn=".$hostpxeconfigs[$i]['dn']."&mnr=1&sbmnr=".$sbmnr."&mcnr=".$i."&nodedn=".$hostDN."' class='headerlink'>".$hostpxeconfigs[$i]['cn']."</a>";
   
      	$trange = "";
   		if (count($hostpxeconfigs[$i]['timerange']) > 1 ){
   			foreach ($hostpxeconfigs[$i]['timerange'] as $tr){
   				$exptime = array_merge(explode('_',$tr), array($hostpxeconfigs[$i]['cn']));
   				$timeranges[$i][] = $exptime; # Für grafische Wo-Ansicht
   				if ($exptime[0] == "X"){$exptime[0]="t&auml;glich";}
   				# if ($exptime[1] == "X" && $exptime[2] == "X"){$exptime[1] = ""; $exptime[2]= "";}
   				$trange .= $exptime[0].", von ".$exptime[1].":00 bis ".$exptime[2].":59 <br> "; 
   			}
   		}else{
   			$exptime = array_merge(explode('_',$hostpxeconfigs[$i]['timerange']), array($hostpxeconfigs[$i]['cn']));
   			$timeranges[$i] = $exptime; # Für grafische Wo-Ansicht
   			if ($exptime[0] == "X"){$exptime[0]="t&auml;glich";}
   			# if ($exptime[1] == "X" && $exptime[2] == "X"){$exptime[1] = ""; $exptime[2]= "";}
   			$trange .= $exptime[0].", von ".$exptime[1].":00 bis ".$exptime[2].":59"; 
   		}
   		
			$pxehost .=	"<tr valign='top'>
						<td width='20%' class='tab_d'>$pxelink &nbsp;</td>
						<td width='30%' class='tab_d'>$trange &nbsp;</td>
						<td class='tab_d'> &nbsp;</td>
					</tr>";
   	}
	}else{
		$pxehost .=	"<tr valign='top'>
						<td class='tab_d' colspan='3'>Keine PXE Config angelegt </td>
					</tr>";
	}
	
	
	# Default PXEs des RBS
	$defpxe = "<tr>
					<td colspan='3' width='50%' class='tab_h'>
						<b>Default PXE Konfigurationen des gew&auml;hlten Remote Boot Dienstes <code class='font_object'> {RBSNAME} </code></b><br>
						(read-only - d.h. nur vom RBS Betreiber ver&auml;nderbar)
					</td>
				</tr>";
	
	$defaultpxeconfigs = get_pxeconfigs($rbsDN,array("dn","cn","description","timerange","filename"));
   #print_r($defaultpxeconfigs); echo "<br>";
   if (count($defaultpxeconfigs) != 0){
      for ($i=0;$i<count($defaultpxeconfigs);$i++){
         if ($defaultpxeconfigs[$i]['filename'] == "default"){
         	$defpxelink = "<a href='showpxe.php?dn=".$defaultpxeconfigs[$i]['dn']."&mnr=1&sbmnr=".$sbmnr."&mcnr=-1&hostdn=".$hostDN."' class='headerlink'>".$defaultpxeconfigs[$i]['cn']."</a>";
         
         	$deftrange = "";
      		if (count($defaultpxeconfigs[$i]['timerange']) > 1 ){
      			foreach ($defaultpxeconfigs[$i]['timerange'] as $tr){
      				$exptime = array_merge(explode('_',$tr), array($defaultpxeconfigs[$i]['cn']));
      				$timeranges[$i][] = $exptime; # Für grafische Wo-Ansicht
      				if ($exptime[0] == "X"){$exptime[0]="t&auml;glich";}
      				# if ($exptime[1] == "X" && $exptime[2] == "X"){$exptime[1] = ""; $exptime[2]= "";}
      				$deftrange .= $exptime[0].", von ".$exptime[1].":00 bis ".$exptime[2].":59 <br> "; 
      			}
      		}else{
      			$exptime = array_merge(explode('_',$defaultpxeconfigs[$i]['timerange']), array($defaultpxeconfigs[$i]['cn']));
      			$timeranges[$i] = $exptime; # Für grafische Wo-Ansicht
      			if ($exptime[0] == "X"){$exptime[0]="t&auml;glich";}
      			# if ($exptime[1] == "X" && $exptime[2] == "X"){$exptime[1] = ""; $exptime[2]= "";}
      			$deftrange .= $exptime[0].", von ".$exptime[1].":00 bis ".$exptime[2].":59"; 
      		}
      	$defpxe .=	"<tr valign='top'>
						<td width='20%' class='tab_d'>$defpxelink &nbsp;</td>
						<td width='30%' class='tab_d'>$deftrange &nbsp;</td>
						<td class='tab_d'> &nbsp;</td>
					</tr>";
			}
      }
   }



##########################################################
# PXE Wochenübersicht

# erst Defaults vom RBS Dienst
for ($i=0; $i<count($defaultpxeconfigs); $i++){
	# Timerange Komponenten
	if (count($defaultpxeconfigs[$i]['timerange']) > 1 ){
		foreach ($defaultpxeconfigs[$i]['timerange'] as $tr){
			$exptime = array_merge(explode('_',$tr),array($defaultpxeconfigs[$i]['cn']));
			$wopldeftranges[$i][] = $exptime; # Für grafische Wo-Ansicht
		}
	}else{
		$exptime = array_merge(explode('_',$defaultpxeconfigs[$i]['timerange']), array($defaultpxeconfigs[$i]['cn']));
		$wopldeftranges[$i] = $exptime; # Für grafische Wo-Ansicht
	}
}	
# Diese dann mit möglichen Rechnerspezifischen überschreiben
for ($i=0; $i<count($hostpxeconfigs); $i++){
	# Timerange Komponenten
	if (count($hostpxeconfigs[$i]['timerange']) > 1 ){
		foreach ($hostpxeconfigs[$i]['timerange'] as $tr){
			$exptime = array_merge(explode('_',$tr),array($hostpxeconfigs[$i]['cn']));
			$wopltranges[$i][] = $exptime; # Für grafische Wo-Ansicht
		}
	}else{
		$exptime = array_merge(explode('_',$hostpxeconfigs[$i]['timerange']), array($hostpxeconfigs[$i]['cn']));
		$wopltranges[$i] = $exptime; # Für grafische Wo-Ansicht
	}
}

include("pxe_wochenplan.php");

}
else{
	$pxehost = "<tr>
						<td colspan='3' class='tab_d_ohne'>
							Client <b>".$host['hostname']."</b> ist keinem Remote Boot Dienst zugewiesen.<br>
							Client-spezifische PXE Konfigurationen sind daher nicht m&ouml;glich.
						</td>
					</tr>";
	$defpxe = "";
}

$template->assign(array("HOSTDN" => $hostDN,
								"HOSTNAME" => $host['hostname'],
           		       	"PXEHOST" => $pxehost,
           		       	"DEFPXE" => $defpxe,
           			      "RBSNAME" => $exprbs[0],
           		       	"HOSTLINK" => "<a href='host.php?host=".$host['hostname']."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"DHCPLINK" => "<a href='dhcphost.php?host=".$host['hostname']."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"HWLINK" => "<a href='hwhost.php?host=".$host['hostname']."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"AUDN" => $auDN,
           		       	"SBMNR" => $sbmnr));


###################################################################################

include("computers_footer.inc.php");

?>