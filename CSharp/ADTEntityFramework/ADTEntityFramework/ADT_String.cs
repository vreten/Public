using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ADTEntityFramework
{
    class ADT_String
    {
        

        public int MessageID
        {
            get;
            set;
        }
        public string MessageType { get; set; }
        public string LocationBefore { get; set; }
        public string LocationAfter { get; set; }
        public string StatusBefore { get; set; }
        public string StatusAfter { get; set; }
        public DateTime MessageTimestamp { get; set; }
        public string PatientID { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
    }
}
