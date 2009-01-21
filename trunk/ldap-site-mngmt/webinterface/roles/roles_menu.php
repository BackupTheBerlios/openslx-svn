<?php


function createRolesMenu($rollen , $mnr, $assocdom) {
    global $template;
    global $START_PATH;
    # Struktur der Registerkartenleiste
    if ($assocdom != ""){
    $hauptmenu = array(array("link" => "roles.php",
                             "text" => "&Uuml;bersicht",
                             "zugriff" => array("MainAdmin")),
                       array("link" => "role_show.php?role=MainAdmin&mnr=1",
                             "text" => "Main Admins",
                             "zugriff" => array("MainAdmin")),
                       array("link" => "role_show.php?role=HostAdmin&mnr=2",
                             "text" => "Host Admins",
                             "zugriff" => array("MainAdmin")),
                       array("link" => "role_show.php?role=DhcpAdmin&mnr=3",
                             "text" => "DHCP Admins",
                             "zugriff" => array("MainAdmin")),
                       array("link" => "role_show.php?role=ZoneAdmin&mnr=4",
                             "text" => "DNS Admins",
                             "zugriff" => array("MainAdmin")));
	 }else{
	 $hauptmenu = array(array("link" => "roles.php",
                             "text" => "&Uuml;bersicht",
                             "zugriff" => array("MainAdmin")),
                       array("link" => "role_show.php?role=MainAdmin&mnr=1",
                             "text" => "Main Admins",
                             "zugriff" => array("MainAdmin")),
                       array("link" => "role_show.php?role=HostAdmin&mnr=2",
                             "text" => "Host Admins",
                             "zugriff" => array("MainAdmin")),
                       array("link" => "role_show.php?role=DhcpAdmin&mnr=3",
                             "text" => "DHCP Admins",
                             "zugriff" => array("MainAdmin")));	
	 }
	 # $rollen = array_keys($roles);

    # Zusammenstellen der Menuleiste
    $template->define_dynamic("Hauptmenu", "Menu");
        $i=0;
        foreach($hauptmenu as $item) {
                if($item['zugriff'] === "alle" || vergleicheArrays($rollen , $item['zugriff'])) {
                        if ($i==0) {
                                if ($mnr==0) {
                                        $zwisch="";
                                        $lastaktive=true;
                                        $farb="#505050";
                                }
                                else {
                                        $zwisch="";
                                        $farb="#A0A0A0";
                                        $lastaktive=false;
                                }
                        }
                        else {
                                if ($mnr==$i) {
                                        $zwisch="";
                                        $lastaktive=true;
                                        $farb="#505050";
                                }
                                else {
                                        $farb="#A0A0A0";
                                        if ($lastaktive) {$zwisch="";}
                                        else {$zwisch="";}
                                        $lastaktive=false;
                                } 
                        }
            $template->assign(array("ZWISCHEN" => $zwisch,
                                                                        "FARBE" => $farb,
                                                                        "LINK_M" => $item["link"],
                                                                        "TEXT_M" => $item["text"]));
            $template->parse("HAUPTMENU_LIST", ".Hauptmenu"); 

        }
                $i=$i+1;
    }
        if ($lastaktive) {$template->assign(array("ENDE" => ""));}
                else {
                        $template->assign(array("ENDE" => ""));
                }

}


?>