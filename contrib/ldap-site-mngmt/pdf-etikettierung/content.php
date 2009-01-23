<?php
session_start();

switch ($_GET['section'])
{
    case "searchDB": include "searchDB.php"; break;
    case "sendchoice": include "sendChoice.php"; break;
    case "printPreview": include "printPreview.php"; break;
    case "generatePDF": include "generatePDF.php"; break;
    default: include "home.php"; break;
}
