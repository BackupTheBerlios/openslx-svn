<?php

function createIPMenu($rollen , $mnr) {
    global $template;
    global $START_PATH;
    # Struktur der Registerkartenleiste
    $hauptmenu = array(array("link" => "ip.php",
                             "text" => "&Uuml;bersicht",
                             "zugriff" => "alle"),
    						  array("link" => "ip_rechner.php",
                             "text" => "IP Adressen Rechner",
                             "zugriff" => array("MainAdmin","HostAdmin")),
                       array("link" => "ip_dhcp.php",
                             "text" => "IP Adressen DHCP",
                             "zugriff" => array("MainAdmin","HostAdmin","DhcpAdmin")),
                       array("link" => "ip_deleg.php",
                             "text" => "Delegierte IP Bereiche",
                             "zugriff" => array("MainAdmin")));
	 
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