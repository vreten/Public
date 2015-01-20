using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Timers;

namespace ADTEntityFramework
{
    public static class MLog
    {
        static string filename;
        static Timer _timer;

        static StringBuilder sb;
        static readonly object sb_mutex;

        static MLog()
        {
            filename = "log.txt";

            sb_mutex = new object();
            sb = new StringBuilder();
            _timer = new Timer(3000);

            _timer.Elapsed += new ElapsedEventHandler(saveLog);

            _timer.Enabled = true;

        }

        public static void saveLog(object sender, ElapsedEventArgs e)
        {
            lock(sb_mutex)
            {
                if (Global.logToFile)
                {
                    FileStream fs = new FileStream(filename, FileMode.Append, FileAccess.Write, FileShare.None);

                    StreamWriter swFromFileStream = new StreamWriter(fs);

                    swFromFileStream.Write(sb.ToString());

                    swFromFileStream.Flush();

                    swFromFileStream.Close();

                }
                if (Global.logToConsole)
                {
                    Console.Write(sb.ToString());
                }

                sb.Clear();
            }
        }


        public static void Debug(String msg)
        {
            if (Global.logDebug)
                AppendLog("Debug", "    ", msg);
        }

        public static void Info(String msg)
        {
            if (Global.logInfo)
                AppendLog("Info", "    ", msg);
        }

        public static void Warn(String msg)
        {
            if (Global.LogWarnings)
                AppendLog("Warn", "    ", msg);
        }

        public static void Error(String msg)
        {
            if (Global.LogErrors)
                AppendLog("ERROR", "    ", msg);
        }

        public static void MsgCapture(String msg)
        {
            if (Global.LogAllMessages)
                AppendLog("MsgCap", "    ", msg);
        }

        private static void AppendLog(String logType, String indention, String message)
        {
            message = message
                .Replace("\r\n", "\n")
                .Replace("\n", "\n                   " + indention)
                .Replace("\r", "\r                   " + indention);

            lock (sb_mutex) sb.AppendLine(String.Format("{0:hh:mm:ss} - {1,-7}:{2}{3}",
                DateTime.Now, logType, indention, message));
        }

    }
}
