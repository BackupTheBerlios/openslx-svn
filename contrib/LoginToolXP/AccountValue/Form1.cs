using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using aejw.Network;
using TL.XML;
using IWshRuntimeLibrary;
using System.Runtime.InteropServices;
using System.Threading;
using System.Diagnostics;


//##############################// AccountValue Tool####################################
// Mounten von Netzlaufwerken / Verbindung mit dem Drucker / Kontoaufwertung / DiskSpace
// #####################################################################################
// (C) 2005 - 2006 Randolph Welte randy@uni-freiburg.de#################################
// 
// Bearbeitung Bohdan Dulya & Marco Haustein 2006 - 2007 ###############################


namespace AccountValue
{
    public partial class Form1 : Form
    {
        [DllImport("kernel32.dll")]
        private static extern bool GetDiskFreeSpaceEx(string directoryName,
            ref long freeBytesAvailable,
            ref long totalBytes,
            ref long totalFreeBytes);

        tlxml xml = new tlxml();
        tlxml xmlD = new tlxml();

        private DragExtender dragExtender1;
        private bool firsttime = true;
        private Form2 f2;
        
        String resolution_x = "";
        String resolution_y = "";
        
        // Wenn wahr, wird später die Auflösung umgestellt, fehlen die Parameter, dann nicht!
        private bool change_resolution = true;

        private int tempHeight = 0, tempWidth = 0;
        // private int FixHeight = 1024, FixWidth = 768;

        //#####################################################################
        //Variable, die die Umgebung beschreibt
        private String env;

        //Anzahl der Drucker in der Umgebung
        private int anz;

        //Variablen, die Optionsfelder beschreiben
        private String home;
        private String shared;
        private String printer;
        private String account;

        //#####################################################################
        public Form1()
        {
            Screen Srn = Screen.PrimaryScreen;
            tempHeight = Srn.Bounds.Width;
            tempWidth = Srn.Bounds.Height;
            
            InitializeComponent();

            // XML Settings aus Laufwerk B auslesen...
            // ################ Wichtig!! Gross schreiben!!! ##################

            try
            {
                xml.loadFile("C:\\CONFIG.XML");
            }
            catch (Exception e)
            {
                MessageBox.Show(e.Message, "Error: ", MessageBoxButtons.OK, MessageBoxIcon.Error);
                System.Environment.Exit(0);
            }

            //############## Auslesen, in welcher Umgebung man ist ############
            try
            {
                env = xml.getAttribute("/settings/eintrag/umgebung", "param");
            }
            catch { }

            try
            {
                resolution_x = xml.getAttribute("/settings/eintrag/resolution_x", "param");
                resolution_y = xml.getAttribute("/settings/eintrag/resolution_y", "param");
            }
            catch (Exception e)
            {
                change_resolution = false;
            }


            if (change_resolution)
            {
                Resolution.CResolution ChangeRes = new Resolution.CResolution(Convert.ToInt32(resolution_x), Convert.ToInt32(resolution_y));
            }
                        
            try
            {
                textBox1.AppendText(xml.getAttribute("/settings/eintrag/username", "param"));               
            }
            catch(Exception e)
            {
                MessageBox.Show(e.Message, "Error: **********************", MessageBoxButtons.OK, MessageBoxIcon.Error);
                System.Environment.Exit(0);
            }
                                      
            //resolution_x = "1680"; 
            //resolution_y = "1050";  

            try
            {
                maskedTextBox1.Focus();
            }
            catch {}
        }
        
        
        private void Form1_Load(object sender, EventArgs e)
        {
        }

        //############## Wenn der Knopf "Anmelden" angecklickt wird ###########
        private void button1_Click(object sender, EventArgs e)
        {
            login_clicked();
        }


