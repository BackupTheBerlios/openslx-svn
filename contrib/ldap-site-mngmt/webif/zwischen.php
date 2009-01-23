<?php
session_cache_expire(30);
session_start();

$_SESSION['audn'] = $_GET['audn'];

#$rollen_string = $_GET['rollen'];
#$_SESSION['rollen'] = explode('_',$rollen_string);

include('lib/commonlib.inc.php');

$url = "au/au.php";
$mesg = "";
redirect(0, $url, $mesg, $addSessionId = TRUE);

?>