using Advanced.Delegates.Tests;
using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.Entity.Validation;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace ADTEntityFramework
{
    //	
    //	  ____ _       _           _ 
    //	 / ___| | ___ | |__   __ _| |
    //	| |  _| |/ _ \| '_ \ / _` | |
    //	| |_| | | (_) | |_) | (_| | |
    //	 \____|_|\___/|_.__/ \__,_|_|
    //	
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public class Global
    {
        public static int TCP_PORT = 2015;
        public static byte[] EOM = new byte[] { 0x1c, 0x0d };

        public static bool DeleteDischargedPatients = false;   // TODO: code this

        public static bool CreateLocations = true;
        public static bool Process_A01 = true;
        public static bool Process_A02 = true;
        public static bool Process_A03 = true;
        public static bool Process_A06 = true;
        public static bool Process_A07 = true;
        public static bool Process_A08 = false;
        public static bool Process_A11 = false;
        public static bool Process_A12 = false;
        public static bool Process_A13 = false;


        // Enabled: Concat --(counter) to duplicate message ID's
        // Disabled: Ignore messages with duplicate message ID's
        public static bool AllowDuplicateMessageIDs = true;

        // Log every received and sent message
        public static bool LogAllMessages = false;

        public static bool LogErrors = true;
        public static bool LogWarnings = true;
        public static bool logInfo = true;
        public static bool logDebug = false;

    }

    class Program
    {
        static void Main(string[] args)
        {
            Thread TCP_Listen_Thread;
            TCP_Listen_Thread = new Thread(TCP_Listen_Thread_Function);
            TCP_Listen_Thread.Start();
        }

        //		
        //		 ______    __  ____       ____     ___     __    ___  ____  __ __    ___  ____  
        //		|      T  /  ]|    \     |    \   /  _]   /  ]  /  _]l    j|  T  |  /  _]|    \ 
        //		|      | /  / |  o  )    |  D  ) /  [_   /  /  /  [_  |  T |  |  | /  [_ |  D  )
        //		l_j  l_j/  /  |   _/     |    / Y    _] /  /  Y    _] |  | |  |  |Y    _]|    / 
        //		  |  | /   \_ |  |       |    \ |   [_ /   \_ |   [_  |  | l  :  !|   [_ |    \ 
        //		  |  | \     ||  |       |  .  Y|     T\     ||     T j  l  \   / |     T|  .  Y
        //		  l__j  \____jl__j       l__j\_jl_____j \____jl_____j|____j  \_/  l_____jl__j\_j
        //		
        //		
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        #region TCP Receiver

        private static void TCP_Listen_Thread_Function()
        {
            TcpListener server = null;
            ADTMessage adt_message;
            try
            {
                MLog.Info("Caching database...");
                try
                {
                    using (var db = new ADT_ModelContainer1())
                    {
                        var q1 = 
                            from adt in db.ADTMessages
                            where adt.MessageID == "1"
                            select adt;

                        var c1 = q1.First();
                    }
                }
                catch (Exception)
                {
                }

                Int32 port = Convert.ToInt32(Global.TCP_PORT);

                if (!System.Net.NetworkInformation.NetworkInterface.GetIsNetworkAvailable())
                {
                    MLog.Error("No network available... Press any key to exit.");
                    Console.ReadKey();
                    return;
                }

                IPAddress localAddr = IPAddress.Parse(LocalIPAddress());

                // TcpListener server = new TcpListener(port);
                server = new TcpListener(localAddr, port);

                // Start listening for client requests.
                server.Start();

                // Buffer for reading data
                byte[] raw;
                string rawString = "";
                
                // Enter the listening loop. 
                while (true)
                {
                    MLog.Info("Waiting for a connection... ");

                    // Perform a blocking call to accept requests. 
                    // You could also user server.AcceptSocket() here.
                    TcpClient client = server.AcceptTcpClient();
                    MLog.Info("Connected!");
                    NetworkStream stream = client.GetStream();
                    int i = 0;

                    while (client.Connected)
                    {
                        // If this truly loops around 1 time per message
                        // then let the info about the message be known
                        // MLog.Info("Yo, whatup!" + i++);

                        try
                        {
                            // this reads exactly 1 message
                            raw = blockingEOMRead(stream, 1000, 500, 1000, Global.EOM);

                            //MLog.Info("Test: " + i);

                            if (raw.Length == 0 || raw.Length == 1) continue;

                            rawString = Tool.ByteArrayToString(raw);

                            MLog.MsgCapture("Received: " + rawString);

                            // This extracts data from the message string
                            adt_message = new ADTMessage(rawString, DateTime.Now);

                            // Read from/Write to Patient and Location tables in database
                            if (!adt_message.skip) adt_message.parse();

                            adt_message.Log();

                            // Send an acknowledge
                            sendAck(stream);
                        }
                        catch (Exception ex)
                        {
                            MLog.Error("Exception Detected in msg: |" + rawString + "| Closing Connection.\n" + ex.Message);
                            client.Close();

                            break;
                        }
                    }                    
                }
            }
            catch (SocketException ex)
            {
                MLog.Error("FATAL: SocketException: " + ex);
            }
            finally
            {
                // Stop listening for new clients.
                server.Stop();
            }
        }

        private static void sendAck(NetworkStream stream)
        {
            byte[] ackMsg = System.Text.Encoding.UTF8.GetBytes(
                                    "\x0BMSH|^~\\&|||EPIC|EPICADT|" +
                                    DateTime.Now.Ticks + "||ACK||D|2.5\r" +
                                    "MSA|AA|\x1C\x0D");

            stream.Write(ackMsg, 0, ackMsg.Length);
            MLog.MsgCapture("Sent    : " + Tool.ByteArrayToString(ackMsg));
        }

        public static string LocalIPAddress()
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

        public static byte[] blockingEOMRead(NetworkStream stream,
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

        #endregion TCP Receiver
    }

    //		
    //		 ___ ___   ___   ___      ___  _            ___  __ __  ______    ___  ____    _____ ____  ___   ____    _____
    //		|   T   T /   \ |   \    /  _]| T          /  _]|  T  T|      T  /  _]|    \  / ___/l    j/   \ |    \  / ___/
    //		| _   _ |Y     Y|    \  /  [_ | |         /  [_ |  |  ||      | /  [_ |  _  Y(   \_  |  TY     Y|  _  Y(   \_ 
    //		|  \_/  ||  O  ||  D  YY    _]| l___     Y    _]l_   _jl_j  l_jY    _]|  |  | \__  T |  ||  O  ||  |  | \__  T
    //		|   |   ||     ||     ||   [_ |     T    |   [_ |     |  |  |  |   [_ |  |  | /  \ | |  ||     ||  |  | /  \ |
    //		|   |   |l     !|     ||     T|     |    |     T|  |  |  |  |  |     T|  |  | \    | j  ll     !|  |  | \    |
    //		l___j___j \___/ l_____jl_____jl_____j    l_____j|__j__|  l__j  l_____jl__j__j  \___j|____j\___/ l__j__j  \___j
    //		
    //		
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    #region Model Extensions

    //	
    //	    _    ____ _____ __  __                                
    //	   / \  |  _ \_   _|  \/  | ___  ___ ___  __ _  __ _  ___ 
    //	  / _ \ | | | || | | |\/| |/ _ \/ __/ __|/ _` |/ _` |/ _ \
    //	 / ___ \| |_| || | | |  | |  __/\__ \__ \ (_| | (_| |  __/
    //	/_/   \_\____/ |_| |_|  |_|\___||___/___/\__,_|\__, |\___|
    //	                                               |___/      
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public partial class ADTMessage
    {
        //_  _ ____ _  _    ____ _  _ ___ ____    _  _ ____ ____ _ ____ ___  _    ____ ____ 
        //|\ | |  | |\ | __ |__| |  |  |  |  |    |  | |__| |__/ | |__| |__] |    |___ [__  
        //| \| |__| | \|    |  | |__|  |  |__|     \/  |  | |  \ | |  | |__] |___ |___ ___] 
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        public string FirstName;
        public string LastName;
        ADTLookupResult adtLookupResult;
        LocationLookupResult locationLookupResult;
        PatientLookupResult patientLookupResult;
        public List<string> warnList = new List<string>();
        public bool skip = false;

        //____ ____ _  _ ____ ___ ____ _  _ ____ ___ ____ ____ 
        //|    |  | |\ | [__   |  |__/ |  | |     |  |  | |__/ 
        //|___ |__| | \| ___]  |  |  \ |__| |___  |  |__| |  \ 
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        public ADTMessage(string _MessageID)
        {
            MessageID = _MessageID;
        }

        public ADTMessage(string rawString, DateTime _GeneratedTimestamp)
        {
            // This parses the ADT string
            // and fills its own fields based on it

            GeneratedTimestamp = _GeneratedTimestamp;

            string[] subfields; // Move these declarations out of the loop

            string unit = "";
            string room = "";
            string bed = "";
            string facility = "";
            string[] fields;

            string[] segments = rawString.Split(new string[] { "\r", "\n", "\\r", "\\n", "\v" }, StringSplitOptions.RemoveEmptyEntries);

            foreach (string segment in segments)
            {
                fields = segment.Split(new string[] { "|", "\v" }, StringSplitOptions.None);

                switch (fields[0])
                {
                    case "MSH":

                        MessageTimestamp = getMSHTime(fields[6]);

                        try
                        {
                            subfields = fields[8].Split(new string[] { "^" }, StringSplitOptions.None);
                            MessageType = subfields[1];
                        }
                        catch (Exception ex)
                        {
                            warnList.Add("SKIP: Could not parse ADT msg type");
                            skip = true;
                            return;
                        }

                        try
                        {
                            MessageID = fields[9];
                        }
                        catch (Exception ex)
                        {
                            warnList.Add("SKIP: Could not parse ADT msg ID");
                            skip = true;
                            return;
                        }

                        break;
                    case "PID":
                        try
                        {
                            subfields = fields[3].Split(new string[] { "^" }, StringSplitOptions.None);

                            PatientID = subfields[0];

                            subfields = fields[5].Split(new string[] { "^" }, StringSplitOptions.None);
                            FirstName = subfields[1];
                            LastName = subfields[0];
                        }
                        catch (Exception ex)
                        {
                            warnList.Add("Could not parse patientID, FirstName, or LastName");
                        }

                        break;
                    case "PV1":
                        subfields = fields[3].Split(new string[] { "^" }, StringSplitOptions.None);

                        try
                        {
                            unit = subfields[0];
                            room = subfields[1];
                            bed = subfields[2];
                            facility = subfields[3];
                        }
                        catch (Exception)
                        {
                        }
                        
                        LocationID = facility + "$" + unit + "_" + room + "_" + bed;
                        break;
                    default:

                        break;
                }

            }

        }

        public DateTime getMSHTime(String stringTimestamp)
        {
            DateTime parsedDate = DateTime.UtcNow;

            if (DateTime.TryParseExact(stringTimestamp, "yyyyMMddHHmmss", null, DateTimeStyles.AdjustToUniversal, out parsedDate))
                MLog.Debug("Seconds in '" + stringTimestamp + "' timestamp (" + parsedDate + "()");
            else if (DateTime.TryParseExact(stringTimestamp, "yyyyMMddHHmm", null, DateTimeStyles.AdjustToUniversal, out parsedDate))
                MLog.Debug("No seconds in '" + stringTimestamp + "' timestamp (" + parsedDate + ")");
            else
                MLog.Debug("Unable to convert '" + stringTimestamp + "' to timestamp. Using UTCNow.");
            return parsedDate;
        }

        //___  ____ ____ ____ ____ 
        //|__] |__| |__/ [__  |___ 
        //|    |  | |  \ ___] |___ 
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        public void parse()
        {
            // LocationLookupStatus:
            // ----------------------
            // Blank                        - location = null           - existingPatient = null
            // Found_NoExistingPatient      - location = <a location>   - existingPatient = null
            // Found_ExistingPatientKicked  - location = <a location>   - existingPatient = <a patient>
            // NotFound_Created             - location = <a location>   - existingPatient = null
            // NotFound_NotCreated          - location = null           - existingPatient = null

            // PatientLookupStatus:
            // ---------------------
            // Blank                        - patient = null
            // Found                        - patient = <a patient>
            // NotFound                     - patient = null

            // MessageType
            // A01 - Admit                  - Need location             - Need patient
            // A02 - Transfer               - Need location             - Need patient
            // A03 - Discharge              - Do not Need location      - Need patient
            // A06 - OutpatientToIn         - Need location             - Need patient
            // A07 - InpatientToOut         - Do not Need location      - Need patient
            // A08 - Update                 - Need location             - Need patient
            // A11 - CancelAdmit            - Do not Need location      - Need patient
            // A12 - CancelTransfer         - Do not Need location      - Need patient
            // A13 - CancelDischarge        - Do not Need location      - Need patient

            // PatientStatus:
            // ----------------------
            // AdmittedWithLocation         
            // AdmittedWithoutLocation
            // Discharged

            // Query the database for the identifiers in the message
            adtLookupResult = ADTMessage.FindByID(MessageID);
            locationLookupResult = Location.FindByID(LocationID);
            patientLookupResult = Patient.FindByID(PatientID);


            switch (adtLookupResult.status)
            {
                case ADTLookupStatus.Blank: warnList.Add("SKIP: Blank Message ID"); skip = true; return;
                case ADTLookupStatus.Found: warnList.Add("SKIP: Message Already Exists"); skip = true; return;
                case ADTLookupStatus.CreatedNew: MessageID = adtLookupResult.message.MessageID; break;
            }

            switch (patientLookupResult.status)
	        {
                // If there is no patient: WARN AND EXIT
                case PatientLookupStatus.Blank: warnList.Add("SKIP: No Patient ID"); skip = true; return;

                // If there is no patient: INITIALIZE BASIC INFO
                case PatientLookupStatus.CreatedNew:
                    patientLookupResult.patient.FirstName = FirstName;
                    patientLookupResult.patient.LastName = LastName;
                    break;
	        }

            switch (MessageType)
            {
                // These messages can update a patient's location
                case "A01": case "A02": case "A06": case "A08":

                    int h = 5;
                    if(MessageType == "A06") h = 4;

                    // If there is no location 
                    // WARN AND EXIT
                    if (locationLookupResult.location == null) {
                        warnList.Add("SKIP: There was no location in " + MessageType); skip = true;  return;
                    }

                    // If there is an existing patient
                    // WARN AND KICK
                    if (locationLookupResult.existingPatient != null && 
                        locationLookupResult.existingPatient.PatientID != PatientID)
                    {
                        warnList.Add("Kicking existing Patient");
                        KickPatient();
                    }

                    // Update the patient, and ADT message
                    Update();

                    break;

                // These messages can discharge a patient
                case "A03": case "A07":
                    
                    // If there is no location 
                    // WARN
                    if (locationLookupResult.location == null) 
                        warnList.Add("There was no location in " + MessageType);
                    
                    // If there is an existing patient
                    // WARN
                    if (locationLookupResult.existingPatient != null &&
                        locationLookupResult.existingPatient.PatientID != PatientID)
                    {
                        warnList.Add(MessageType + " indicated different patient in location");
                    }
                    
                    // Discharge the patient
                    Discharge();

                    break;

                //case "A11": if (Global.Process_A11) CancelAdmit(); break;
                //case "A12": if (Global.Process_A12) CancelTransfer(); break;
                //case "A13": if (Global.Process_A13) CancelDischarge(); break;

                default: warnList.Add("SKIP: " + MessageType + " messages are not handled"); skip = true;  return;
            }

            // Write adt_message to the database
            CreateInDatabase();

        }



        //____ _ _  _ ___  ___  _   _ _ ___  
        //|___ | |\ | |  \ |__]  \_/  | |  \ 
        //|    | | \| |__/ |__]   |   | |__/ 
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        public static ADTLookupResult FindByID(String ID_toQuery)
        {
            ADTMessage adt_message;

            using (var db = new ADT_ModelContainer1())
            {
                if (ID_toQuery == "") return new ADTLookupResult(ADTLookupStatus.Blank, null);
                else
                {
                    try
                    {
                        // Check database for ADTMessage
                        adt_message = db.ADTMessages.First(adt => adt.MessageID == ID_toQuery);

                        // ADTMessage was found...

                        // If AllowDuplicateMessageIDs is set, recursively find the next available MessageID
                        if (Global.AllowDuplicateMessageIDs)
                        {
                            string[] full_id_split = ID_toQuery.Split(new string[] { "--" }, StringSplitOptions.None);
                            if(full_id_split.Length == 1)
                                return FindByID(ID_toQuery + "--1");
                            else
                            {
                                return FindByID(full_id_split[0] + "--" + (Int32.Parse(full_id_split[1]) + 1));
                            }
                        }
                        // Otherwise, return that it was found
                        else
                            return new ADTLookupResult(ADTLookupStatus.Found, adt_message);
                    }
                    // TargetInvocationException
                    catch (Exception)
                    {
                        adt_message = new ADTMessage(ID_toQuery);
                        return new ADTLookupResult(ADTLookupStatus.CreatedNew, adt_message);
                    }
                }
            }
        }



        //_  _ ___  ___  ____ ___ ____ 
        //|  | |__] |  \ |__|  |  |___ 
        //|__| |    |__/ |  |  |  |___ 
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        public void Update()
        {
            // Store the previous status and location in ADT table
            PreviousStatus = patientLookupResult.patient.Status;
            PreviousLocationID = patientLookupResult.patient.LocationID;

            // Store the patient's new status
            patientLookupResult.patient.Status = 
                locationLookupResult.location != null? 
                Enum.GetName(typeof(PatientStatus), PatientStatus.AdmittedWithLocation) :
                Enum.GetName(typeof(PatientStatus), PatientStatus.AdmittedWithoutLocation);
                
            // Store the patient's new location
            patientLookupResult.patient.LocationID = locationLookupResult.location.LocationID;

            // Make sure these are stored for the ADT message as well
            Status = patientLookupResult.patient.Status;
            LocationID = patientLookupResult.patient.LocationID;

            switch (patientLookupResult.status)
            {
                // Add patient to database
                case PatientLookupStatus.CreatedNew:
                    patientLookupResult.patient.CreateInDatabase();
                    break;

                // Update patient in database
                case PatientLookupStatus.Found:
                    patientLookupResult.patient.UpdateInDatabase();
                    break;
            }
        }
        


        //_ _ _ ____ ____ _  _ 
        //| | | |__| |__/ |\ | 
        //|_|_| |  | |  \ | \| 
        //////////////////////////////////////////////////////////////////////////////////////////////////////////

        internal void Log()
        {
            string msg = LookupStatusesToString() + (skip? "Skipped! " : "STORED!  ");

            if(warnList.Count() > 0) msg += warnList.Count() + " Warnings: " + string.Join("; ", warnList);
            
            MLog.Info(msg);
        }
        
        
        private string LookupStatusesToString()
        {
            return String.Format( 
                "msgID {0,-14}, msgType {1,-3}, adt {2,-10}, patient {3,-10}, location = {4,-27}: ",
                MessageID,
                MessageType,
                Enum.GetName(typeof(ADTLookupStatus), adtLookupResult.status),
                Enum.GetName(typeof(PatientLookupStatus), patientLookupResult.status),
                Enum.GetName(typeof(LocationLookupStatus), locationLookupResult.status)
            );
        }



        //_  _ _ ____ _  _ ___  ____ ___ _ ____ _  _ ___ 
        //|_/  | |    |_/  |__] |__|  |  | |___ |\ |  |  
        //| \_ | |___ | \_ |    |  |  |  | |___ | \|  |  
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        private void KickPatient()
        {
            // Update the kicked patient
            locationLookupResult.existingPatient.LocationID = null;
            locationLookupResult.existingPatient.Status = Enum.GetName(typeof(PatientStatus), PatientStatus.AdmittedWithoutLocation);
            locationLookupResult.existingPatient.UpdateInDatabase();

            // Store the kicked patient in the ADT Message
            KickedPatientID = locationLookupResult.existingPatient.PatientID;
        }

        //___  _ ____ ____ _  _ ____ ____ ____ ____ 
        //|  \ | [__  |    |__| |__| |__/ | __ |___ 
        //|__/ | ___] |___ |  | |  | |  \ |__] |___ 
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        public void Discharge()
        {
            // Store the previous status and location in ADT table
            PreviousStatus = patientLookupResult.patient.Status;
            PreviousLocationID = patientLookupResult.patient.LocationID;

            // Store the patient's new status
            patientLookupResult.patient.Status = Enum.GetName(typeof(PatientStatus), PatientStatus.Discharged);

            // Store the patient's new location
            patientLookupResult.patient.LocationID = null;

            Status = Enum.GetName(typeof(PatientStatus), PatientStatus.Discharged);
            LocationID = null;

            switch (patientLookupResult.status)
            {
                // Add patient to database
                case PatientLookupStatus.CreatedNew:
                    patientLookupResult.patient.CreateInDatabase();
                    break;

                // Update patient in database
                case PatientLookupStatus.Found:
                    patientLookupResult.patient.UpdateInDatabase();
                    break;
            }
        }

        //____ ____ _  _ ____ ____ _    ____ ___  _  _ _ ___ 
        //|    |__| |\ | |    |___ |    |__| |  \ |\/| |  |  
        //|___ |  | | \| |___ |___ |___ |  | |__/ |  | |  |  
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        private void CancelAdmit()
        {
            throw new NotImplementedException();
        }

        //____ ____ _  _ ____ ____ _    ___ ____ ____ _  _ ____ ____ ____ ____ 
        //|    |__| |\ | |    |___ |     |  |__/ |__| |\ | [__  |___ |___ |__/ 
        //|___ |  | | \| |___ |___ |___  |  |  \ |  | | \| ___] |    |___ |  \ 
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        private void CancelTransfer()
        {
            throw new NotImplementedException();
        }

        //____ ____ _  _ ____ ____ _    ___  _ ____ ____ _  _ ____ ____ ____ ____ 
        //|    |__| |\ | |    |___ |    |  \ | [__  |    |__| |__| |__/ | __ |___ 
        //|___ |  | | \| |___ |___ |___ |__/ | ___] |___ |  | |  | |  \ |__] |___ 
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        private void CancelDischarge()
        {
            throw new NotImplementedException();
        }


    }

    //	
    //	 ____       _   _            _   
    //	|  _ \ __ _| |_(_) ___ _ __ | |_ 
    //	| |_) / _` | __| |/ _ \ '_ \| __|
    //	|  __/ (_| | |_| |  __/ | | | |_ 
    //	|_|   \__,_|\__|_|\___|_| |_|\__|
    //	
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public partial class Patient
    {

        //____ ____ _  _ ____ ___ ____ _  _ ____ ___ ____ ____ 
        //|    |  | |\ | [__   |  |__/ |  | |     |  |  | |__/ 
        //|___ |__| | \| ___]  |  |  \ |__| |___  |  |__| |  \ 
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        public Patient(string _PatientID)
        {
            PatientID = _PatientID;
        }

        //____ _ _  _ ___  ___  _   _ _ ___  
        //|___ | |\ | |  \ |__]  \_/  | |  \ 
        //|    | | \| |__/ |__]   |   | |__/ 
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        public static PatientLookupResult FindByID(String ID_toQuery)
        {
            Patient patient;

            using (var db = new ADT_ModelContainer1())
            {
                if (ID_toQuery == "") return new PatientLookupResult(PatientLookupStatus.Blank, null);
                else
                {
                    try
                    {
                        // Check database for patient
                        patient = db.Patients.First(pat => pat.PatientID == ID_toQuery);
                        
                        // Patient was found
                        return new PatientLookupResult(PatientLookupStatus.Found, patient);

                    }
                    // TargetInvocationException
                    catch (Exception)
                    {
                        patient = new Patient(ID_toQuery);
                        return new PatientLookupResult(PatientLookupStatus.CreatedNew, patient);
                    }
                }
            }
        }

    }

    //	 _                    _   _             
    //	| |    ___   ___ __ _| |_(_) ___  _ __  
    //	| |   / _ \ / __/ _` | __| |/ _ \| '_ \ 
    //	| |__| (_) | (_| (_| | |_| | (_) | | | |
    //	|_____\___/ \___\__,_|\__|_|\___/|_| |_|
    //	
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public partial class Location
    {
        //____ _ _  _ ___  ___  _   _ _ ___  
        //|___ | |\ | |  \ |__]  \_/  | |  \ 
        //|    | | \| |__/ |__]   |   | |__/ 
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        public static LocationLookupResult FindByID(String ID_toQuery)
        {
            Location location;
            Patient existingPatient;

            using (var db = new ADT_ModelContainer1())
            {
                if (ID_toQuery == null || ID_toQuery == "") return new LocationLookupResult(LocationLookupStatus.Blank, null);
                else
                {
                    try
                    {
                        // Try to find the location
                        location = db.Locations.First(loc => loc.LocationID == ID_toQuery);
                        
                        // Location Found!

                        // Check for existing patient
                        try
                        {
                            // Try to find an existing patient
                            existingPatient = db.Patients.First(pat => pat.LocationID == ID_toQuery);

                            // There was a patient there...  this should almost NEVER happen... Time to kick them out.
                            return new LocationLookupResult(LocationLookupStatus.Found_ExistingPatientKicked, location, existingPatient);
                        }
                        catch (Exception)
                        {
                            // No patient was in that room
                            return new LocationLookupResult(LocationLookupStatus.Found_NoExistingPatient, location);
                        }
                    } 
                    // TargetInvocationException
                    catch (Exception)
                    {
                        if (Global.CreateLocations)
                        {
                            location = new Location(ID_toQuery);
                            location.CreateInDatabase();
                            return new LocationLookupResult(LocationLookupStatus.CreatedNew, location);
                        }
                        else
                            return new LocationLookupResult(LocationLookupStatus.NotFound_NotCreated, null);
                        
                    }
                }
            }
        }
    }


    public partial class ADT_ModelContainer1
    {
        public override int SaveChanges()
        {
            try
            {
                return base.SaveChanges();
            }
            catch (DbEntityValidationException ex)
            {
                // Retrieve the error messages as a list of strings.
                var errorMessages = ex.EntityValidationErrors
                        .SelectMany(x => x.ValidationErrors)
                        .Select(x => x.ErrorMessage);

                // Join the list to a single string.
                var fullErrorMessage = string.Join("\n\t\t", errorMessages);

                // Combine the original exception message with the new one.
                var exceptionMessage = string.Concat("Caught DbEntityValidationException\n\tEntityValidationErrors:\n\t\t", fullErrorMessage);

                // Throw a new DbEntityValidationException with the improved exception message.
                throw new DbEntityValidationException(exceptionMessage, ex.EntityValidationErrors);
            }
            catch(Exception ex)
            {
                throw new Exception(ex.Message + "\nINNER EXCEPTION:\n" + ex.InnerException);
            }
        }

    }


    #endregion Model Extensions





    //		
    //		 ______  ____    ____  ____    _____ ____    ___   ____  ______      _       ____  __ __    ___  ____  
    //		|      T|    \  /    T|    \  / ___/|    \  /   \ |    \|      T    | T     /    T|  T  T  /  _]|    \ 
    //		|      ||  D  )Y  o  ||  _  Y(   \_ |  o  )Y     Y|  D  )      |    | |    Y  o  ||  |  | /  [_ |  D  )
    //		l_j  l_j|    / |     ||  |  | \__  T|   _/ |  O  ||    /l_j  l_j    | l___ |     ||  ~  |Y    _]|    / 
    //		  |  |  |    \ |  _  ||  |  | /  \ ||  |   |     ||    \  |  |      |     T|  _  |l___, ||   [_ |    \ 
    //		  |  |  |  .  Y|  |  ||  |  | \    ||  |   l     !|  .  Y |  |      |     ||  |  ||     !|     T|  .  Y
    //		  l__j  l__j\_jl__j__jl__j__j  \___jl__j    \___/ l__j\_j l__j      l_____jl__j__jl____/ l_____jl__j\_j
    //		
    //		
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    #region Transport Layer



    public class ADTLookupResult
    {
        public ADTLookupStatus status;
        public ADTMessage message;

        public ADTLookupResult(
            ADTLookupStatus _status,
            ADTMessage _message)
        {
            status = _status;
            message = _message;
        }
    }



    //	
    //	 _                    _   _             _                _                ____                 _ _   
    //	| |    ___   ___ __ _| |_(_) ___  _ __ | |    ___   ___ | | ___   _ _ __ |  _ \ ___  ___ _   _| | |_ 
    //	| |   / _ \ / __/ _` | __| |/ _ \| '_ \| |   / _ \ / _ \| |/ / | | | '_ \| |_) / _ \/ __| | | | | __|
    //	| |__| (_) | (_| (_| | |_| | (_) | | | | |__| (_) | (_) |   <| |_| | |_) |  _ <  __/\__ \ |_| | | |_ 
    //	|_____\___/ \___\__,_|\__|_|\___/|_| |_|_____\___/ \___/|_|\_\\__,_| .__/|_| \_\___||___/\__,_|_|\__|
    //	                                                                   |_|                               
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public class LocationLookupResult
    {
        public LocationLookupStatus status;
        public Location location;
        public Patient existingPatient;

        public LocationLookupResult(
            LocationLookupStatus _status,
            Location _location,
            Patient _existingPatient)
        {
            status = _status;
            location = _location;
            existingPatient = _existingPatient;
        }

        public LocationLookupResult(
            LocationLookupStatus _status,
            Location _location)
        {
            status = _status;
            location = _location;
        }
    }

    //	
    //	 ____       _   _            _   _                _                ____                 _ _   
    //	|  _ \ __ _| |_(_) ___ _ __ | |_| |    ___   ___ | | ___   _ _ __ |  _ \ ___  ___ _   _| | |_ 
    //	| |_) / _` | __| |/ _ \ '_ \| __| |   / _ \ / _ \| |/ / | | | '_ \| |_) / _ \/ __| | | | | __|
    //	|  __/ (_| | |_| |  __/ | | | |_| |__| (_) | (_) |   <| |_| | |_) |  _ <  __/\__ \ |_| | | |_ 
    //	|_|   \__,_|\__|_|\___|_| |_|\__|_____\___/ \___/|_|\_\\__,_| .__/|_| \_\___||___/\__,_|_|\__|
    //	                                                            |_|                               
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public class PatientLookupResult
    {
        public PatientLookupStatus status;
        public Patient patient;

        public PatientLookupResult(
            PatientLookupStatus _status,
            Patient _patient)
        {
            status = _status;
            patient = _patient;
        }
    }

    #endregion Transport Layer


    //		
    //		
    //		  _____ ______   ____  ______  __ __  _____   ___  _____
    //		 / ___/|      T /    T|      T|  T  T/ ___/  /  _]/ ___/
    //		(   \_ |      |Y  o  ||      ||  |  (   \_  /  [_(   \_ 
    //		 \__  Tl_j  l_j|     |l_j  l_j|  |  |\__  TY    _]\__  T
    //		 /  \ |  |  |  |  _  |  |  |  |  :  |/  \ ||   [_ /  \ |
    //		 \    |  |  |  |  |  |  |  |  l     |\    ||     T\    |
    //		  \___j  l__j  l__j__j  l__j   \__,_j \___jl_____j \___j
    //		
    //		
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    #region Statuses

         
    // MaxLength = 10
    public enum ADTLookupStatus
    {
        Blank,
        Found,
        CreatedNew
    }

    // MaxLength 23

    //	
    //	 ____       _   _            _   ____  _        _             
    //	|  _ \ __ _| |_(_) ___ _ __ | |_/ ___|| |_ __ _| |_ _   _ ___ 
    //	| |_) / _` | __| |/ _ \ '_ \| __\___ \| __/ _` | __| | | / __|
    //	|  __/ (_| | |_| |  __/ | | | |_ ___) | || (_| | |_| |_| \__ \
    //	|_|   \__,_|\__|_|\___|_| |_|\__|____/ \__\__,_|\__|\__,_|___/
    //	
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public enum PatientStatus
    {
        AdmittedWithLocation,
        AdmittedWithoutLocation,
        Discharged
    }

    // Max Legth = 27
    //	 _                    _   _             _                _               ____  _        _             
    //	| |    ___   ___ __ _| |_(_) ___  _ __ | |    ___   ___ | | ___   _ _ __/ ___|| |_ __ _| |_ _   _ ___ 
    //	| |   / _ \ / __/ _` | __| |/ _ \| '_ \| |   / _ \ / _ \| |/ / | | | '_ \___ \| __/ _` | __| | | / __|
    //	| |__| (_) | (_| (_| | |_| | (_) | | | | |__| (_) | (_) |   <| |_| | |_) |__) | || (_| | |_| |_| \__ \
    //	|_____\___/ \___\__,_|\__|_|\___/|_| |_|_____\___/ \___/|_|\_\\__,_| .__/____/ \__\__,_|\__|\__,_|___/
    //	                                                                   |_|                                
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public enum LocationLookupStatus
    {
        Blank,
        Found_NoExistingPatient,
        Found_ExistingPatientKicked,
        CreatedNew,
        NotFound_NotCreated
    }

    //	
    //	 ____       _   _            _   _                _               ____  _        _             
    //	|  _ \ __ _| |_(_) ___ _ __ | |_| |    ___   ___ | | ___   _ _ __/ ___|| |_ __ _| |_ _   _ ___ 
    //	| |_) / _` | __| |/ _ \ '_ \| __| |   / _ \ / _ \| |/ / | | | '_ \___ \| __/ _` | __| | | / __|
    //	|  __/ (_| | |_| |  __/ | | | |_| |__| (_) | (_) |   <| |_| | |_) |__) | || (_| | |_| |_| \__ \
    //	|_|   \__,_|\__|_|\___|_| |_|\__|_____\___/ \___/|_|\_\\__,_| .__/____/ \__\__,_|\__|\__,_|___/
    //	                                                            |_|                                
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public enum PatientLookupStatus
    {
        Blank,
        Found,
        CreatedNew
    }

    #endregion Statuses


    //	
    //	 _____           _ 
    //	|_   _|__   ___ | |
    //	  | |/ _ \ / _ \| |
    //	  | | (_) | (_) | |
    //	  |_|\___/ \___/|_|
    //	
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public class Tool
    {
        public static string ByteArrayToString(byte[] input)
        {
            UTF8Encoding enc = new UTF8Encoding();
            string str = enc.GetString(input);
            return str.Replace("\r", "\\r").Replace("\n", "\\n");
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

    }


}

