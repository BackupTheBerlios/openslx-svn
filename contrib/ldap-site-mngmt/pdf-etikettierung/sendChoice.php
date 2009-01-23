<?php
session_start();

echo "<pre>";
var_dump($_SESSION['hosts']);
echo "</pre>";

echo "<pre>";
var_dump($_POST["choice"]);
var_dump($_POST["ip"]);
var_dump($_POST["host"]);
echo "</pre>";

foreach ($_POST["choice"] as $key=>$val) {
    if( $val == "on" ) {
        echo $_SESSION['hosts'][$key]['hostname']."<br>";
        $tmp = explode('_', $_SESSION['hosts'][$key]['ipaddress']);
        //if ($tmp[0] != $tmp[1])
            //do something...
        $_SESSION['entries'][] = array($_SESSION['hosts'][$key]['hostname'], $_SESSION['hosts'][$key]['domainname'],
        $tmp[0], $_SESSION['hosts'][$key]['hwaddress']);  
    }
}

echo "<pre>";
echo "</pre>";
