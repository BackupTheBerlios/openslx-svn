<?php

function createComputersMenu($rollen , $mnr, $auDN, $sbmnr, $mcnr) {
   
   global $template, $ds, $suffix, $START_PATH;
    
   # Struktur der Registerkartenleiste
   # Hauptmenu
   $hauptmenu = array(array("link" => "computers.php",
                             "text" => "&Uuml;bersicht",
                             "zugriff" => array("MainAdmin","HostAdmin","DhcpAdmin")),
    						  array("link" => "hostoverview.php",
                             "text" => "Rechner",
                             "zugriff" => array("MainAdmin","HostAdmin","DhcpAdmin")),
                       array("link" => "groupoverview.php",
                             "text" => "Rechnergruppen",
                             "zugriff" => array("MainAdmin","HostAdmin","DhcpAdmin")),
                       #array("link" => "machineconfig_default.php",
                       #      "text" => "Default MachineConfigs",
                       #      "zugriff" => array("MainAdmin","HostAdmin")),
                       #array("link" => "new_mcdef.php",
                       #      "text" => "Neue MachineConfig",
                       #      "zugriff" => array("MainAdmin","HostAdmin")),
                       array("link" => "new_pxe.php",
                             "text" => "Neues PXE Bootmen&uuml;",
                             "zugriff" => array("MainAdmin","HostAdmin","DhcpAdmin")));
	
	# Submenus 
	/*$computers_array = get_hosts($auDN,array("dn","hostname","ou"));
  	for($n=0;$n<count($computers_array);$n++){
  		
  		$comps[] = array("link" => "host.php?dn=".$computers_array[$n]['dn']."&sbmnr=".$n,
  							"text" => $computers_array[$n]['hostname'],
                    	"zugriff" => array("MainAdmin","HostAdmin","DhcpAdmin"));
      # print_r($comps); echo "<br>";
  	}*/
  	$comps[] = array("link" => "new_host.php?sbmnr=0", #.$n,
                    "text" => "Neuen Rechner anlegen",
                    "zugriff" => array("MainAdmin","HostAdmin"));
   
  	$groups_array = get_groups($auDN,array("dn","cn"));
  	for($n=0;$n<count($groups_array);$n++){
  		
  		$groups = array();
  		$groups[] = array("link" => "group.php?dn=".$groups_array[$n]['dn']."&sbmnr=".$n,
  								"text" => $groups_array[$n]['cn'],
      	              	"zugriff" => array("MainAdmin","HostAdmin","DhcpAdmin"));
      	              	
  	}
  	$groups[] = array("link" => "new_group.php?sbmnr=".$n,
                     "text" => "Neue Gruppe anlegen",
                     "zugriff" => array("MainAdmin","HostAdmin"));
   
   # default machine-configs 
   $mcdef_array = get_machineconfigs("cn=computers,".$auDN,array("dn","cn","timerange"));
   for($n=0;$n<count($mcdef_array);$n++){
   	$defmc [] = array("link" => "mcdef.php?dn=".$mcdef_array[$n]['dn']."&mnr=3&sbmnr=".$n,
  								"text" => $mcdef_array[$n]['cn'],
      	              	"zugriff" => array("MainAdmin","HostAdmin","DhcpAdmin"));
   }
   
  	$submenu = array(array(),
    	              $comps,
    	              $groups,
    	              $defmc,
    	              array());
   #echo "submenu: ";print_r($submenu);echo "<br><br>";
	
   # Zusammenstellen der Menuleiste
   $template->define_dynamic("Hauptmenu", "Menu");
	$template->define_dynamic("Submenu", "Menu");
  	$i=0;
  	
  	$maxmenu = count($hauptmenu);
   foreach($hauptmenu as $item){
   	$template->clear_parse("SUBMENU_LIST");
   	
  		if($item['zugriff'] === "alle" || vergleicheArrays($rollen , $item['zugriff'])) {
  		
  			#########################################################################
  			# SUBMENU 
  			
  			$subempty = 0;
			$j=0;
			$maxsub = count($submenu[$mnr]);
			#echo "_"; print_r($maxsub); echo "_";
			if($maxsub > 0){
  			foreach($submenu[$mnr] as $item2) {
									
		   	if($item2['zugriff'] === "alle" || vergleicheArrays($rollen, $item2['zugriff'])) {
		   		
		   		
		   		if($i != $mnr){
		   		$template->assign(array("SUB" => ""));
		         # 								"LINK_S" => "", 
		         #                       "TEXT_S" => ""));
		         $template->parse("SUBMENU_LIST", ".Submenu"); 
		         $template->clear_dynamic("Submenu");
		   		}
		   		else{
		   		if ($j==0) {
		         	if ($sbmnr==0) { 
		               if($maxsub == 1){$zwisch2="";}
		               else {$zwisch2="";}
		               $lastaktive=true;
		               $farb="#505050";
		            }
		            else{
		            	if(count($subsubmenu[$i][$j][0]) != 0){
               		if($maxsub == 1){$zwisch2="<a href='".$item2['link']."' style='border-style=none;text-decoration:none'>
               			<img style='border-width:0;border-style=none;' src='../pics/plus2.gif'></a>";}
		         		else {$zwisch2="<a href='".$item2['link']."' style='border-style=none;text-decoration:none'>
               			<img style='border-width:0;border-style=none;' src='../pics/plus2.gif'></a>";}
		         		}else{$zwisch2="";}
		               $farb="#A0A0A0";  
		               $lastaktive=false;
		            }
		         }
		         else {
		         	if ($sbmnr==$j) { 
		            	if($maxsub == $j+1){$zwisch2="";}
		               else {$zwisch2="";}
		               $lastaktive=true; 
		               $farb="#505050"; 
		            }
		            else {
		            	if(count($subsubmenu[$i][$j][0]) != 0){
               			if($maxsub == $i+1){$zwisch2="<a href='".$item2['link']."' style='border-style=none;text-decoration:none'>
               				<img style='border-width:0;border-style=none;' src='../pics/plus2.gif'></a>";}
		         			else {$zwisch2="<a href='".$item2['link']."' style='border-style=none;text-decoration:none'>
               				<img style='border-width:0;border-style=none;' src='../pics/plus2.gif'></a>";}
		         		}else{$zwisch2="";}
		               $farb="#A0A0A0";
		               $lastaktive=false;
		            } 
		        	}
		   		$htmlcode= "
		   		<tr height='4'>
						<td></td><td></td><td></td><td></td>
		   		</tr>
		   		<tr>
						<td width='8%'>&nbsp;</td>
						<td width='8%' align='right'>".$zwisch2."</td>
 						<td width='5%' align='left' style='border-width:1 0 1 1;border-color:#000000;border-style:solid;padding:4;background-color:{FARBE_S}'>&nbsp;</td>
		     			<td width='69%' align='left' style='border-width:1 1 1 0;border-color:#000000;border-style:solid;padding:4;padding-left:12px;background-color:{FARBE_S}'> 
		     			<a href='".$item2['link']."' style='text-decoration:none'><b class='standard_schrift'>".$item2['text']."</b></a></td>
						<td width='10%'>&nbsp;</td> 						
					</tr>
					";
		         $template->assign(array("SUB" => $htmlcode));		         
  		         $template->assign(array("FARBE_S" => $farb));
		         $template->parse("SUBMENU_LIST", ".Submenu"); 
		         $template->clear_dynamic("Submenu");
		         }
		      }
		      else {
		         $subempty++;
		      }
		      $j=$j+1;
		   }   
		  	}
		   if($subempty == count($submenu[$mnr])) {
		      $template->assign(array("SUB" => ""));
		     	#							  "LINK_S" => "",
		 	   #                       "TEXT_S" => ""));
		    	$template->parse("SUBMENU_LIST", ".Submenu"); 
		    	$template->clear_dynamic("Submenu");
		    	
		   }
  			# SUBMENU		
  			#####################################################################		
  				
			if ($i==0) {
         	if ($mnr==0) {
         		if(count($submenu[$i][0]) != 0){
               if($maxmenu == 1){$zwisch="";} # {$zwisch="<img style='border-width:0;border-style=none;' src='../pics/minus2.gif'>";}
		         else {$zwisch="";}
		         }else{$zwisch="";}
               $lastaktive=true;
               $farb="#505050";
            }
            else{
            	if(count($submenu[$i][0]) != 0){
               if($maxmenu == 1){$zwisch="<a href='{LINK_M}' style='border-style=none;text-decoration:none'>
               	<img style='border-width:0;border-style=none;' src='../pics/plus2.gif'></a>";}
		         else {$zwisch="<a href='{LINK_M}' style='border-style=none;text-decoration:none'>
               	<img style='border-width:0;border-style=none;' src='../pics/plus2.gif'></a>";}
		         }else{$zwisch="";}
               $farb="#A0A0A0";
               $lastaktive=false;
            }
         }
         else {
         	if ($mnr==$i) {
         		if(count($submenu[$mnr][0]) != 0){
	            	if($maxmenu == $i+1){$zwisch="";}
			         else {$zwisch="";}
   				}else{$zwisch="";}
               $lastaktive=true;
               $farb="#505050";
            }
            else {
               
               if(count($submenu[$i][0]) != 0){
               if($maxmenu == $i+1){$zwisch="<a href='{LINK_M}' style='border-style=none;text-decoration:none'>
               	<img style='border-width:0;border-style=none;' src='../pics/plus2.gif'></a>";}
		         else {$zwisch="<a href='{LINK_M}' style='border-style=none;text-decoration:none'>
               	<img style='border-width:0;border-style=none;' src='../pics/plus2.gif'></a>";}
		         }else{$zwisch="";}
               $farb="#A0A0A0";
               $lastaktive=false;
            } 
        	}
         $template->assign(array("ICON" => $zwisch,
                                 "FARBE" => $farb,
                                 "LINK_M" => $item["link"],
                                 "TEXT_M" => $item["text"]));
         $template->parse("HAUPTMENU_LIST", ".Hauptmenu");
			$template->clear_dynamic("Hauptmenu");			
      }
   	$i=$i+1;
   }
   if ($lastaktive) {$template->assign(array("ENDE" => ""));}
   else{
   	$template->assign(array("ENDE" => ""));
   } 
}
?>