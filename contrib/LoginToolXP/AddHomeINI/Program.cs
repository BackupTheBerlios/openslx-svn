using System;
using System.Collections.Generic;
using System.Text;

namespace AddHomeINI
{
    class Program
    {
        static void Main(string[] args)
        {
            IniFile datei;
            datei = new IniFile(@"C:\Programme\Login\AccValue.ini");

            datei.IniWriteValue("Home", "connect", "yes");
        }
    }
}
