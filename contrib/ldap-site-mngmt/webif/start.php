<?php

#Pfad festlegen wo die Dateien sich befinden
include('start_header.inc.php');
session_unregister('rollen');
session_unregister('all_roles');


$titel = "Rechner und IP Management Startseite";
$webseite = "home.dwt";

# neues Template-Objekt erstellen
$template = new FastTemplate(".");
# dem erstellten Template-Objekt eine Vorlage zuweisen
$template->define(array("Vorlage" => "index.dwt",
                        "Login" => "logout_form.inc.dwt",
                        "Webseite" => $webseite));

$template->assign(array("SEITENTITEL" => $titel,"USERCN" => $usercn));
############################################################

function build_au_array($au,$parentau) {

	global $ds, $ldaperror, $tree_array, $tree;
	
	if ($parentau == ""){
		$tree_array[$au]['mode'] = "exp";
	}else{
		$tree_array[$au]['mode'] = "coll";
	}
	# au data
	$au_data = get_au_data($au,array("ou","associateddomain"));
	#print_r($au_data); echo "<br><br>";
	
	$tree_array[$au]['roles'] = get_au_roles($au);
	# Falls MainAdmin dann auch MainAdmin automatisch im gesamten Subtree
	if ( $parentau && in_array("MainAdmin",$tree_array[$parentau]['roles']) ) {
		if ( !in_array("MainAdmin",$tree_array[$au]['roles']) ) {
			$tree_array[$au]['roles'][] = "MainAdmin";
		}
	}
	
	if ( $tree_array[$au]['roles'] ) {
		$roles = implode('_',$tree_array[$au]['roles']);
		$tree_array[$au]['zone'] = $au_data[0]['associateddomain'];
		
		if ( $au_data[0]['associateddomain'] ) {
			$tree_array[$au]['text'] = "<a href='zwischen.php?audn=$au' class='headerlink'><b>".$au_data[0]['ou']."</b></a>
												&nbsp;&nbsp;&nbsp;[ ".$au_data[0]['associateddomain']." ]";
		}else{
			$tree_array[$au]['text'] = "<code class='inactive_au'>".$au_data[0]['ou']."</code> &nbsp;(Nicht aktiviert - noch keine DNS Zone)";
		}
		 
	} else {
		$tree_array[$au]['text'] = "<code class='noadmin_au'>".$au_data[0]['ou']."</code>";
	}
	
	# childaus
	$childs = get_childau($au,array("dn","ou"));
	if ($childs) {
		if ( $tree_array[$au]['roles'] ) {
			$tree_array[$au]['mode'] ="exp";
		}else{
			$tree_array[$au]['mode'] ="coll";
		}
		
		foreach ($childs as $child) {
			$childau = $child['dn'];
			$tree_array[$au]['childs'][] = $childau;
			
			# rekursiver Aufruf
			build_au_array($childau,$au);
			
			# Tree Pfad zu AUs unten expanden
			if ($tree_array[$childau]['roles'] || $tree_array[$childau]['mode'] == "exp") {
				$tree_array[$au]['mode'] = "exp";
			}
		}
	}
}

function get_au_roles($audn) {
	
	global $ds, $userDN, $ldapError;
	$au_roles = array();
	
	if(!($result = uniLdapSearch($ds, "cn=roles,".$audn, "(&(member=$userDN)(cn=*))", array("dn","cn"), "cn", "list", 0, 0))) {
       redirect(5, "index.php", $ldapError, FALSE);
       die;
   }else{
	   $result = ldapArraySauber($result);
		#print_r($result);
	   foreach($result as $item) {
	   	$au_roles [] = $item['cn'];
	   }
	  	return $au_roles;
	}
}

function draw_tree($au,$indent,$propindent) {
	
	global $tree, $tree_array;
	
	$tree .= "<tr height='25' valign='center'>
					$indent<td width='100%' class='tab_d_ohne' colspan='10'>".$tree_array[$au]['text']."</td>
				</tr>";
	$max = 0;
	foreach ($tree_array[$au]['childs'] as $child) {
		if ($tree_array[$child]['mode'] == "exp" || $tree_array[$child]['roles']) {
			$max++;
		}
	}
	#echo "<br>max $max ->";
	$$au = 1; 
			
	foreach ($tree_array[$au]['childs'] as $childau) {
	
		if ($tree_array[$childau]['mode'] == "exp" || $tree_array[$childau]['roles']){
			#echo " ${$au} |";	
			if ($indent == "") {
				if ($max == ${$au}) {
					$newindent = "<td width='5%' class='tab_d_ohne' align='center'><img src='pics/ecke.gif' width='30' height='25' border='0' alt=''></td>";
					$newpropindent = "<td width='5%' class='tab_d_ohne' align='center'><img src='pics/blank.gif' width='30' height='25' border='0' alt=''></td>";
				}else{
					$newindent = "<td width='5%' class='tab_d_ohne' align='center'><img src='pics/tee.gif' width='30' height='25' border='0' alt=''></td>";
					$newpropindent = "<td width='5%' class='tab_d_ohne' align='center'><img src='pics/linie.gif' width='30' height='25' border='0' alt=''></td>";				
				}
			}else{
				if ($max == ${$au}) {
					$newindent = $propindent."<td width='5%' class='tab_d_ohne' align='center'><img src='pics/ecke.gif' width='30' height='25' border='0' alt=''></td>";
					$newpropindent = $propindent."<td width='5%' class='tab_d_ohne' align='center'><img src='pics/blank.gif' width='30' height='25' border='0' alt=''></td>";
				}else{
					$newindent = $propindent."<td width='5%' class='tab_d_ohne' align='center'><img src='pics/tee.gif' width='30' height='25' border='0' alt=''></td>";
					$newpropindent = $propindent."<td width='5%' class='tab_d_ohne' align='center'><img src='pics/linie.gif' width='30' height='25' border='0' alt=''></td>";				
				}
			}

			draw_tree($childau,$newindent,$newpropindent);
			
			${$au}++;
		}
		
	}
	
}

############################################################ 

$tree_array = array();

build_au_array($rootAU,"");
#print_r($tree_array);
foreach (array_keys($tree_array) as $au){
	if ( $tree_array[$au]['roles'] ) {
		$all_roles[$au]['roles'] = $tree_array[$au]['roles']; 
		$all_roles[$au]['zone'] = $tree_array[$au]['zone'];
	}
}
$_SESSION['all_roles'] = $all_roles;
#print_r($_SESSION['all_roles']);

$tree = "";
$text = "Um zu den Administrations-Seiten einer AU zu kommen, w&auml;hlen Sie entsprechenden Link.";

if (!$all_roles) {
	$text = "Sie sind in der Benutzerdatenbank des <b>net&lowast;Client Management</b> registriert<br>
				Ihnen wurden jedoch noch keine administrativen Rechte zugeordnet<br><br>
				Wenden Sie sich bitte an<br><br>
				<b>**DHCP USER EMAIL**</b>";
}else{
	draw_tree($rootAU,"","");
}

$template->assign(array( "TEXT" => $text));
$template->assign(array( "TREE" => $tree));

############################################################# 

# Daten in die Vorlage parsen
$template->assign(array("PFAD" => $START_PATH));

$template->parse("LOGIN", "Login");
$template->parse("HAUPTFENSTER", "Webseite");
$template->parse("PAGE", "Vorlage");

# Fertige Seite an den Browser senden
$template->FastPrint("PAGE");

?>
