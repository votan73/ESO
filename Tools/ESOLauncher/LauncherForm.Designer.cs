namespace ESOLauncher
{
    partial class LauncherForm
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.btnStartPTSConsole = new ESOLauncher.StartButton();
            this.btnStartPTS = new ESOLauncher.StartButton();
            this.btnStartEU = new ESOLauncher.StartButton();
            this.btnStartNA = new ESOLauncher.StartButton();
            this.SuspendLayout();
            // 
            // btnStartPTSConsole
            // 
            this.btnStartPTSConsole.Location = new System.Drawing.Point(415, 12);
            this.btnStartPTSConsole.Name = "btnStartPTSConsole";
            this.btnStartPTSConsole.Size = new System.Drawing.Size(128, 128);
            this.btnStartPTSConsole.TabIndex = 3;
            this.btnStartPTSConsole.Text = "PTC";
            this.btnStartPTSConsole.UseVisualStyleBackColor = true;
            this.btnStartPTSConsole.Click += new System.EventHandler(this.btnStartPTSConsole_Click);
            // 
            // btnStartPTS
            // 
            this.btnStartPTS.Location = new System.Drawing.Point(281, 12);
            this.btnStartPTS.Name = "btnStartPTS";
            this.btnStartPTS.Size = new System.Drawing.Size(128, 128);
            this.btnStartPTS.TabIndex = 2;
            this.btnStartPTS.Text = "PTS";
            this.btnStartPTS.UseVisualStyleBackColor = true;
            this.btnStartPTS.Click += new System.EventHandler(this.StartPTS_Click);
            // 
            // btnStartEU
            // 
            this.btnStartEU.Location = new System.Drawing.Point(146, 12);
            this.btnStartEU.Name = "btnStartEU";
            this.btnStartEU.Size = new System.Drawing.Size(128, 128);
            this.btnStartEU.TabIndex = 1;
            this.btnStartEU.Text = "EU";
            this.btnStartEU.UseVisualStyleBackColor = true;
            this.btnStartEU.Click += new System.EventHandler(this.StartEU_Click);
            // 
            // btnStartNA
            // 
            this.btnStartNA.Location = new System.Drawing.Point(12, 12);
            this.btnStartNA.Name = "btnStartNA";
            this.btnStartNA.Size = new System.Drawing.Size(128, 128);
            this.btnStartNA.TabIndex = 0;
            this.btnStartNA.Text = "NA";
            this.btnStartNA.UseVisualStyleBackColor = true;
            this.btnStartNA.Click += new System.EventHandler(this.StartNA_Click);
            // 
            // LauncherForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(96F, 96F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Dpi;
            this.AutoSize = true;
            this.AutoSizeMode = System.Windows.Forms.AutoSizeMode.GrowAndShrink;
            this.ClientSize = new System.Drawing.Size(554, 150);
            this.Controls.Add(this.btnStartPTSConsole);
            this.Controls.Add(this.btnStartPTS);
            this.Controls.Add(this.btnStartEU);
            this.Controls.Add(this.btnStartNA);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedToolWindow;
            this.Name = "LauncherForm";
            this.Padding = new System.Windows.Forms.Padding(8);
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "ESO Launcher";
            this.WindowState = System.Windows.Forms.FormWindowState.Minimized;
            this.ResumeLayout(false);

        }

        #endregion

        private StartButton btnStartNA;
        private StartButton btnStartEU;
        private StartButton btnStartPTS;
        private StartButton btnStartPTSConsole;
    }
}

