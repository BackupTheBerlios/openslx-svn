<?php
/**
 * -----------------------------------------------------------------------------
 * Copyright (c) 2008 - Rechenzentrum Uni FR, OpenSLX Project
 *
 * This program is free software distributed under the GPL version 2.
 * See http://openslx.org/COPYING
 *
 * If you have any feedback please consult http://openslx.org/feedback and
 * send your suggestions, praise, or complaints to feedback@openslx.org
 *
 * General information about OpenSLX can be found at http://openslx.org/
 * -----------------------------------------------------------------------------
 * sendChoice.php
 *    -
 * -----------------------------------------------------------------------------
 */
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
