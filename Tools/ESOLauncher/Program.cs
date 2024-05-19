using System;
using System.Drawing;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace ESOLauncher
{
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static void Main()
        {
            var field = typeof(Form).GetField("defaultIcon", BindingFlags.GetField | BindingFlags.NonPublic | BindingFlags.Static);
            if (field != null)
            {
                var a = typeof(Program).Assembly;
                Icon = new Icon(a.GetManifestResourceStream(a.GetName().Name + ".ESO.ico"));
                field.SetValue(null, Icon);
            }

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new LauncherForm());

        }
        public static System.Drawing.Icon Icon;
    }
}
