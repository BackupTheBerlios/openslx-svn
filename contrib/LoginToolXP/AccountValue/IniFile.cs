using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;


namespace AccountValue
{
    public class IniFile
    {
        public string path;

        [DllImport("kernel32")]
        private static extern long WritePrivateProfileString(string section, string key, string val, string filePath);

        [DllImport("kernel32")]
        private static extern int GetPrivateProfileString(string section, string key, string def, StringBuilder retVal, int size, string filePath);

        public IniFile(string INIPath)
        {
            path = INIPath;
        }

        public void IniWriteValue(string Section, string key, string Value)
        {
            WritePrivateProfileString(Section, key, Value, this.path);
        }

        public string IniReadValue(string Section, string key)
        {
            StringBuilder temp = new StringBuilder(255);
            int i = GetPrivateProfileString(Section, key, "", temp, 255, this.path);
            return temp.ToString();
        }
    }
}
