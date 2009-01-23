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
 * pdf.php
 *    - Defines the design of the tags (layout of ten per sheet of A4 paper
 *      with dimensions of 96mm x 50.8mm per tag). Inclusion of third party
 *      code for PDF and semacode generation, see www.fpdf.de. To be installed
 *      on the webserver.
 *  ____________________________________
 * | Organisation Logo                  |
 * |   hostname             sema        |
 * |   domainname           code        |
 * |   IP address           picture     |
 * |   MAC address                      |
 * |   additional text                  |
 * |____________________________________|
 * -----------------------------------------------------------------------------
 */

// inclusion of fpdf.php (www.fpdf.de) for the generation of the actual PDF
// files and semacode.php for rendering of the semacodes.
require('/usr/share/php/fpdf/fpdf.php');
require('semacode.php');

class pdfgen
{
    /* Klassenvariablen
    *  $_pdf: PDF-Objekt von fpdf
    *  $_width: breite einer Etikette
    *  $_height: höhe einer Etikette
    *  $_topmargin: Randabstand von oberem Rand des "DinA4-Blattes" zu den Etiketten
    *  $_leftmargin: Randabstand von linkem Rand des "DinA4-Blattes" zu den Etiketten
    *  $_position: Bestimmt ab welcher Position die Etiketten auf das pdf kommen
    *  $_pos10: die Koordinaten der linken oberen Ecken der 10 Etiketten, die auf ein
    *  Blatt kommen.
    *  $_semacode: semacode-objekt für die Generierung des Semacodes
    *  $_image: nimmt das png des semacodes auf
    */
    private $_pdf;
    private $_width;
    private $_height;
    private $_topmargin;
    private $_leftmargin;
    private $_position;
    private $_pos10 = array(array(7.7, 21.4),
                            array(106.2, 21.4),
                            array(7.7, 72.2),
                            array(106.2, 72.2),
                            array(7.7, 123),
                            array(106.2, 123),
                            array(7.7, 173.8),
                            array(106.2, 173.8),
                            array(7.7, 224.6),
                            array(106.2, 224.6)
                           );
    private $_semacode;
    private $_img;

    /* 
    *  Konstruktor: legt fpdf und semacode objekte an
    */
 
    public function __construct()
    {
        $this->_pdf = new FPDF('P','mm','A4');
        $this->_semacode = new Semacode();
    }

    /* Funktion um Semacodes zu generieren.
    *  Die jeweiligen Semacode-PNG's werden
    *  temporär in /tmp abgelegt und gelangen
    *  von dort aus ins PDF (direkt ins PDF ist
    *  nicht möglich mit fpdf)
    *  Diese temporären Bilder werden in printLabels()
    *  nach Verwendung wieder mit unlink gelöscht.
    */

    public function createSemacode($info, $name)
    {
        $_img = $this->_semacode->asGDImage($info, 120);
        header('Content-Type: image/png');
        imagepng($_img, "/tmp/$name.png");
        imagedestroy($_img);
    }

    /* Initialisieren der Etikettenmaße:
    *  Höhe, Breite und Abstände zum Rand
    */

    public function createLabels()
    {
        $this->_width = 96;
        $this->_height = 50.8;
        $this->_topmargin = 21.4;
        $this->_leftmargin = 7.7;
    }

    /* Hauptfunktion zur Generierung des PDF's
    *  Parameter:
    *  $labels: 2-dimensionales Array der Rechnerdaten
    *  $position: ab welcher position auf dem blatt gedruckt werden soll
    *  $addsize: schriftgröße des zusatztextes
    *
    *  Falls die Etiketten nicht auf ein Blatt passen, werden automatisch
    *  weitere Seiten generiert.
    */

    public function printLabels($labels, $position, $addsize)
    {
        $this->_position = $position;
        $this->_pdf->SetLeftMargin($this->_leftmargin);
        $this->_pdf->SetTopMargin($this->_topmargin);
        $this->_pdf->AddPage();
        $this->_pdf->SetFont('Arial', 'B', 14);
        
        $img = './images/rzlogo_test.jpg';
        $size = GetImageSize($img);

        $addpage = false;
        
        for ($i=0; $i<count($labels); $i++) {
            if ($addpage == true) {
                $this->_pdf->AddPage();
                $addpage = false;
            }
            $this->_pdf->SetFont('Arial', 'B', 14);
	        $this->_pdf->SetXY($this->_pos10[$this->_position][0], $this->_pos10[$this->_position][1]); 
            $this->_pdf->MultiCell($this->_width, $this->_height, '', 0);
            $this->_pdf->SetXY($this->_pos10[$this->_position][0], $this->_pos10[$this->_position][1]);
            $this->_pdf->Image($img,$this->_pos10[$this->_position][0], $this->_pos10[$this->_position][1], 50, 10);
            $this->_pdf->SetXY($this->_pos10[$this->_position][0], $this->_pos10[$this->_position][1] + 12);
            $this->_pdf->Cell(53, 6, $labels[$i][0], 0, 0, 'C');
            $this->_pdf->SetFont('Arial', '', 14);
            $this->_pdf->SetXY($this->_pos10[$this->_position][0], $this->_pos10[$this->_position][1] + 20);
            $this->_pdf->Cell(53, 6, $labels[$i][1], 0, 0, 'C');
            $this->_pdf->SetFont('Courier', 'B', 16);
            $this->_pdf->SetXY($this->_pos10[$this->_position][0], $this->_pos10[$this->_position][1] + 28);
            $this->_pdf->Cell(53, 6, $labels[$i][2], 0, 0, 'C');
            $this->_pdf->SetFont('Arial', '', 14);
            $this->_pdf->SetXY($this->_pos10[$this->_position][0], $this->_pos10[$this->_position][1] + 36);
            $this->_pdf->Cell(53, 6, $labels[$i][3], 0, 0, 'C');
            $this->_pdf->SetFont('Arial', '', $addsize);
            $this->_pdf->SetXY($this->_pos10[$this->_position][0], $this->_pos10[$this->_position][1] + 44);
            $this->_pdf->Cell(90, 6, $labels[$i][4], 0, 0, 'L');

            $this->createSemacode($labels[$i][0].$labels[$i][1].$labels[$i][2].$labels[$i][3], $i);

            $this->_pdf->Image("/tmp/$i.png", $this->_pos10[$this->_position][0] + 53, $this->_pos10[$this->_position][1] + 3, 42.33, 42.33);
            unlink("/tmp/$i.png");
            $this->_position++;
            if ($this->_position == 10) {
                $this->_position = 0;
                $addpage = true;
                $this->_pdf->SetFont('Arial', 'B', 14);
            }
        }
    }

    /*
    *  Zum Ausgeben der erzeugten PDF.
    */

    public function generatePDF()
    {
        $this->_pdf->Output();
    }
}
