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
            this.btnStartNA = new System.Windows.Forms.Button();
            this.btnStartEU = new System.Windows.Forms.Button();
            this.btnStartPTS = new System.Windows.Forms.Button();
            this.SuspendLayout();
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
            // LauncherForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(96F, 96F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Dpi;
            this.ClientSize = new System.Drawing.Size(421, 150);
            this.Controls.Add(this.btnStartPTS);
            this.Controls.Add(this.btnStartEU);
            this.Controls.Add(this.btnStartNA);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedToolWindow;
            this.Name = "LauncherForm";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "ESO Launcher";
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Button btnStartNA;
        private System.Windows.Forms.Button btnStartEU;
        private System.Windows.Forms.Button btnStartPTS;
    }
}

