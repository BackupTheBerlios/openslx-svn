<?php
include('../standard_header.inc.php');

# 1. Seitentitel - wird in der Titelleiste des Browser angezeigt. 
$titel = "Roles Management";
# 2. Nummer des zugehörigen Hauptmenus (Registerkarte) beginnend bei 0, siehe Dokumentation.doc.
$mainnr = 1;
$mnr = 1; 
# 3. Dateiname und evtl. Pfad des Templates für die Webseite
$webseite = "role_show.dwt";
$role = "MainAdmin";

include("../class.FastTemplate.php");

include("roles_header.inc.php");


###############################################################################

$mnr = $_GET['mnr'];

# Menuleiste erstellen
createMainMenu($rollen, $mainnr);
createRolesMenu($rollen, $mnr, $assocdom);

#################################### 
# Admins anzeigen und loeschen

$role = $_GET['role'];
$roles_array = get_roles($auDN);
# print_r($roles_array);

# jeder Rolle entsprechend Members holen und Überschrift setzen
switch ($role){
case 'MainAdmin':
	$template->assign(array("ROLE" => "MainAdmin","ROLE_DESC" => "Haupt Administratoren","MENR" => $mnr));
	$members = $roles_array['MainAdmin'];
	break;
case 'HostAdmin':
	$template->assign(array("ROLE" => "HostAdmin","ROLE_DESC" => "Administratoren &nbsp;- &nbsp;Rechner, Rechnergruppen, Remote Boot Services (PXE)","MENR" => $mnr));
	$members = $roles_array['HostAdmin'];
	break;
case 'DhcpAdmin':
	$template->assign(array("ROLE" => "DhcpAdmin","ROLE_DESC" => "Administratoren &nbsp;- &nbsp;DHCP","MENR" => $mnr));
	$members = $roles_array['DhcpAdmin'];
	break;
case 'ZoneAdmin':
	$template->assign(array("ROLE" => "ZoneAdmin","ROLE_DESC" => "Administratoren &nbsp;- &nbsp;DNS Zone &nbsp;[ {DOM} ]","MENR" => $mnr,"DOM" => $assocdom));
	$members = $roles_array['ZoneAdmin'];
	break;
}

# print_r($members); echo "<br><br>";

# für jedes Member Daten holen (Benutzername, UID)
if ( count($members) != 0 ){
	$members_data  = array();
 	foreach ($members as $item){
 		$members_data[] = get_user_data($item,array("dn","cn","uid","mail"));
		# print_r(get_user_data($item,array("dn","cn","uid"))); echo "<br>";
	}
}
# echo "<br>"; 
# print_r($members_data); echo "<br><br>";

if (count($members_data) != 0){
	$template->define_dynamic("Members", "Webseite");
	foreach ($members_data as $item){
		$template->assign(array("VALUE" => $item['dn'],
                              "USERNAME" => $item['cn'],
                              "UID" => $item['uid'],
                              "MAIL" => $item['mail']));
      $template->parse("MEMBERS_LIST", ".Members");	
	}
}else{
	$template->assign(array("VALUE" => "","USERNAME" => "","UID" => "","MAIL" => ""));
}


##############################################
# Admin anlegen ...
$users_array = get_users();
# print_r($users_array); echo "<br><br>";

if (count($members_data) != 0){
for ($i=0; $i < count($users_array); $i++){
	foreach ($members_data as $item){
		if ($users_array[$i]['uid'] == $item['uid']){
			array_splice($users_array, $i, 1);
			# break;
		}
	}
}
# print_r($users_array); echo "<br><br>";
}

# if (count($users_array) != 0){
	$template->define_dynamic("Users", "Webseite");
	foreach ($users_array as $item){
		$template->assign(array("UDN" => $item['dn'],
                              "USER" => $item['uid']));
      $template->parse("USERS_LIST", ".Users");	
	}
#}else{ 
# 	$template->assign(array("UDN" => "","USER" => ""));
# }





###############################################################################

include("roles_footer.inc.php");

?>