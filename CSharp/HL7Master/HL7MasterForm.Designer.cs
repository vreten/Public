namespace HL7Master
{
    partial class HL7MasterForm
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
            this.chkSingleItemOnlyMode = new System.Windows.Forms.CheckBox();
            this.startButton = new System.Windows.Forms.Button();
            this.portBox = new System.Windows.Forms.TextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.groupListControl1 = new GLC.GroupListControl();
            this.SuspendLayout();
            // 
            // chkSingleItemOnlyMode
            // 
            this.chkSingleItemOnlyMode.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.chkSingleItemOnlyMode.AutoSize = true;
            this.chkSingleItemOnlyMode.Font = new System.Drawing.Font("Orange", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.chkSingleItemOnlyMode.Location = new System.Drawing.Point(351, 47);
            this.chkSingleItemOnlyMode.Name = "chkSingleItemOnlyMode";
            this.chkSingleItemOnlyMode.Size = new System.Drawing.Size(169, 23);
            this.chkSingleItemOnlyMode.TabIndex = 1;
            this.chkSingleItemOnlyMode.Text = "Expand 1 at a time";
            this.chkSingleItemOnlyMode.UseVisualStyleBackColor = true;
            this.chkSingleItemOnlyMode.CheckedChanged += new System.EventHandler(this.chkSingleItemOnlyMode_CheckedChanged);
            // 
            // startButton
            // 
            this.startButton.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.startButton.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.startButton.Location = new System.Drawing.Point(430, 12);
            this.startButton.Name = "startButton";
            this.startButton.Size = new System.Drawing.Size(89, 29);
            this.startButton.TabIndex = 2;
            this.startButton.Text = "Start";
            this.startButton.UseVisualStyleBackColor = true;
            this.startButton.Click += new System.EventHandler(this.startButton_Click);
            // 
            // portBox
            // 
            this.portBox.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.portBox.Location = new System.Drawing.Point(332, 17);
            this.portBox.Name = "portBox";
            this.portBox.Size = new System.Drawing.Size(81, 20);
            this.portBox.TabIndex = 3;
            this.portBox.Text = "13000";
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("Orange", 36F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label1.Location = new System.Drawing.Point(12, 9);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(283, 61);
            this.label1.TabIndex = 4;
            this.label1.Text = "HL7 Master";
            // 
            // groupListControl1
            // 
            this.groupListControl1.AutoScroll = true;
            this.groupListControl1.AutoSizeMode = System.Windows.Forms.AutoSizeMode.GrowAndShrink;
            this.groupListControl1.BackColor = System.Drawing.SystemColors.Control;
            this.groupListControl1.FlowDirection = System.Windows.Forms.FlowDirection.TopDown;
            this.groupListControl1.Location = new System.Drawing.Point(12, 75);
            this.groupListControl1.Name = "groupListControl1";
            this.groupListControl1.SingleItemOnlyExpansion = false;
            this.groupListControl1.Size = new System.Drawing.Size(514, 393);
            this.groupListControl1.TabIndex = 0;
            this.groupListControl1.WrapContents = false;
            // 
            // HL7MasterForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(538, 480);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.portBox);
            this.Controls.Add(this.startButton);
            this.Controls.Add(this.chkSingleItemOnlyMode);
            this.Controls.Add(this.groupListControl1);
            this.Name = "HL7MasterForm";
            this.Text = "Form1";
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private GLC.GroupListControl groupListControl1;
        private System.Windows.Forms.CheckBox chkSingleItemOnlyMode;
        private System.Windows.Forms.Button startButton;
        private System.Windows.Forms.TextBox portBox;
        private System.Windows.Forms.Label label1;
    }
}

