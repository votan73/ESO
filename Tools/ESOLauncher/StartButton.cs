using System;
using System.ComponentModel;
using System.Drawing;

namespace ESOLauncher
{
    internal class StartButton : System.Windows.Forms.Button
    {
        public StartButton() : base()
        {
            CooldownLabel = new Cooldownlabel();
            CooldownLabel.TextAlign = ContentAlignment.MiddleCenter;
            CooldownLabel.Visible = false;
            Controls.Add(CooldownLabel);
            CooldownLabel.SetBounds(8, ClientSize.Height - 8 - CooldownLabel.Height, Width - 16, 0, System.Windows.Forms.BoundsSpecified.Width | System.Windows.Forms.BoundsSpecified.Location);
            CooldownLabel.Anchor = System.Windows.Forms.AnchorStyles.Left | System.Windows.Forms.AnchorStyles.Right | System.Windows.Forms.AnchorStyles.Bottom;
            CooldownLabel.AutoSize = false;
        }

        [DesignerSerializationVisibility(DesignerSerializationVisibility.Content)]
        public Cooldownlabel CooldownLabel { get; private set; }

        public StartButton DependingButton { get; set; }

        [DesignerSerializationVisibility(DesignerSerializationVisibility.Hidden), Browsable(false)]
        public DateTime Cooldown { get; set; }

        public void UpdateCooldown()
        {
            if (Cooldown <= DateTime.Now)
            {
                if (CooldownLabel.Text != String.Empty)
                {
                    CooldownLabel.Text = String.Empty;
                    CooldownLabel.Visible = false;
                }
                if (Cooldown > DateTime.MinValue)
                    Enabled = true;
            }
            else
            {
                CooldownLabel.Text = Cooldown.Subtract(DateTime.Now).ToString(@"mm\:ss");
                CooldownLabel.Visible = true;
            }
        }

        public class Cooldownlabel : System.Windows.Forms.Label
        {

            [DesignerSerializationVisibility(DesignerSerializationVisibility.Hidden)]
            public override Color BackColor { get => Color.Transparent; set => base.BackColor = Color.Transparent; }
        }
    }
}
