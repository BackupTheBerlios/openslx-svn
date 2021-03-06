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
 * searchDB.php
 *     - Read data from the LDAP database ...
 * -----------------------------------------------------------------------------
 */

session_start();

require('ldap3.inc.php');

$ds = uniLdapConnect(USER, PASS);

// to be defined accordingly
$auDN = "ou=Lehrpool1,ou=Rechenzentrum,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de";
$attributes = array("hostname", "domainname", "ipaddress", "hwaddress");


$res = get_hosts($auDN, $attributes, "");

echo "Seite fuer das Suchen in der DB...<br>";

echo "<form action='index.php?section=sendchoice' method='POST'>";

$_SESSION['hosts'] = $res;
$template  = "%s, %s, %s, %s <input type=\"checkbox\" name=\"choice[%s]\" />";
$template .= "<br/>";

foreach ($res as $key=>$entries) {
  /*  echo $entries["hostname"].", ".$entries["domainname"].", ".$entries["ipaddress"].", ".$entries["hwaddress"];
    
    echo "<input type='checkbox' name='choice[";
    echo%s $key;
    echo "]' />";
    /*echo "<input type='hidden' name='ip[".$entries["hwaddress"]."]' value=\"".$entries["ipaddress"]."\"/>";
    echo "<input type='hidden' name='host[".$entries["hwaddress"]."]' value=\"".$entries["hostname"]."\"/>";
    echo "<input type='hidden' name='dn[".$entries["hwaddress"]."]' value=\"".$entries["domainname"]."\"/>";
    echo "<br>";
*/
    echo (
        sprintf(
            $template,
            $entries["hostname"], 
            $entries["domainname"],
            $entries["ipaddress"],
            $entries["hwaddress"],
            $key
        ));
}

echo "<input type='submit' name='submit'>";
echo "</form>";

