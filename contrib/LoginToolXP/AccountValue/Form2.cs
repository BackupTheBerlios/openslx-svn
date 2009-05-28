using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using SHDocVw;
using System.Runtime.InteropServices;
using System.Xml;




//##############################// AccountValue Tool####################################
// Mounten von Netzlaufwerken / Verbindung mit dem Drucker / Kontoaufwertung / DiskSpace
// #####################################################################################
// (C) 2005 - 2006 Randolph Welte randy@uni-freiburg.de#################################
//
// Bearbeitung Bohdan Dulya & Marco Haustein 2006 - 2009 ###############################






namespace AccountValue
{
    public partial class Form2 : Form
    {
        private DragExtender dragExtender1;
        private String version = "0.4";
        Form1 f1;
        private String home;
        XmlDocument doc = new XmlDocument();




        public Form2(Form1 form1)
        {

            f1 = form1;
            InitializeComponent();

            // Die Form beweglich machen...
            this.dragExtender1 = new DragExtender();
            this.dragExtender1.Form = this;
            // make the form draggable
            this.dragExtender1.SetDraggable(this, true);
            this.dragExtender1.SetDraggable(this.panel1, true);
            this.dragExtender1.SetDraggable(this.label1, true);
            this.dragExtender1.SetDraggable(this.label2, true);

            try
            {
                doc.Load("B:\\CONFIG.XML");
                XmlNode xnHome = doc.SelectSingleNode("/settings/eintrag/home");
                home = xnHome.Attributes["param"].InnerText;
            }
            catch { }

            if(home != "true")
            {
                pictureBox2.Visible = false;
            }


        }

        private void panel1_Paint(object sender, PaintEventArgs e)
        {

        }

        private void aboutToolStripMenuItem_Click(object sender, EventArgs e)
        {
            MessageBox.Show("© 2006 Randolph Welte \n 2007-2009 Bohdan Dulya & Marco Haustein", "About...", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        private void versionToolStripMenuItem_Click(object sender, EventArgs e)
        {
            MessageBox.Show("Version: " + version, "Version...", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        private void quitToolStripMenuItem_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }

        private void pictureBox1_Click(object sender, EventArgs e)
        {
            

            //object x = null;

            Form3 f3 = new Form3();
            f3.webBrowser1.Navigate(@"https://myaccount.ruf.uni-freiburg.de/uadmin/priacc?uid=" + f1.textBox1.Text.Trim() + "&pwd=" + f1.maskedTextBox1.Text.Trim());
            f3.Show();

        }

        private void pictureBox2_Click(object sender, EventArgs e)
        {
            object x = null;

            InternetExplorer explorer = new InternetExplorer();
            if (explorer != null)
            {
                explorer.Visible = true;

                explorer.Navigate(@"k:\",ref x,ref x,ref x,ref x);
            }


        }

        private void label3_Click(object sender, EventArgs e)
        {

        }

        private void colorProgressBar1_Click(object sender, EventArgs e)
        {

        }











    }
}