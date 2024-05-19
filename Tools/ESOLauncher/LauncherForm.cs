using System;
using System.Collections.Generic;
using System.Drawing;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace ESOLauncher
{
    public partial class LauncherForm : Form
    {
        public LauncherForm()
        {
            InitializeComponent();
        }
        static Font font;
        System.IO.FileInfo fileLive;
        System.IO.FileInfo filePTS;

        protected override void CreateHandle()
        {
            font = font ?? new Font(Font.FontFamily, 36);
            btnStartPTS.Font = btnStartEU.Font = btnStartNA.Font = font;

            Icon = Program.Icon;

            base.CreateHandle();
        }
        protected override void OnLoad(EventArgs e)
        {
            fileLive = new System.IO.FileInfo(@"..\The Elder Scrolls Online\game\client\eso64.exe");
            filePTS = new System.IO.FileInfo(@"..\The Elder Scrolls Online PTS\game\client\eso64.exe");

            base.OnLoad(e);
        }
        protected override void OnShown(EventArgs e)
        {
            btnStartNA.Enabled = btnStartEU.Enabled = fileLive.Exists;
            btnStartPTS.Enabled = filePTS.Exists;

            base.OnShown(e);
        }
        private static void UpdateSettings(bool isPTS, bool isEU)
        {
            if (isPTS)
                return;

            var settingsFile = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "Elder Scrolls Online", "live", "UserSettings.txt");
            if (!System.IO.File.Exists(settingsFile))
                return;
            var lines = new List<string>(System.IO.File.ReadAllLines(settingsFile));
            var plattform = "SET LastPlatform " + (isEU ? "\"Live-EU\"" : "\"Live\"");
            var realm = "SET LastRealm " + (isEU ? "\"EU Megaserver\"" : "\"NA Megaserver\"");
            for (int i = 0; i < lines.Count; i++)
            {
                var line = lines[i];
                if (line.StartsWith("SET LastRealm ", StringComparison.OrdinalIgnoreCase))
                {
                    lines[i] = realm;
                }
                else if (line.StartsWith("SET LastPlatform ", StringComparison.OrdinalIgnoreCase))
                {
                    lines[i] = plattform;
                }
            }
            System.IO.File.WriteAllLines(settingsFile, lines.ToArray());
        }

        private static string GetLastPlatform()
        {
            var settingsFile = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "Elder Scrolls Online", "live", "UserSettings.txt");
            if (!System.IO.File.Exists(settingsFile))
                return "";
            var lines = new List<string>(System.IO.File.ReadAllLines(settingsFile));
            for (int i = 0; i < lines.Count; i++)
            {
                var line = lines[i];
                if (line.StartsWith("SET LastPlatform ", StringComparison.OrdinalIgnoreCase))
                {
                    return line.Substring(17).Trim().Trim('\"').ToLower();
                }
            }
            return "";
        }

        private void Launch(object sender, System.IO.FileInfo file)
        {
            var btn = sender as StartButton;
            btn.Enabled = false;
            Task.Factory.StartNew(() =>
            {
                var info = new System.Diagnostics.ProcessStartInfo(file.FullName);
                info.WorkingDirectory = file.Directory.FullName;
                info.UseShellExecute = false;
                info.WindowStyle = System.Diagnostics.ProcessWindowStyle.Minimized;
                var p = System.Diagnostics.Process.Start(info);
                p.PriorityBoostEnabled = true;
                p.PriorityClass = System.Diagnostics.ProcessPriorityClass.High;
                p.WaitForExit();

                if (!IsHandleCreated)
                    return;

                string lastPlatform = GetLastPlatform();

                MethodInvoker exited = () =>
                {
                    btn.Enabled = file.Exists;
                };
                BeginInvoke(exited);
            });
        }

        private void StartNA_Click(object sender, EventArgs e)
        {
            UpdateSettings(false, false);
            Launch(sender, fileLive);
        }

        private void StartEU_Click(object sender, EventArgs e)
        {
            UpdateSettings(false, true);
            Launch(sender, fileLive);
        }
        private void StartPTS_Click(object sender, EventArgs e)
        {
            UpdateSettings(true, false);
            Launch(sender, filePTS);
        }
    }
}
