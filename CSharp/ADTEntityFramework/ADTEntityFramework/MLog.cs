using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ADTEntityFramework
{
    public static class MLog
    {
        
        public static void Debug(String msg)
        {
            if (Global.logDebug)
                LogToConsole("Debug", "    ", msg);
        }

        public static void Info(String msg)
        {
            if (Global.logInfo)
                LogToConsole("Info", "    ", msg);
        }

        public static void Warn(String msg)
        {
            if (Global.LogWarnings)
                LogToConsole("Warn", "    ", msg);
        }

        public static void Error(String msg)
        {
            if (Global.LogErrors)
                LogToConsole("ERROR", "    ", msg);
        }

        public static void MsgCapture(String msg)
        {
            if (Global.LogAllMessages)
                LogToConsole("MsgCap", "    ", msg);
        }

        private static void LogToConsole(String logType, String indention, String message)
        {
            message = message
                .Replace("\r\n", "\n")
                .Replace("\n", "\n                   " + indention)
                .Replace("\r", "\r                   " + indention);

            Console.WriteLine(String.Format("{0:hh:mm:ss} - {1,-7}:{2}{3}", 
                DateTime.Now, logType, indention, message));
        }

    }
}
