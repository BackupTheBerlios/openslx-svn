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
 * index.php
 *    - Generic part of the tag interface webpage displayed to the user
 * -----------------------------------------------------------------------------
 */

session_start();
$_SESSION["entries"];
?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de">
 <head>
  <title>Inventory Tags for the LDAP Site Management</title>
  <link rel="stylesheet" type="text/css" href="style.css">
 </head>
 <body>
  <div id="container">
   <div id="header"></div>
   <div id="line"></div>
   <div id="menu">
    <ul>
     <li><a href="index.php?section=searchDB">search DB</a></li>
     <li><a href="index.php?section=printPreview">printPreview</a></li>
    </ul>
   </div>
   <div id="content">
<?php
include "content.php";
?>
   </div>
  </div>
 </body>
</html>
