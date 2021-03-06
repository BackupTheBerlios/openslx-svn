<?php

function createAUMenu($rollen, $mnr, $auDN,$sbmnr) {
	
	global $template, $ds, $suffix, $START_PATH, $au_ou;
	
	# Mainmenu 
	$hauptmenu = array(array("link" => "au.php",
			"text" => "&Uuml;bersicht",
			"zugriff" => "alle"),
		array("link" => "au_show.php",
			"text" => "AU $au_ou",
			"zugriff" => array("MainAdmin","DhcpAdmin","HostAdmin")),
		array("link" => "au_childs.php",
			"text" => "Untergeordnete AUs",
			"zugriff" => array("MainAdmin")),
		array("link" => "roles.php",
			"text" => "AU Administratoren",
			"zugriff" => array("MainAdmin")),
		#array("link" => "new_child.php",
		#	"text" => "Neue untergeordnete AU",
		#	"zugriff" => array("MainAdmin"))
		);
	#echo "hauptmenu: ";print_r($hauptmenu);echo "<br><br>";
	
	# Submenu 
	$childaus = array();
	$n = 0;	
	#$childau_array = get_childau($auDN,array("dn","cn","ou"));
	#echo "childau_array: ";print_r($childau_array);echo "<br><br>";
	#if (count($childau_array)!= 0){
   #	for ($n=0;$n<count($childau_array);$n++) {
   #		$childaus[] = array("link" => "child_au.php?dn=".$childau_array[$n]['dn']."&sbmnr=".$n,
   #			"text" => $childau_array[$n]['ou'],
   #			"zugriff" => array("MainAdmin"));
   #	}
   #	#$c=0+$n;
	#}
	#$c = $n;
	$childaus[] = array("link" => "new_child.php?sbmnr=".$n,
							"text" => "Neue AU anlegen",
							"zugriff" => array("MainAdmin"));
	
	$adminroles = array(array("link" => "role_show.php?role=MainAdmin&sbmnr=0",
                             "text" => "Main Admins",
                             "zugriff" => array("MainAdmin")),
                       array("link" => "role_show.php?role=HostAdmin&sbmnr=1",
                             "text" => "Client Admins",
                             "zugriff" => array("MainAdmin")),
                       array("link" => "role_show.php?role=DhcpAdmin&sbmnr=2",
                             "text" => "DHCP Admins",
                             "zugriff" => array("MainAdmin")),
                       array("link" => "role_show.php?role=RbsAdmin&sbmnr=3",
                             "text" => "RemoteBoot Admins",
                             "zugriff" => array("MainAdmin")),
                       array("link" => "role_show.php?role=ZoneAdmin&mnr=4",
                             "text" => "DNS Zonen Admins",
                             "zugriff" => array("ZoneAdmin"))
                       );
	
	
	$submenu = array(array(),
							array(),
							$childaus,
							$adminroles
						);
	#echo "submenu: ";print_r($submenu);echo "<br><br>";
	# Zusammenstellen der Menuleiste
	$template->define_dynamic("Hauptmenu", "Menu");
	$template->define_dynamic("Submenu", "Menu");
	
	$i=0;
	$maxmenu = count($hauptmenu);
	
	foreach ($hauptmenu as $item) {
		$template->clear_parse("SUBMENU_LIST");
		#echo "item: "; print_r($item); echo "<br>"; 
		if ($item['zugriff'] === "alle" || vergleicheArrays($rollen , $item['zugriff'])) {
			
			#########################################################################
  			# SUBMENU 
  						
			$subempty = 0;
			$j=0;
			$maxsub = count($submenu[$mnr]);
			#echo "maxsub: "; print_r($maxsub); echo "<br>";
			if ($maxsub > 0) {
				foreach ($submenu[$mnr] as $item2) {
				   #echo "item2: "; print_r($item2); echo "<br>"; 
					if ($item2['zugriff'] === "alle" || vergleicheArrays($rollen, $item2['zugriff'])) {
						if ($i != $mnr) {
							$template->assign(array("SUB" => ""));
								#"LINK_S" => "",
								#"TEXT_S" => ""));
								$template->parse("SUBMENU_LIST", ".Submenu");
								$template->clear_dynamic("Submenu");
						}
						else {
							if ($j==0) {
								if ($sbmnr==0) {
									if ($maxsub == 1) {$zwisch="branchbottom2";}
									else {$zwisch="branch2";}
									$lastaktive=true;
									$farb="#505050";
								}
								else {
									if ($maxsub == 1) {$zwisch="branchbottom2";}
									else {$zwisch="branch2";}
										$farb="#A0A0A0";  
									$lastaktive=false;
								}
							}
							else {
								if ($sbmnr==$j) { 
									if ($maxsub == $j+1) {$zwisch="branchbottom2";}
									else {$zwisch="branch2";}
									$lastaktive=true; 
									$farb="#505050"; 
								}
								else {
									$farb="#A0A0A0";
									if ($maxsub == $j+1) {$zwisch="branchbottom2";}
									else {$zwisch="branch2";}
									# if ($lastaktive) {$zwisch="branch";}
									# else {$zwisch="branch";}
									$lastaktive=false;
								}
							}
							$htmlcode= "
								<tr height='2'>
									<td></td>
									<td align='right'><img src='../pics/line2.gif' height='2'></td>
									<td colspan='2'></td>
								</tr>
								<tr>
									<td width='8%'></td>
									<td width='8%' align='right'><img src='../pics/".$zwisch.".gif'></td>
									<td width='74%' align='left' style='border-width:1 1 1 1;border-color:#000000;border-style:solid;padding:4;padding-left:25px;background-color:{FARBE_S}'>
										<a href='".$item2['link']."' style='text-decoration:none'><code class='submenue_schrift'>".$item2['text']."</code></a></td>
									<td width='10%'></td>
								</tr>";
							
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
			if ($subempty == count($submenu[$mnr])) {
				$template->assign(array("SUB" => ""));
					#"LINK_S" => "",
					#"TEXT_S" => ""));
				$template->parse("SUBMENU_LIST", ".Submenu");
				$template->clear_dynamic("Submenu");
			}
			# SUBMENU		
  			#####################################################################
  			
  			
			if ($i==0) {
				if ($mnr==0) {
					if (count($submenu[$i][0]) != 0) {
						if ($maxmenu == 1) {$zwisch="";} # {$zwisch="<img style='border-width:0;border-style=none;' src='../pics/minus2.gif'>";}
						else {$zwisch="";}
					}
					else {$zwisch="";}
					$lastaktive=true;
					$farb="#505050";
				}
				else {
					if (count($submenu[$i][0]) != 0) {
						if	($maxmenu == 1)	{
								$zwisch="<a href='{LINK_M}' style='border-style=none;text-decoration:none'>
									<img style='border-width:0;border-style=none;' src='../pics/plus3.gif'></a>";
						}
						else {
							$zwisch="<a href='{LINK_M}' style='border-style=none;text-decoration:none'>
								<img style='border-width:0;border-style=none;' src='../pics/plus3.gif'></a>";
						}
					}
					else {$zwisch="";}
					$farb="#A0A0A0";
					$lastaktive=false;
				}
			}
			else {
				if ($mnr==$i) {
					if (count($submenu[$mnr][0]) != 0) {
						if ($maxmenu == $i+1) {$zwisch="";}
						else {$zwisch="";}
					}
					else {$zwisch="";}
					$lastaktive=true;
					$farb="#505050";
				}
				else {
					$farb="#A0A0A0";
					if (count($submenu[$i][0]) != 0) {
						if ($maxmenu == $i+1) {
							$zwisch="<a href='{LINK_M}' style='border-style=none;text-decoration:none'>
								<img style='border-width:0;border-style=none;' src='../pics/plus3.gif'></a>";
						}
						else {
							$zwisch="<a href='{LINK_M}' style='border-style=none;text-decoration:none'>
								<img style='border-width:0;border-style=none;' src='../pics/plus3.gif'></a>";
						}
					}
					else {$zwisch="";}
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
	if ($lastaktive) {
		$template->assign(array("ENDE" => ""));
	}
	else{
		$template->assign(array("ENDE" => ""));
	}
	
}

?>