using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Text;
using System.Windows.Forms;
using System.Xml; //instead of TL.XML
using aejw.Network;
//using TL.XML;
using IWshRuntimeLibrary;
using System.Runtime.InteropServices;
using System.Threading;
using System.Diagnostics;


//##############################// AccountValue Tool####################################
// Mounten von Netzlaufwerken / Verbindung mit dem Drucker / Kontoaufwertung / DiskSpace
// #####################################################################################
// (C) 2005 - 2006 Randolph Welte randy@uni-freiburg.de#################################
// 
// Bearbeitung Bohdan Dulya d_bohdan@gmx.de 2006 - 2009 ################################
// & Marco Haustein 2008 ###############################################################


namespace AccountValue
{
    public partial class Form1 : Form
    {
        [DllImport("kernel32.dll")]
        private static extern bool GetDiskFreeSpaceEx(string directoryName,
            ref long freeBytesAvailable,
            ref long totalBytes,
            ref long totalFreeBytes);

        XmlDocument doc = new XmlDocument();

        //private DragExtender dragExtender1;
        private String last_stand = null;
        private bool firsttime = true;
        private bool firstclick = true;
        private Form2 f2;

        String resolution_x = "";
        String resolution_y = "";



        // Wenn wahr, wird sp�ter die Aufl�sung umgestellt, fehlen die Parameter, dann nicht!
        private bool change_resolution = false;

        private int tempHeight = 0, tempWidth = 0;
        // private int FixHeight = 1024, FixWidth = 768;

        //#####################################################################
        //Laufwerksbuchstabe
        //'Z' wird f�r das erste Laufwerk benutzt, dann f�r jedes folgende
        //Laufwerk immer um 1 dekrementiert also Y, X, usw.
        private char dl = 'Z';


        //Variablen die angeben was eingebunden werden soll
        private String home = "true";
        private String shareds = "false";
        private bool printers = false;
        private bool scanners = false;

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
                //Pr�fe ob das Laufwerk B: verbunden ist
                DirectoryInfo di = new DirectoryInfo("B:\\");
                int i = 0;
                bool disk = di.Exists;
                while (disk == false)
                {
                    System.Threading.Thread.Sleep(1000);
                    disk = di.Exists;
                    i++;
                    //if (i == 10)
                    if (i == 60)
                        break;
                }
                
                doc.Load("B:\\CONFIG.XML");
                //doc.Load("C:\\CONFIG.XML");

            }
            catch //(Exception e)
            {
                MessageBox.Show("Das Laufwerk B: oder CONFIG.XML auf dem Laufwerk B: ist nicht vorhanden!", "Fehler", MessageBoxButtons.OK, MessageBoxIcon.Error);
                System.Environment.Exit(0);
            }
                        
            try
            {
                XmlNode xnUser = doc.SelectSingleNode("/settings/eintrag/username");
                textBox1.AppendText(xnUser.Attributes["param"].InnerText); 
                //xml.getAttribute("/settings/eintrag/username", "param"));               
            }
            catch /*(Exception e)*/
            {
                MessageBox.Show(this, "Eintrag \"Benutzername\" ist in B:\\CONFIG.XML nicht vorhanden!", "Fehler: CONFIG.XML", MessageBoxButtons.OK, MessageBoxIcon.Error);
                System.Environment.Exit(0);
            }

