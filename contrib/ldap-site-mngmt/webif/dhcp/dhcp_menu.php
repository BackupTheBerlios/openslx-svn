<?php

function createDhcpMenu($rollen, $mnr, $auDN, $sbmnr) {
	
	global $template, $START_PATH, $rootAU; 
	
	$i=0;
	
	$mipbs = get_maxipblocks_au($auDN);
	#echo "MIPB: "; print_r ($mipbs); echo "<br>";
	if ($mipbs[0] != ""){
		$hauptmenu = array();
	}else{
		$hauptmenu = array(array("link" => "no_dhcp.php?mnr=".$i,
                             "text" => "&Uuml;bersicht",
                             "zugriff" => "alle"));
      $i++;        
	}
	
	$pools = get_dhcppools($auDN, array("dn"));
	if (count($pools) == 0){
		$poollink = "dhcpnopool.php";
	}else{
		$poollink = "dhcppools.php";
	}   
	
   
   if ( $auDN == $rootAU ) {
      $dhcpservice_array = get_dhcpservices($auDN,array("dn","cn"));
      if (count($dhcpservice_array) == 0){
      	$dhcpsvlink = "new_dhcpservice.php?mnr=1";
      }
      else {
      	$dhcpsvlink = "dhcpservice.php?mnr=1";
      }
      $hauptmenu []= array("link" => $dhcpsvlink,
                           "text" => "DHCP Service",
                           "zugriff" => array("MainAdmin","DhcpAdmin"));
      $i++;
   }
   #if ($mipbs[0] != ""){
      #if ( check_if_max_networks() ){
         $hauptmenu [] = array("link" => "dhcpsubnets.php?mnr=".$i,
                                "text" => "DHCP Subnets",
                                "zugriff" => array("MainAdmin","DhcpAdmin"));
	if ($mipbs[0] != ""){
	      $subnets = array();
		   # falls komplette Netze verfügbar, link zum Neuanlegen
   	   if ( check_if_free_networks() ){
   	      #$dhcpsubnet_array = get_dhcpsubnets($auDN,array("dn","cn"));
   	      /*for ($j=0;$j<count($dhcpsubnet_array);$j++){
      	  		$subnets[] = array("link" => "dhcpsubnet.php?dn=".$dhcpsubnet_array[$j]['dn']."&mnr=".$i."&sbmnr=".$j,
      	  							"text" => $dhcpsubnet_array[$j]['cn'],
      								"zugriff" => array("MainAdmin","DhcpAdmin"));
      	  	}*/
      	   $subnets[] = array("link" => "new_dhcpsubnet.php?mnr=".$i."&sbmnr=0",
      	                   "text" => "Neues DHCP Subnet",
      	                   "zugriff" => array("MainAdmin","DhcpAdmin"));
   	   }
   	   $i++;
         $hauptmenu [] = array("link" => $poollink."?mnr=".$i,
                                "text" => "Dynamische DHCP Pools",
                                "zugriff" => array("MainAdmin","DhcpAdmin"));

         $submenu = array(#array(),
          	              $subnets,
          	              array());
      #}else{
      #   $hauptmenu [] = array("link" => $poollink."?mnr=".$i,
      #                          "text" => "Dynamische DHCP Pools",
      #                          "zugriff" => array("MainAdmin","DhcpAdmin"));
      #}
   }
   
   # DHCP Classes
   if ( $auDN == $rootAU ) {
   	$hauptmenu []= array("link" => "dhcp_classes.php?mnr=".++$i,
                           "text" => "DHCP Classes",
                           "zugriff" => array("MainAdmin","DhcpAdmin"));
		$hauptmenu []= array("link" => "dhcp_condstmts.php?mnr=".++$i,
                           "text" => "DHCP Conditional Statements",
                           "zugriff" => array("MainAdmin","DhcpAdmin"));
   }

   # Zusammenstellen der Menuleiste
   $template->define_dynamic("Hauptmenu", "Menu");
   $template->define_dynamic("Submenu", "Menu");
   $i=0;
   $maxmenu = count($hauptmenu);
	
	foreach($hauptmenu as $item) {
		$template->clear_parse("SUBMENU_LIST");
		if($item['zugriff'] === "alle" || vergleicheArrays($rollen , $item['zugriff'])) {
			
			$subempty = 0;
			$j=0;
			$maxsub = count($submenu[$mnr]);
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
      		               if($maxsub == 1){$zwisch="";}
      		               else {$zwisch="";}
      		               $lastaktive=true;
      		               $farb="#505050";
      		            }
      		            else{
      		               if($maxsub == 1){$zwisch="";}
      		               else {$zwisch="";}
      		               $farb="#A0A0A0";  
      		               $lastaktive=false;
      		            }
      		         }
      		         else {
      		         	if ($sbmnr==$j) { 
      		            	if($maxsub == $j+1){$zwisch="";}
      		               else {$zwisch="";}
      		               $lastaktive=true; 
      		               $farb="#505050"; 
      		            }
      		            else {
      		               $farb="#A0A0A0";
      		               if($maxsub == $j+1){$zwisch="";}
      		               else {$zwisch="";}
      		               # if ($lastaktive) {$zwisch="branch";} 
      		               # else {$zwisch="branch";}
      		               $lastaktive=false;
      		            } 
      		        	}
      		   		$htmlcode= "
      		   		<tr height='2'>
      						<td></td><td></td><td></td><td></td>
      		   		</tr>
      		   		<tr>
      						<td width='8%'>&nbsp;</td>
      						<td width='8%' align='right'>".$zwisch."</td>
      		     			<td width='74%' align='left' style='border-width:1 1 1 1;border-color:#000000;border-style:solid;padding:2;padding-left:15px;background-color:{FARBE_S}'> 
      		     			<a href='".$item2['link']."' style='text-decoration:none'><code class='submenue_schrift'>".$item2['text']."</code></a></td>
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
         
         # weiter im Hauptmenü
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
               	<img style='border-width:0;border-style=none;' src='../pics/plus3.gif'></a>";}
		         else {$zwisch="<a href='{LINK_M}' style='border-style=none;text-decoration:none'>
               	<img style='border-width:0;border-style=none;' src='../pics/plus3.gif'></a>";}
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
               $farb="#A0A0A0";
               if(count($submenu[$i][0]) != 0){
               if($maxmenu == $i+1){$zwisch="<a href='{LINK_M}' style='border-style=none;text-decoration:none'>
               	<img style='border-width:0;border-style=none;' src='../pics/plus3.gif'></a>";}
		         else {$zwisch="<a href='{LINK_M}' style='border-style=none;text-decoration:none'>
               	<img style='border-width:0;border-style=none;' src='../pics/plus3.gif'></a>";}
		         }else{$zwisch="";}
               #if ($lastaktive) {$zwisch="";}
               #else {$zwisch="";}
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
   else {$template->assign(array("ENDE" => ""));}
}

?>