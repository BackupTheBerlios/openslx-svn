<?php

session_start();

include "pdf.php";

$pdfgen = new pdfgen();

$pos = $_POST["position"];
$addsize = $_POST["addsize"];
$i = 0;


foreach ($_SESSION["entries"] as $entries) {
    if (isset($_POST["hostname"])) {
        $hosts[$i][0] = $entries[0];
    }
    else {
        $hosts[$i][0] = "";
    }
    if (isset($_POST["domainname"])) {
        $hosts[$i][1] = $entries[1];
    }
    else {
        $hosts[$i][1] = "";
    }
    if (isset($_POST["ipaddress"])) {
        $hosts[$i][2] = $entries[2];
    }
    else {
        $hosts[$i][2] = "";
    }
    if (isset($_POST["hwaddress"])) {
        $hosts[$i][3] = $entries[3];
    }
    else {
        $hosts[$i][3] = "";
    }
    if (isset($_POST["additional"])) {
        $hosts[$i][4] = $_POST["addtext"];
    }
    else {
        $hosts[$i][4] = "";
    }
    

    $i++;
}

$pdfgen->createLabels();
$pdfgen->printLabels($hosts, $pos, $addsize);
$pdfgen->generatePDF();