            try
            {
                MessageBox.Show("Wenn Sie die Drucker benutzen und Daten in Ihrem Verzeichnis speichern m�chten,\nmelden Sie sich bitte im Fenster, das gleich angezeigt wird, an!", "Information!");
                maskedTextBox1.Focus();
            }
            catch { }
        }


        private void Form1_Load(object sender, EventArgs e)
        {
        }

        //############## Wenn der Knopf "Anmelden" angecklickt wird ###########
        private void button1_Click(object sender, EventArgs e)
        {
            //Verbot von doppeltem Click auf "Anmelden"
            if (firstclick)
            {
                login_clicked();
                firstclick = false;
            }
        }

        private void login_clicked()
        {
            firstclick = true;
            //NetworkDrive oNetDrive = new NetworkDrive();

            //############### Parameter aus CONFIG.XML auslesen ################
            try
            {
                XmlNode xnHome = doc.SelectSingleNode("/settings/eintrag/home");
                XmlNode xnShareds = doc.SelectSingleNode("/settings/eintrag/shareds");
                XmlNode xnPrinters = doc.SelectSingleNode("/settings/eintrag/printers");
                XmlNode xnScanners = doc.SelectSingleNode("/settings/eintrag/scanners");
                
                if (xnHome != null)
                    home = xnHome.Attributes["param"].InnerText;
                if (xnShareds != null)
                    shareds = xnShareds.Attributes["param"].InnerText;

                if (xnPrinters.FirstChild != null)
                    printers = true;
                if (xnScanners.FirstChild != null)
                    scanners = true;
                
            }
            catch (Exception e)
            {
                MessageBox.Show(e.Message, "Fehler: ", MessageBoxButtons.OK, MessageBoxIcon.Error);
                System.Environment.Exit(0);
            }

            // Stehen �berhaupt Login und Password drin?

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

            if (printers == true)
            {
                try
                {
                    XmlNode xnPrinters2 = doc.SelectSingleNode("/settings/eintrag/printers");

                    System.Diagnostics.ProcessStartInfo sendInfo;

                    foreach (XmlNode printer in xnPrinters2.ChildNodes)
                    {
                        sendInfo = new System.Diagnostics.ProcessStartInfo("cscript");
                        sendInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
                        sendInfo.Arguments = "C:\\WINDOWS\\system32\\prnmngr.vbs -ac -p " + printer.Attributes["path"].InnerText;
                        System.Diagnostics.Process.Start(sendInfo);//.WaitForExit();
                        sendInfo = null;

                        //System.Diagnostics.Process.Start("cscript", "C:\\WINDOWS\\system32\\prnmngr.vbs -ac -p " + printer.Attributes["path"].InnerText);
                    }
                }

                catch (Exception err)
                {
                    MessageBox.Show(this, "Fehler: " + err.Message, "Installieren des Druckers nicht m�glich!", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }


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

                catch
                {
                    MessageBox.Show(this, "Fehler: CONFIG.XML", "Verbindung zum \"Drucker\" nicht m�glich!", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    //maskedTextBox1.Text = "";

                    //try
                    //{
                    //    maskedTextBox1.Focus();
                    //}
                    //catch { }

                    //return;
                }
            }

            /*
             * Wenn kein Druckereintrag in CONFIG.XML vorhanden ist,
             * installiere Drucker des RZ und der UB2
             */
            else
            {
                try
                {
                    System.Diagnostics.ProcessStartInfo sendInfo;
                    sendInfo = new System.Diagnostics.ProcessStartInfo("cscript");
                    sendInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
                    sendInfo.Arguments = "C:\\WINDOWS\\system32\\prnmngr.vbs -ac -p " + "\\\\pub-ps01.public.ads.uni-freiburg.de\\rzps1";
                    System.Diagnostics.Process.Start(sendInfo);
                    sendInfo = null;

                    sendInfo = new System.Diagnostics.ProcessStartInfo("cscript");
                    sendInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
                    sendInfo.Arguments = "C:\\WINDOWS\\system32\\prnmngr.vbs -ac -p " + "\\\\pub-ps01.public.ads.uni-freiburg.de\\rzps2";
                    System.Diagnostics.Process.Start(sendInfo);
                    sendInfo = null;

                    sendInfo = new System.Diagnostics.ProcessStartInfo("cscript");
                    sendInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
                    sendInfo.Arguments = "C:\\WINDOWS\\system32\\prnmngr.vbs -ac -p " + "\\\\pub-ps01.public.ads.uni-freiburg.de\\ubps1";
                    System.Diagnostics.Process.Start(sendInfo);
                    sendInfo = null;

                    sendInfo = new System.Diagnostics.ProcessStartInfo("cscript");
                    sendInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
                    sendInfo.Arguments = "C:\\WINDOWS\\system32\\prnmngr.vbs -ac -p " + "\\\\pub-ps01.public.ads.uni-freiburg.de\\ubps2";
                    System.Diagnostics.Process.Start(sendInfo);
                    sendInfo = null;
                }

                catch
                {
                    MessageBox.Show(this, "Fehler: CONFIG.XML", "Installieren der Drucker nicht m�glich!", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }


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

                catch
                {
                    MessageBox.Show(this, "Fehler: CONFIG.XML", "Verbindung zum \"Drucker\" nicht m�glich!", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    //maskedTextBox1.Text = "";

                    //try
                    //{
                    //    maskedTextBox1.Focus();
                    //}
                    //catch { }

                    //return;
                }
            }
            //Ender der Druckerinstallation ###################################
            //#################################################################


            //#################################################################
            // Homedirectory mounten...

            if (home == "true")
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
                    MessageBox.Show(this, "Fehler: " + err.Message, "Verbindung zum \"Homedirectory\" nicht m�glich!", MessageBoxButtons.OK, MessageBoxIcon.Error);
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
            if (shareds == "true")
            {
                try
                {
                    XmlNode xnShareds2 = doc.SelectSingleNode("/settings/eintrag/shareds");

                    foreach (XmlNode shared in xnShareds2.ChildNodes)
                    {
                        oNetDrive.LocalDrive = dl + ":";

                        try
                        {
                            oNetDrive.UnMapDrive();
                        }
                        catch { }

                        oNetDrive.ShareName = shared.Attributes["path"].InnerText;
                        oNetDrive.MapDrive(shared.Attributes["name"].InnerText, shared.Attributes["pass"].InnerText);

                        createDesktopLinks("Gemeinsames Laufwerk " + dl, dl + ":\\");
                        dl = Convert.ToChar(Convert.ToInt16(dl) - 1);

                    }

                    /*
                     * Installiere auch das gemeinsame Laufwerk der Lehrpools
                     */
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
                        MessageBox.Show(this, "Fehler: " + err.Message, "Verbindung zum \"Gemeinsamen Laufwerk L\" nicht m�glich!", MessageBoxButtons.OK, MessageBoxIcon.Error);
                        maskedTextBox1.Text = "";

                        try
                        {
                            maskedTextBox1.Focus();
                        }
                        catch { }

                        return;
                    }
                    createDesktopLinks("Gemeinsames Laufwerk L", "l:\\");
                }

                catch (Exception err)
                {

                    MessageBox.Show(this, "Fehler: " + err.Message, "Verbindung zum \"Gemeinsamen Laufwerk \" nicht m�glich!", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    maskedTextBox1.Text = "";

                    try
                    {
                        maskedTextBox1.Focus();
                    }
                    catch { }

                    return;

                }

                //#################################################################
                //createDesktopLinks("Gemeinsames Laufwerk L", "l:\\");
            }
            /*
             * Bei default oder wenn in CONFIG.XML kein Eintrag shareds existiert,
             * wird standardes gemeinsames Laufwerk L verbunden
             */
            else {
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
                    MessageBox.Show(this, "Fehler: " + err.Message, "Verbindung zum \"Gemeinsamen Laufwerk L\" nicht m�glich!", MessageBoxButtons.OK, MessageBoxIcon.Error);
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

            
            //#####################################################################################
            //#### Fuege die IP-Adresse des Scanners in C:\sane\etc\sane.d\net.conf ###############

            if (scanners == true)
            {

                string path = @"c:\sane\etc\sane.d\net.conf";

                try
                {
                    using (StreamWriter sw = System.IO.File.CreateText(path)) { }
                    string path2 = path + "temp";

                    // Ensure that the target does not exist.
                    System.IO.File.Delete(path2);

                    // Copy the file.
                    System.IO.File.Copy(path, path2);

                    // Delete the newly created file.
                    System.IO.File.Delete(path2);
                }
                catch { }

                try
                {
                    XmlNode xnScanner = doc.SelectSingleNode("/settings/eintrag/scanners/scanner");
                    using (StreamWriter sw = System.IO.File.CreateText(path))
                    {
                        sw.WriteLine(xnScanner.Attributes["ip"].InnerText);
                    }
                }
                catch { }
            }
            MessageBox.Show("Bitte speichern Sie Ihre Dateien im Homeverzeichnis K: oder unter \"Eigenen Dateien\"!\nAlles, was in anderen Ordner gespeichert wird, wird nach dem Logout verschwinden!", "Wichtige Information!");
        }


        //#####################################################################
        private void getAccountInformation()
        {

            if (firsttime)
            {
                String navigateTo = "https://myaccount.uni-freiburg.de/uadmin/pa?uid=" + textBox1.Text + "&pwd=" + maskedTextBox1.Text.Replace("%", "%25");

                webBrowser1.Navigate(navigateTo);

                timer1.Enabled = true;

            }

            else
            {
                //timer1.Enabled = true;
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


                f2.Show();

                //Weils so sch�n war gleich nochmal ;-))
                getAccountInformation();

            }



            f2.label1.Text = "Benutzer: " + textBox1.Text;

            String value = webBrowser1.Document.Body.InnerText.Trim();
            
            if (value.IndexOf("ERROR") != -1)
            {
                //value = "ERROR";
                value = last_stand;
            }
            else
            {
                value += "�";
                last_stand = value;
            }
            
            /*
            if (value.IndexOf("ERROR") != -1)
                value = "ERROR";
            else
                value += "�";
            */


            f2.label2.Text = value;

            Application.DoEvents();





        }

        private void timer1_Tick(object sender, EventArgs e)
        {

            String navigateTo = "https://myaccount.uni-freiburg.de/uadmin/pa?uid=" + textBox1.Text + "&pwd=" + maskedTextBox1.Text.Replace("%", "%25");

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

            // Disk Usage anzeigen...

            if (home == "true")
            {
                try
                {
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
                catch {}
            }
            else
            {
                f2.label5.Text = "Homelaufwerk nicht eingebunden.";
            }
        }

        public static bool CheckProcessIsRun(string sProcessName){
			return (System.Diagnostics.Process.GetProcessesByName(sProcessName).Length > 0);
        }
    }
}