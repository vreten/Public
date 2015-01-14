using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using GLC;
using System.Runtime.InteropServices;
using System.IO;
using System.Net;
using System.Threading;
using System.Net.Sockets;
using System.Globalization;


namespace HL7Master
{
    public partial class HL7MasterForm : Form
    {
        Dictionary<string, Location> locationList = new Dictionary<string, Location>();
        Dictionary<string, Patient> patientList = new Dictionary<string, Patient>();

        Dictionary<string, patientLocationMapping> patientLocationMappingList = new Dictionary<string, patientLocationMapping>();

        GroupListControl glc;

        delegate void ProcessingCallback(string rawString);

        public void processingDelegateStructure(string rawString)
        {
            if (this.groupListControl1.InvokeRequired)
            {
                ProcessingCallback d = new ProcessingCallback(processingDelegateStructure);
                this.Invoke(d, new object[] { rawString });
            }
            else
            {
                process(rawString);
            }
        }

        long fileNumber = 0;
        int maxDataFolders = 100;
        string path;

        byte[] EOM = new byte[] { 0x1c, 0x0d };


        public HL7MasterForm()
        {
            InitializeComponent();
            setSimulatorDataFolder();
            ShowConsoleWindow();

            // Create a GLC instance:
            glc = this.groupListControl1;
            glc.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom)
                | System.Windows.Forms.AnchorStyles.Left)
                | System.Windows.Forms.AnchorStyles.Right)));
        }


        private void startButton_Click(object sender, EventArgs e)
        {

            Thread TCP_Listen_Thread;
            TCP_Listen_Thread = new Thread(TCP_Listen_Thread_Function);
            TCP_Listen_Thread.Start();
            startButton.Enabled = false;
        }


        private void TCP_Listen_Thread_Function()
        {
            TcpListener server = null;
            try
            {
                Int32 port = Convert.ToInt32(portBox.Text);

                if(!System.Net.NetworkInformation.NetworkInterface.GetIsNetworkAvailable())
                {
                    Console.WriteLine("No network available... Press any key to exit.");
                    Console.ReadKey();
                    Application.Exit();
                }

                IPAddress localAddr = IPAddress.Parse(LocalIPAddress());

                // TcpListener server = new TcpListener(port);
                server = new TcpListener(localAddr, port);

                // Start listening for client requests.
                server.Start();

                // Buffer for reading data
                byte[] raw;

                // Enter the listening loop. 
                while (true)
                {
                    Console.Write("Waiting for a connection... ");

                    // Perform a blocking call to accept requests. 
                    // You could also user server.AcceptSocket() here.
                    TcpClient client = server.AcceptTcpClient();
                    Console.WriteLine("Connected!");
                    NetworkStream stream = client.GetStream();

                    while (client.Connected)
                    {
                        try
                        {
                            // this reads exactly 1 message
                            raw = blockingEOMRead(stream, 1000, 500, 1000, EOM);

                            // Console.WriteLine("Received:\n" + DriverTools.ByteArrayToString(raw));
                            saveData(raw);

                            processingDelegateStructure(System.Text.Encoding.UTF8.GetString(raw.ToArray()));

                            sendAck(stream);
                        }
                        catch (Exception ex)
                        {
                            Console.WriteLine("Exception Detected; Closing Connection.\n" + ex.Message);
                            client.Close();

                            break;
                        }
                    }

                }
            }
            catch (SocketException ex)
            {
                Console.WriteLine("SocketException: {0}", ex);
            }
            finally
            {
                // Stop listening for new clients.
                server.Stop();
            }




        }

        public string LocalIPAddress()
        {
            IPHostEntry host;
            string localIP = "";
            host = Dns.GetHostEntry(Dns.GetHostName());
            foreach (IPAddress ip in host.AddressList)
            {
                if (ip.AddressFamily == AddressFamily.InterNetwork)
                {
                    localIP = ip.ToString();
                    break;
                }
            }
            return localIP;
        }



        private void process(string rawString)
        {
            Patient pat = new Patient("blank");
            Location loc;
            patientLocationMapping PLM = new patientLocationMapping();
            ListGroup lg = new ListGroup();

            string MSHTimeString = "";
            DateTime MSHTime;
            string ParmTimeString = "";
            DateTime ParmTime;

            int parmIndex;

            string receiveTimeString = DateTime.Now.ToString("h:m:s t");

            string[] segments = rawString.Replace("" + (char)11, "").Split(new string[] { "\r" }, StringSplitOptions.None);

            Console.WriteLine(segments.Count() + " Segments:");

            foreach (string segment in segments)
            {
                string[] fields = segment.Split(new string[] { "|" }, StringSplitOptions.None);

                switch (fields[0])
                {
                    case "MSH":
                        try
                        {
                            MSHTimeString = fields[6];
                            MSHTime = DateTime.ParseExact(MSHTimeString, "yyyyMMddHHmmss", CultureInfo.CurrentCulture);
                            MSHTimeString = MSHTime.ToString("h:m:s t");
                        }
                        catch (Exception ex)
                        {
                            Console.WriteLine("Error parsing msg time: " + ex.Message);
                            MSHTimeString = "no_time";
                        }
                        break;
                    case "PID":
                        pat = getPatientFromPIDFields(fields);
                        break;
                    case "PV1":
                        loc = getLocationFromPV1Fields(fields);

                        PLM = getPatientLocationMapping(pat, loc);

                        lg = getListGroup(PLM);

                        // Add column for the result
                        lg.Columns.Add(receiveTimeString + " (" + MSHTimeString + ")");

                        lg.Columns[lg.Columns.Count - 1].Width = 135;

                        break;
                    case "OBX":

                        ListViewItem parmValueItem;
                        // ListViewItem parmTimeItem;

                        string[] parameter_subfields = fields[3].Split(new string[] { "^" }, StringSplitOptions.None);
                        string parameter_name = parameter_subfields[0];

                        parameter_subfields = fields[6].Split(new string[] { "^" }, StringSplitOptions.None);
                        string parameter_uom = parameter_subfields[0];

                        string ParameterID = parameter_name + " in " + parameter_uom;

                        if (!PLM.parameters.ContainsKey(ParameterID))
                        {
                            PLM.parameters.Add(ParameterID, new Parameter(PLM.parameters.Count(), ParameterID, 1));
                            Console.WriteLine("New Parameter = " + ParameterID);

                            parmIndex = PLM.parameters.Count() - 1;
                            // itemIndex = parmIndex * 2;

                            parmValueItem = lg.Items.Insert(parmIndex, ParameterID);
                            // parmTimeItem = lg.Items.Insert(parmIndex + 1, new ListViewItem("Timestamps"));
                        }
                        else
                        {
                            Console.WriteLine("Existing Parameter = " + ParameterID);

                            parmIndex = PLM.parameters[ParameterID].index;
                            // itemIndex = parmIndex * 2;

                            parmValueItem = lg.Items[parmIndex];

                            // parmTimeItem = lg.Items[itemIndex + 1];
                        }


                        string parameter_value = fields[5];

                        

                        try
                        {
                            ParmTimeString = fields[14];
                            ParmTime = DateTime.ParseExact(ParmTimeString, "yyyyMMddHHmmss", CultureInfo.CurrentCulture);
                            ParmTimeString = ParmTime.ToString("h:m:s t");
                        }
                        catch (Exception ex)
                        {
                            Console.WriteLine("Error parsing parameter time: " + ex.Message);
                            ParmTimeString = "no_time";
                        }


                        parmValueItem.SubItems.Add(parameter_value + "\t(" + ParmTimeString + ")");

                        // parmTimeItem.SubItems.Add(parameter_time);

                        break;
                    default:

                        break;
                }

            }

        }

        public Patient getPatientFromPIDFields(string[] fields)
        {
            string[] name_subfields = fields[5].Split(new string[] { "^" }, StringSplitOptions.None);
            string key = name_subfields[1] + " " + name_subfields[0];

            Patient pat;

            if (!patientList.TryGetValue(key, out pat))
            {
                patientList.Add(key, new Patient(key));
                patientList[key].messageCount++;
                Console.WriteLine("New Patient name = " + key);
                return patientList[key];
            }
            else
            {
                Console.WriteLine("Existing Patient = " + key);
                pat.messageCount++;
                return pat;
            }
        }

        private Location getLocationFromPV1Fields(string[] fields)
        {
            string[] subfields = fields[3].Split(new string[] { "^" }, StringSplitOptions.None);

            string unit = subfields[0];
            string room = subfields[1];
            string bed = subfields[2];
            string facility = subfields[3];

            string loc_ID = facility + "_" + unit + "_" + room + "_" + bed;

            Location loc;

            if (!locationList.TryGetValue(loc_ID, out loc))
            {
                locationList.Add(loc_ID, new Location(loc_ID));
                Console.WriteLine("New Location name = " + loc_ID);
                return locationList[loc_ID];
            }
            else
            {
                Console.WriteLine("Existing Location = " + loc_ID);
                return loc;
            }

        }

        private patientLocationMapping getPatientLocationMapping(Patient pat, Location loc)
        {
            patientLocationMapping PLM;

            string ID = pat.ID + " - " + loc.ID;

            if (!patientLocationMappingList.TryGetValue(ID, out PLM))
            {
                patientLocationMappingList.Add(ID, new patientLocationMapping(pat, loc));
                patientLocationMappingList[ID].messageCount++;
                Console.WriteLine("New Patient - Location Mapping = " + ID);
                return patientLocationMappingList[ID];
            }
            else
            {
                Console.WriteLine("Existing Patient - Location Mapping = " + ID);
                PLM.messageCount++;
                return PLM;
            }
        }

        private ListGroup getListGroup(patientLocationMapping PLM)
        {
            ListGroup lg;

            if (!(glc.Controls).ContainsKey(PLM.ID))
            {
                lg = new ListGroup();
                lg.Name = PLM.ID;
                lg.Columns.Add(PLM.ID);
                lg.Columns[lg.Columns.Count - 1].Width = 170;


                // Add handling for the columnRightClick Event:
                lg.MouseClick += new MouseEventHandler(lg_MouseClick);

                glc.Controls.Add(lg);

                return lg;
            }
            else
            {
                return (ListGroup)glc.Controls[PLM.ID];

                //((ListGroup)glc.Controls[key]).Columns[1].Text = "Results(" + ++patientList[key].messageCount + ")";
                //((ListGroup)glc.Controls[key]).Columns[2].Text = "Latest Received: (" + receiveTimeString + ")";
                //if (patientList[key].messageCount % 2 == 0)
                //    rowColor = Color.SkyBlue;
                //else
                //    rowColor = Color.White;
            }
        }

        private void sendAck(NetworkStream stream)
        {
            byte[] ackMsg = System.Text.Encoding.UTF8.GetBytes(
                                    "\x0BMSH|^~\\&|||EPIC|EPICADT|" +
                                    DateTime.Now.Ticks + "||ACK||D|2.5\r" +
                                    "MSA|AA|\x1C\x0D");

            saveData(ackMsg);

            stream.Write(ackMsg, 0, ackMsg.Length);
            // Console.WriteLine("Sent:\n" + DriverTools.ByteArrayToString(ackMsg));

        }


        public byte[] blockingEOMRead(NetworkStream stream,
                                        int initialTimeout,
                                        int latencyTmeout,
                                        int roughSize,
                                        byte[] EOM)
        {
            byte[] receivedBytes = new byte[roughSize];
            int bytesRead;

            stream.ReadTimeout = initialTimeout;
            for (bytesRead = 0; Tool.IndexOf(receivedBytes, EOM) == -1; bytesRead++)
            {
                receivedBytes[bytesRead] = (byte)stream.ReadByte();
                if (receivedBytes[bytesRead] == 0xff)
                {
                    receivedBytes[bytesRead] = 0;
                    break;
                }
                stream.ReadTimeout = latencyTmeout;
                if (bytesRead == roughSize - 1)
                    receivedBytes = Tool.changeArraySize(receivedBytes, roughSize *= 2);
            }
            return Tool.changeArraySize(receivedBytes, bytesRead);
        }


        private void setSimulatorDataFolder()
        {
            try
            {
                int i;
                for (i = 0; i < maxDataFolders; i++)
                {
                    path = @"C:\HL7_Logs\" + i + "\\";
                    if (!Directory.Exists(path)) break;
                }
                if (i == maxDataFolders)
                {
                    Console.WriteLine("Data folder count exceeded");
                }
                else
                {
                    Directory.CreateDirectory(path);
                }

            }
            catch (Exception ex)
            {
                Console.WriteLine("Error with simulator data folder: " + ex.Message);
            }
        }


        public void saveData(byte[] data)
        {
            string filename = fileNumber.ToString() + "."
                + DateTime.UtcNow.Ticks.ToString() + ".hex";

            Tool.ByteArrayToFile(path + "\\" + filename, data);
            fileNumber++;
        }

        void lg_MouseClick(object sender, MouseEventArgs e)
        {
            ListGroup lg = (ListGroup)sender;
            ListViewHitTestInfo info = lg.HitTest(e.X, e.Y);
            ListViewItem item = info.Item;
        }

        // Determine whether or not to use SingleItemOnly Expansion:
        private void chkSingleItemOnlyMode_CheckedChanged(object sender, EventArgs e)
        {
            this.groupListControl1.SingleItemOnlyExpansion = this.chkSingleItemOnlyMode.Checked;
            if (this.groupListControl1.SingleItemOnlyExpansion)
            {
                this.groupListControl1.CollapseAll();
            }
            else
            {
                this.groupListControl1.ExpandAll();
            }
        }

        #region Console Display

        const int SW_HIDE = 0;
        const int SW_SHOW = 5;

        public static void ShowConsoleWindow()
        {
            var handle = GetConsoleWindow();

            if (handle == IntPtr.Zero)
            {
                AllocConsole();
            }
            else
            {
                ShowWindow(handle, SW_SHOW);
            }

            Console.ForegroundColor = ConsoleColor.Green;
            Console.WindowWidth = 100;
            Console.SetBufferSize(400, 2000);
            Console.WriteLine("Works");
        }

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool AllocConsole();

        [DllImport("kernel32.dll")]
        static extern IntPtr GetConsoleWindow();

        [DllImport("user32.dll")]
        static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        public static void HideConsoleWindow()
        {
            var handle = GetConsoleWindow();

            ShowWindow(handle, SW_HIDE);
        }

        #endregion Console Display


    }

    public class Patient
    {
        public string ID;
        public int messageCount = 0;

        public Patient(string id)
        {
            ID = id;
        }
    }

    public class Location
    {
        public string ID;

        public Location(string id)
        {
            ID = id;
        }
    }

    public class Parameter
    {
        public int index;
        public string name;
        public int count;

        public Parameter(int i, string n, int c)
        {
            index = i;
            name = n;
            count = c;
        }

    }

    public class patientLocationMapping
    {
        public string ID;
        public Patient patient;
        public Location location;
        public Dictionary<string, Parameter> parameters = new Dictionary<string, Parameter>();

        public int messageCount = 0;
        public List<HL7_Message> hl7MessageList = new List<HL7_Message>();

        public patientLocationMapping(Patient pat, Location loc)
        {
            patient = pat;
            location = loc;
            ID = pat.ID + " - " + loc.ID;
        }

        public patientLocationMapping()
        {
        }
    }

    public class HL7_Message
    {
        public string text;

    }

    public class Tool
    {


        public static byte[] Combine(params byte[][] arrays)
        {
            int length_of_all_arrays = 0;

            foreach (byte[] array in arrays)
                length_of_all_arrays += array.Length;

            byte[] rv = new byte[length_of_all_arrays];
            int offset = 0;
            foreach (byte[] array in arrays)
            {
                System.Buffer.BlockCopy(array, 0, rv, offset, array.Length);
                offset += array.Length;
            }
            return rv;
        }

        public static byte[] StringToByteArray(string str)
        {
            UTF8Encoding encoding = new UTF8Encoding();
            return encoding.GetBytes(str);
        }

        public static string ByteArrayToString(byte[] input)
        {
            UTF8Encoding enc = new UTF8Encoding();
            string str = enc.GetString(input);
            return str.Replace("\r", "\\r").Replace("\n", "\\n");
        }

        public static byte[] GetBytes(string str)
        {
            byte[] bytes = new byte[str.Length * sizeof(char)];
            System.Buffer.BlockCopy(str.ToCharArray(), 0, bytes, 0, bytes.Length);
            return bytes;
        }

        public static bool ByteArrayToFile(string _FileName, byte[] _ByteArray)
        {
            try
            {
                // Open file for reading
                System.IO.FileStream _FileStream =
                   new System.IO.FileStream(_FileName, System.IO.FileMode.Create,
                                            System.IO.FileAccess.Write);
                // Writes a block of bytes to this stream using data from
                // a byte array.
                _FileStream.Write(_ByteArray, 0, _ByteArray.Length);

                // close file stream
                _FileStream.Close();

                return true;
            }
            catch (Exception _Exception)
            {
                // Error
                Console.WriteLine("Exception caught in process: {0}",
                                  _Exception.ToString());
            }

            // error occured, return false
            return false;
        }

        public static byte CalculateCheckSum(byte[] byteArray)
        {
            int sum = 0;
            foreach (byte b in byteArray)
                sum += b;

            return (byte)sum;
        }

        public static byte[] SubArray(byte[] data, int index, int length)
        {
            byte[] result = new byte[length];
            Array.Copy(data, index, result, 0, length);
            return result;
        }

        public static byte[] expand(byte[] buffer, int currentSize, int desiredSize)
        {
            // Logger.info("Expanding buffer from " + currentSize + " to " + desiredSize); 
            byte[] tmp = new byte[desiredSize];
            Buffer.BlockCopy(buffer, 0, tmp, 0, currentSize);
            buffer = null;
            return tmp;
        }

        /// <summary>
        /// Finds whether and where a byte[] pattern exists in a larger byte[]
        /// </summary>
        /// <param name="arrayToSearchThrough">Larger array</param>
        /// <param name="patternToFind">Small pattern array</param>
        /// <returns>Index of pattern, or -1 if pattern not found</returns>
        public static int IndexOf(byte[] arrayToSearchThrough, byte[] patternToFind)
        {
            if (patternToFind.Length > arrayToSearchThrough.Length)
                return -1;
            for (int i = 0; i < arrayToSearchThrough.Length - patternToFind.Length; i++)
            {
                bool found = true;
                for (int j = 0; j < patternToFind.Length; j++)
                {
                    if (arrayToSearchThrough[i + j] != patternToFind[j])
                    {
                        found = false;
                        break;
                    }
                }
                if (found)
                {
                    return i;
                }
            }
            return -1;
        }

        public static byte[] changeArraySize(byte[] oldArray, int newSize)
        {
            byte[] tmp;

            if (newSize > oldArray.Count())
            {
                tmp = new byte[newSize];
                // Logger.debug("Expanding buffer from " + oldArray.Count() + " to " + newSize);
                Buffer.BlockCopy(oldArray, 0, tmp, 0, oldArray.Count());
            }
            else if (newSize < oldArray.Count())
            {
                // Trim Trailing Zeros
                while (--newSize > 0 && oldArray[newSize] == 0) ;
                tmp = new byte[++newSize];

                // Logger.debug("Reducing buffer from " + oldArray.Count() + " to " + newSize);
                Buffer.BlockCopy(oldArray, 0, tmp, 0, newSize);
            }
            else
            {
                // Logger.debug("Buffer is already " + newSize);
                tmp = null;
                return oldArray;
            }
            oldArray = null;
            return tmp;
        }


        public static List<List<byte>> splitByteArray(List<byte> byteList, List<List<byte>> delimeterList)
        {
            List<List<byte>> result = new List<List<byte>>();

            int i, j, k;

            int lastDelimeterIndex = 0;

            try
            {

                // for each byte in byteList
                for (i = 0; i < byteList.Count; i++)
                {
                    // for each delimeter in delimeterList
                    for (j = 0; j < delimeterList.Count; j++)
                    {
                        if (delimeterList[j].Count > byteList.Count - i) continue;

                        // for each byte in current delimeter in delimeterList
                        for (k = 0; k < delimeterList[j].Count; k++)
                        {
                            if (delimeterList[j][k] != byteList[i + k]) break;
                        }

                        if (k == delimeterList[j].Count)
                        {
                            result.Add(byteList.GetRange(lastDelimeterIndex, i - lastDelimeterIndex));
                            i += k;
                            lastDelimeterIndex = i;
                            break;
                        }
                    }
                    if (i >= byteList.Count) break;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error in splitByteArray: " + ex.Message);
            }
            return result;
        }


        public static byte[] trimTrailingZeros(byte[] packet)
        {
            var i = packet.Length - 1;
            while (packet[i] == 0)
            {
                --i;
            }
            var temp = new byte[i + 1];
            Array.Copy(packet, temp, i + 1);
            packet = null;
            return temp;
        }


    }

}