        private void login_clicked()
        {
            //NetworkDrive oNetDrive = new NetworkDrive();
            
            //############### Parameter aus INI-Datei auslesen ################
            try
            {
                IniFile datei;
                datei = new IniFile(@"C:\Programme\Login\AccValue.ini");
                
                home = datei.IniReadValue("Home", "connect");
                shared = datei.IniReadValue("Shared", "connect");
                printer = datei.IniReadValue("Printer", "connect");
                account = datei.IniReadValue("Account", "show");
            }
            catch (Exception e)
            {
                MessageBox.Show(e.Message, "Error: ", MessageBoxButtons.OK, MessageBoxIcon.Error);
                System.Environment.Exit(0);
            }

            // Stehen überhaupt Login und Password drin?
            
            if (textBox1.Text.Equals("") || maskedTextBox1.Text.Equals(""))
            {
                try
                {
                    maskedTextBox1.Focus();
                }
                catch { }

                return;
            }

            NetworkDrive oNetDrive = new NetworkDrive();
            
            //######## Starte das script zum installieren der Drucker #########

            if (printer == "yes")
            {
                //###### Auslesen von Settings für Druckerinstallation ######
                try
                {
                    xmlD.loadFile("DEVICES.XML");
                }
                catch (Exception e)
                {
                    MessageBox.Show(e.Message, "Error: ", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    System.Environment.Exit(0);
                }


                if (env == "RZ")
                {
                    try
                    {
                        anz = Convert.ToInt32(xmlD.getAttribute("/env/RZ/printer", "param"));

                        for (int i = 1; i <= anz; i++)
                        {
                            System.Diagnostics.Process.Start("cscript", "C:\\WINDOWS\\system32\\prnmngr.vbs -ac -p \"\\\\pub-ps01.public.ads.uni-freiburg.de\\" + xmlD.getAttribute("/env/RZ/printer/printer" + Convert.ToString(i) + "/name", "param"));
                        }
                    }
                    catch (Exception err)
                    {
                        MessageBox.Show(this, "Fehler: " + err.Message, "Installieren des Druckers nicht möglich!", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
                else if (env == "UB")
                {
                    try
                    {
                        anz = Convert.ToInt32(xmlD.getAttribute("/env/UB/printer", "param"));

                        for (int i = 1; i <= anz; i++)
                        {
                            System.Diagnostics.Process.Start("cscript", "C:\\WINDOWS\\system32\\prnmngr.vbs -ac -p \"\\\\pub-ps01.public.ads.uni-freiburg.de\\" + xmlD.getAttribute("/env/UB/printer/printer" + Convert.ToString(i) + "/name", "param"));
                        }
                    }

                    catch (Exception err)
                    {
                        MessageBox.Show(this, "Fehler: " + err.Message, "Installieren des Druckers nicht möglich!", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }

                }
                else if (env == "CHEMIE")
                {
                    try
                    {
                        anz = Convert.ToInt32(xmlD.getAttribute("/env/CHEMIE/printer", "param"));

                        for (int i = 1; i <= anz; i++)
                        {
                            System.Diagnostics.Process.Start("cscript", "C:\\WINDOWS\\system32\\prnmngr.vbs -ac -p \"\\\\pub-ps01.public.ads.uni-freiburg.de\\" + xmlD.getAttribute("/env/CHEMIE/printer/printer" + Convert.ToString(i) + "/name", "param"));
                        }
                    }
                    catch (Exception err)
                    {
                        MessageBox.Show(this, "Fehler: " + err.Message, "Installieren des Druckers nicht möglich!", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
                else { }


                //#################################################################
                // Drucker verbinden...

                //NetworkDrive oNetDrive = new NetworkDrive();

                try
                {
                    oNetDrive.LocalDrive = "";
                    oNetDrive.ShareName = "\\\\pub-ps01.public.ads.uni-freiburg.de";
                    oNetDrive.MapDrive("PUBLIC\\" + textBox1.Text, maskedTextBox1.Text);

                    //Warte bis das Netz da ist
                    System.Threading.Thread.Sleep(500 * 1);
                }

                catch (Exception err)
                {
                    MessageBox.Show(this, "Fehler: " + err.Message, "Verbindung zum \"Drucker\" nicht möglich!", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    maskedTextBox1.Text = "";

                    try
                    {
                        maskedTextBox1.Focus();
                    }
                    catch { }

                    return;
                }
            }

            //#################################################################
            // Homedirectory mounten...

            if (home == "yes")
            {
                try
                {
                    oNetDrive.LocalDrive = "k:";

                    try
                    {
                        oNetDrive.UnMapDrive();
                    }
                    catch { }

                    oNetDrive.ShareName = "\\\\" + textBox1.Text + ".files.uni-freiburg.de\\" + textBox1.Text;
                    oNetDrive.MapDrive("PUBLIC\\" + textBox1.Text, maskedTextBox1.Text);
                }

                catch (Exception err)
                {
                    MessageBox.Show(this, "Fehler: " + err.Message, "Verbindung zum \"Homedirectory\" nicht möglich!", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    maskedTextBox1.Text = "";

                    try
                    {
                        maskedTextBox1.Focus();
                    }
                    catch { }

                    return;
                }



                //#################################################################

                createDesktopLinks("Homeverzeichnis K", "k:\\");
            }



            //#################################################################
            // Shared Directory mounten...
            if (shared == "yes")
            {
                try
                {
                    oNetDrive.LocalDrive = "l:";

                    try
                    {
                        oNetDrive.UnMapDrive();
                    }
                    catch { }

                    oNetDrive.ShareName = "\\\\lehrpool.files.uni-freiburg.de\\lehrpool";
                    oNetDrive.MapDrive("PUBLIC\\lehrpool", "(atom)9");
                }

                catch (Exception err)
                {
                    MessageBox.Show(this, "Fehler: " + err.Message, "Verbindung zum \"Gemeinsamen Laufwerk L\" nicht möglich!", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    maskedTextBox1.Text = "";

                    try
                    {
                        maskedTextBox1.Focus();
                    }
                    catch { }

                    return;
                }

                //#################################################################
                createDesktopLinks("Gemeinsames Laufwerk L", "l:\\");
            }

            
            //#################################################################
            // Drucker-Kontostand
            getAccountInformation();
        }


        //#####################################################################
        private void getAccountInformation()
        {
            
            if (firsttime)
            {
                String navigateTo = "https://myaccount.uni-freiburg.de/uadmin/pa?uid=" + textBox1.Text + "&pwd=" + maskedTextBox1.Text;

                webBrowser1.Navigate(navigateTo);
            }

            else
            {
                timer1.Enabled = true;
                timer2.Enabled = true;
            }
             
        }


        private void webBrowser1_DocumentCompleted(object sender, WebBrowserDocumentCompletedEventArgs e)
        {

            if (firsttime)
            {
                firsttime = false;

                this.Hide();

                f2 = new Form2(this);

                // Wohin wird die Form plaziert?           

                int x;
                int y;

                if (change_resolution)
                {
                     x = Convert.ToInt32(resolution_x);
                     y = Convert.ToInt32(resolution_y);
                }
                else
                {
                    Screen screen = Screen.PrimaryScreen;
                     x = screen.Bounds.Width;
                     y = screen.Bounds.Height;

                }



                Point location = new Point(x - f2.Size.Width, y - f2.Size.Height - 30);



                f2.DesktopLocation = location;

                if (account == "yes")
                    f2.Show();

                //Weils so schön war gleich nochmal ;-))
                getAccountInformation();

            }



            f2.label1.Text = "Benutzer: " + textBox1.Text;

            String value = webBrowser1.Document.Body.InnerText.Trim();

            if (value.IndexOf("ERROR") != -1)
                value = "ERROR";
            else
                value += "€";



            f2.label2.Text = value;

            Application.DoEvents();





        }

        private void timer1_Tick(object sender, EventArgs e)
        {

            String navigateTo = "https://myaccount.uni-freiburg.de/uadmin/pa?uid=" + textBox1.Text + "&pwd=" + maskedTextBox1.Text;

            webBrowser1.Navigate(navigateTo);
        }


        private void createDesktopLinks(String linkname, String linkpath)
        {

            // Links auf dem Desktop erstellen...

            String DesktopFolder = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);

            WshShell shell = new WshShell();

            IWshShortcut link = (IWshShortcut)shell.CreateShortcut(DesktopFolder + "\\" + linkname + ".lnk");
            link.TargetPath = linkpath;
            link.WorkingDirectory = DesktopFolder;

            link.Save();


        }


        public static DiskFreeSpace GetDiskFreeSpace(string directoryName)
        {
            DiskFreeSpace result = new DiskFreeSpace();

            if (!GetDiskFreeSpaceEx(directoryName, ref result.FreeBytesAvailable,
                ref result.TotalBytes, ref result.TotalFreeBytes))
            {
                throw new Win32Exception(Marshal.GetLastWin32Error(), "Error retrieving free disk space");
            }

            return result;
        }




        public struct DiskFreeSpace
        {
            public long FreeBytesAvailable;

            public long TotalBytes;

            public long TotalFreeBytes;
        }

        private void timer2_Tick(object sender, EventArgs e)
        {

            // Dsik Usage anzeigen...


            DiskFreeSpace used = GetDiskFreeSpace("k:\\");

            double disk_quota = Convert.ToDouble(used.TotalBytes);
            double used_bytes = Convert.ToDouble(used.TotalBytes) - Convert.ToDouble(used.TotalFreeBytes);
            double free_bytes = Convert.ToDouble(used.TotalFreeBytes);

            double percet_usage = ((100 / disk_quota) * used_bytes);

            
            
            if ((int)percet_usage < 0)
                percet_usage = 0;

            if ((int)percet_usage > 100)
                percet_usage = 100;



            f2.colorProgressBar1.Value = (int)percet_usage;

            double quota = disk_quota / 1024 / 1024;
            double usedb = used_bytes / 1024 / 1024;
            double freespace = free_bytes / 1024 / 1024;
           
  
            f2.label5.Text = "Quota: " + quota.ToString("N2") + " MBytes";
            f2.label8.Text = "Belegt: " + usedb.ToString("N2") + " MBytes";
            f2.label6.Text = "Frei: " + freespace.ToString("N2") + " MBytes";

  

            if ((int)percet_usage >= 90)
            {
                f2.label9.ForeColor = Color.Red;
                f2.colorProgressBar1.BarColor = Color.Red;
            }
            else
            {
                f2.label9.ForeColor = Color.Green;
                f2.colorProgressBar1.BarColor = Color.Green;
            }
            f2.label9.Text = ((int)percet_usage).ToString() + "%";
        }

        
    }
}