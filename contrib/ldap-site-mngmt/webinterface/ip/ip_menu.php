<?php

function createIPMenu($rollen , $mnr) {
    global $template;
    global $START_PATH;
    global $auDN;
    
    $mipb_array = get_maxipblocks_au($auDN);
    #print_r($mipb_array);
    if ( $mipb_array[0] == "" ){
       $iprechnerlink = "no_ip.php?mnr=1";
       $ipdhcplink = "no_ip.php?mnr=2";
       $ipdeleglink = "no_ip.php?mnr=3";
    }else{
       $iprechnerlink = "ip_rechner.php";
       $ipdhcplink = "ip_dhcp.php";
       $ipdeleglink = "ip_deleg.php";
    }
    # Struktur der Registerkartenleiste
    $hauptmenu = array(array("link" => "ip.php",
                             "text" => "&Uuml;bersicht",
                             "zugriff" => "alle"),
    						  array("link" => $iprechnerlink,
                             "text" => "IP Adressen Rechner",
                             "zugriff" => array("MainAdmin","DhcpAdmin","HostAdmin")),
                       #array("link" => $ipdhcplink,
                       #      "text" => "IP Adressen DHCP",
                       #      "zugriff" => array("MainAdmin","HostAdmin","DhcpAdmin")),
                       array("link" => $ipdeleglink,
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