<?php

function createRBSMenu($rollen, $mnr, $auDN, $sbmnr) {
	global $template;
 	global $START_PATH;
 	
 	# rbservices (momentan nur für einen RBS konzipiert)
 	$rbs_array = get_rbservices($auDN,array("dn","cn"));

 	# Struktur der Registerkartenleiste 	
 	$hauptmenu = array(array("link" => "rbs.php?mnr=0",
            	           	"text" => "&Uuml;bersicht",
           		            "zugriff" => "alle"));
   $submenu = array(array());
           		            	
 	$n = 1;
   if (count($rbs_array) != 0){
      for ($i=0;$i<count($rbs_array);$i++){
         
         $hauptmenu [] = array("link" => "rbservice.php?rbsdn=".$rbs_array[$i]['dn']."&mnr=".$n,
	  							 "text" => $rbs_array[$i]['cn'],
	      	             "zugriff" => array("MainAdmin","HostAdmin"));
	      $submenu [] = array(
	                        array("link" => "gbm_overview.php?rbsdn=".$rbs_array[$i]['dn']."&mnr=".$n."&sbmnr=0",
           	          	        "text" => "Generische Bootmen&uuml;s",
           		                    "zugriff" => array("MainAdmin","HostAdmin")),
           		            array("link" => "pxeconfig_default.php?rbsdn=".$rbs_array[$i]['dn']."&mnr=".$n."&sbmnr=1",
            	          	        "text" => "Default PXE Configs",
           		                    "zugriff" => array("MainAdmin","HostAdmin")),
           		            array("link" => "new_gbm.php?rbsdn=".$rbs_array[$i]['dn']."&mnr=".$n."&sbmnr=2",
           	          	        "text" => "Neues GBM anlegen",
           		                    "zugriff" => array("MainAdmin","HostAdmin")),
           		            array("link" => "new_pxe.php?rbsdn=".$rbs_array[$i]['dn']."&mnr=".$n."&sbmnr=3",
           	          	        "text" => "Neue PXE Config anlegen",
           		                    "zugriff" => array("MainAdmin","HostAdmin")), 
          		             );
         $n++;
      }
   }
   $hauptmenu [] = array("link" => "new_rbservice.php?&mnr=".$n,
	 					 "text" => "Neuen RBS anlegen",
	      	       "zugriff" => array("MainAdmin","HostAdmin"));
   
   $submenu [] = array();   
   #print_r($hauptmenu); echo "<br><br>";
   #print_r($submenu);


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
		               if($maxsub == 1){$zwisch="branchbottom2";}
		               else {$zwisch="branch2";}
		               $lastaktive=true;
		               $farb="#505050";
		            }
		            else{
		               if($maxsub == 1){$zwisch="branchbottom2";}
		               else {$zwisch="branch2";}
		               $farb="#A0A0A0";  
		               $lastaktive=false;
		            }
		         }
		         else {
		         	if ($sbmnr==$j) { 
		            	if($maxsub == $j+1){$zwisch="branchbottom2";}
		               else {$zwisch="branch2";}
		               $lastaktive=true; 
		               $farb="#505050"; 
		            }
		            else {
		               $farb="#A0A0A0";
		               if($maxsub == $j+1){$zwisch="branchbottom2";}
		               else {$zwisch="branch2";}
		               # if ($lastaktive) {$zwisch="branch";} 
		               # else {$zwisch="branch";}
		               $lastaktive=false;
		            } 
		        	}
		   		$htmlcode= "
		   		<tr height='4'>
						<td></td><td align='right'><img src='../pics/line2.gif' height='4'></td><td></td><td></td>
		   		</tr>
		   		<tr>
						<td width='8%'>&nbsp;</td>
						<td width='8%' align='right'><img src='../pics/".$zwisch.".gif'></td>
		     			<td width='74%' align='left' style='border-width:1 1 1 1;border-color:#000000;border-style:solid;padding:2;padding-left:30px;background-color:{FARBE_S}'> 
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
               $farb="#A0A0A0";
               if(count($submenu[$i][0]) != 0){
               if($maxmenu == $i+1){$zwisch="<a href='{LINK_M}' style='border-style=none;text-decoration:none'>
               	<img style='border-width:0;border-style=none;' src='../pics/plus2.gif'></a>";}
		         else {$zwisch="<a href='{LINK_M}' style='border-style=none;text-decoration:none'>
               	<img style='border-width:0;border-style=none;' src='../pics/plus2.gif'></a>";}
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
   else{
   	$template->assign(array("ENDE" => ""));
 	}

}

?>