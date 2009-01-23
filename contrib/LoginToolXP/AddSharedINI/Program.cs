using System;
using System.Collections.Generic;
using System.Text;

namespace AddSharedINI
{
    class Program
    {
        static void Main(string[] args)
        {
            IniFile datei;
            datei = new IniFile(@"C:\Programme\Login\AccValue.ini");

            datei.IniWriteValue("Shared", "connect", "yes");
        }
    }
}
