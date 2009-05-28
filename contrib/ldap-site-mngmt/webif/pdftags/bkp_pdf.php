<?php

require('/usr/share/php/fpdf/fpdf.php');
require('semacode.php');

class pdfgen
{
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
	private $_info;
	private $_img;
	private $_add;

    public function __construct()
    {
        $this->_pdf = new FPDF('P','mm','A4');
        $this->_semacode = new Semacode();
    }

    public function createSemacode($info, $name)
    {
        $_img = $this->_semacode->asGDImage($info, 120);
        header('Content-Type: image/png');
        imagepng($_img, "/tmp/$name.png");
        imagedestroy($_img);
    }

    public function createLabels()
    {
        $this->_width = 96;
        $this->_height = 50.8;
        $this->_topmargin = 21.4;
        $this->_leftmargin = 7.7;
    }

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
            $this->_pdf->Cell(53, 6, $labels[$i][4], 0, 0, 'C');

            $this->createSemacode($labels[$i][0].$labels[$i][1].$labels[$i][2].$labels[$i][3], $i);

            $this->_pdf->Image("/tmp/$i.png", $this->_pos10[$this->_position][0] + 53, $this->_pos10[$this->_position][1] + 3.6, 42.33, 42.33);
            unlink("/tmp/$i.png");
            $this->_position++;
            if ($this->_position == 10) {
                $this->_position = 0;
                $addpage = true;
                //$this->_pdf->AddPage();
                $this->_pdf->SetFont('Arial', 'B', 14);
            }
        }
    }

    public function generatePDF()
    {
        $this->_pdf->Output();
    }
}
