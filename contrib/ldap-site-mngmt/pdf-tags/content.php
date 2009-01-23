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
 * content.php
 *     - Dynamically generated content/part of the webpage displayed to the user
 * -----------------------------------------------------------------------------
 */

session_start();

switch ($_GET['section'])
{
    case "searchDB": include "searchDB.php"; break;
    case "sendchoice": include "sendChoice.php"; break;
    case "printPreview": include "printPreview.php"; break;
    case "generatePDF": include "generatePDF.php"; break;
    default: include "home.php"; break;
}
