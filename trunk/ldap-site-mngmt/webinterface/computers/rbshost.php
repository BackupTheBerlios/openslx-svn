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
$webseite = "rbshost.dwt";

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
$dhcp_selectbox = "";

$rbs = "";
$nodhcptext = "";

# Falls nicht DHCP Dienst dann Erklärung ... 
if ($dhcphlpcont == ""){
	
	$nodhcptext .= "Der Rechner ist in keinem DHCP Dienst eingetragen. Dies ist jedoch Voraussetzung,
	         um einen Remote Boot Dienst nutzen zu k&ouml;nnen.<br>
	         D.h. die hier verwalteten RBS-relevanten DHCP Optionen werden bzw. sind f&uuml;r den Client zentral gespeichert, 
	         werden jedoch in keine DHCP Dienst Konfiguration &uuml;nernommen.
	        ";
}
# <input type='hidden' name='rbs' value='".$rbsDN."'> 
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
   
   $rbs .= "<td class='tab_d_ohne'><b>Remote Boot Dienst: </b>&nbsp;</td>
           <td class='tab_d_ohne'>
            Rechner ist in keinem Remote Boot Dienst angemeldet<br></td></tr>
           <tr valign='top'><td class='tab_d'>
			   RBS ausw&auml;hlen: <br></td>".$rbs_selectbox;
}else{
   
   $rbsdata = get_node_data($rbsDN,array("tftpserverip"));
   #print_r($rbsdata); echo "<br>";
   $exp2 = explode(',',$host['hlprbservice']);
   $exprbs = explode('=',$exp2[0]); $rbserv = $exprbs[1];
   $exprbsau = explode('=',$exp2[2]); $rbsau = $exprbsau[1];
   $rbs .= "<tr valign='top'>
               <td class='tab_d_ohne'><b>Remote Boot Dienst: </b>&nbsp;</td>
               <td class='tab_d_ohne'>
                  Remote Boot Service <b>".$rbserv."</b> / AU <b>".$rbsau."</b></td>
            </tr>
            <tr>
				   <td class='tab_d_ohne'>DHCP Option <b>next-server</b> &nbsp;(TFTP Boot Server IP):</td>
				   <td class='tab_d_ohne'><b>".$host['dhcpoptnext-server']."</b>&nbsp;</td>
			   </tr>
			   <tr>
				   <td class='tab_d'>DHCP Option <b>filename</b> &nbsp;(initiale remote Bootdatei):</td>
				   <td class='tab_d'><b>".$host['dhcpoptfilename']."</b>&nbsp;</td>
			   </tr>
            <tr valign='top'><td class='tab_d'>
					RBS Einbindung &auml;ndern: <br></td>".$rbs_selectbox."
				</tr>";
	
	$rbs_dhcpopt = "";
}



$template->assign(array("HOSTDN" => $hostDN,
								"HOSTNAME" => $host['hostname'],
           			      "DOMAINNAME" => $host['domainname'],
           			      "HWADDRESS" => $host['hwaddress'],
           			      "IPADDRESS" => $hostip[0],
           			      "DESCRIPTION" => $host['description'],
           			      "OLDDHCP" => $objectDN,
           			      "OLDFIXADD" => $host['dhcpoptfixed-address'],
           			      "NODHCP" => $nodhcptext,
           			      "OLDRBS" => $rbsDN,
           		       	"RBS" => $rbs,
           		       	"HOSTLINK" => "<a href='host.php?dn=".$hostDN."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"DHCPLINK" => "<a href='dhcphost.php?dn=".$hostDN."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"HWLINK" => "<a href='hwhost.php?dn=".$hostDN."&sbmnr=".$sbmnr."' class='headerlink'>",
           		       	"AUDN" => $auDN,
           		       	"SBMNR" => $sbmnr));




# Rechnerspezifische PXEs
$hostpxeconfigs = get_pxeconfigs($hostDN, array("dn","cn","description","timerange"));

$template->assign(array("PXEDN" => "",
								"PXECN" => "Keine PXE Config angelegt",
								"PXEDESC" => "",
								"PXETR" => "",));
$template->define_dynamic("Rechnerpxes", "Webseite");

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
      $template->assign(array("PXEDN" => $hostpxeconfigs[$i]['dn'],
   								"PXECN" => $pxelink,
              			      #"PXEDESC" => $hostpxeconfigs['description'],
              			      "PXETR" => $trange, ));
   	$template->parse("RECHNERPXES_LIST", ".Rechnerpxes");
   
   }
}

# Default PXEs des RBS 
$defaultpxeconfigs = get_pxeconfigs($rbsDN,array("dn","cn","description","timerange","filename"));

$template->assign(array("DEFPXEDN" => "",
								"DEFPXECN" => "Keine PXE Config angelegt",
								"DEFPXEDESC" => "",
								"DEFPXETR" => "",));
$template->define_dynamic("Defpxes", "Webseite");

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
      
      $template->assign(array("DEFPXEDN" => $defaultpxeconfigs[$i]['dn'],
   								"DEFPXECN" => $defpxelink,
              			      "DEFPXEDESC" => $defaultpxeconfigs['description'],
              			      "DEFPXETR" => $deftrange, ));
   	$template->parse("DEFPXES_LIST", ".Defpxes");
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

###################################################################################

include("computers_footer.inc.php");

?>