using System;
using System.Text;
using System.Xml;
using System.Collections.Generic;
using System.Diagnostics;
using System.Reflection;
using ITG.Ini;
using ITG.Deployment.WindowsInstaller;

namespace ITG.CSM.Metrcontrol
{
    class Bootstrapper
    {
        #region аргументы командной строки

        static
        String
        DB;

        enum CsmTool
        {
            csmmain
            , csmadmin
            , markinv
        }   

        static
        CsmTool
        Tool;

        #endregion аргументы командной строки

        #region main

        static
        void
        Main(string[] args)
        {
            if (args.Length < 1)
            {
                System.Environment.Exit(1);
            };
            DB = args[0];

            IniDocument csmDbFile = new IniDocument(DB);
            Console.WriteLine(csmDbFile["MetrControlDB", "Server"]);

            #region формируем xml файл конфигурации CnnSettings.xml
            XmlDocument config = new XmlDocument();
            config.LoadXml(
                String.Format(
@"<?xml version=""1.0"" encoding=""utf-8""?>
<entries>
	<entry key=""Key"">35AA16F410699668C19C86A111D7A1287FD6D0FB33490C9B</entry>
	<entry key=""IV"">3CE48E956DFB399A</entry>
	<entry key=""iFirst.SP.Ryabkov.CrossSessionData.UniversalSettingsSaver key: Assembly version: "">1.48.0.1</entry>
	<entry key=""SQLConnectLib.SQLConnecter key: server"">{0}</entry>
	<entry key=""SQLConnectLib.SQLConnecter key: db"">{1}</entry>
	<entry key=""SQLConnectLib.SQLConnecter key: user"">{2}</entry>
	<entry key=""SQLConnectLib.SQLConnecter key: passwd"">{3}</entry>
	<entry key=""SQLConnectLib.SQLConnecter key: timeout"">-1</entry>
	<entry key=""SQLConnectLib.SQLConnecter key: ntauth"">{4}</entry>
</entries>"
                    , csmDbFile["MetrControlDB", "Server"]
                    , csmDbFile["MetrControlDB", "Database"]
                    , csmDbFile["MetrControlDB", "Login"]
                    , csmDbFile["MetrControlDB", "PasswordHash"]
                    , (csmDbFile["MetrControlDB", "NTLM"] == "yes")
                    , csmDbFile["MetrControlDB", "Server"]
                    , csmDbFile["MetrControlDB", "Server"]
                )
            );
            XmlWriterSettings writerSettings = new System.Xml.XmlWriterSettings()
            {
                Indent = true
                , OmitXmlDeclaration = false
                , NamespaceHandling = NamespaceHandling.OmitDuplicates
                , NewLineOnAttributes = false
                , CloseOutput = true
                , IndentChars = "\t"
            };
            XmlWriter writer = XmlWriter.Create(
                System.Environment.ExpandEnvironmentVariables("%LocalAppData%\\IFirst\\MetrControl\\CnnSettings.xml")
                , writerSettings
            );
            config.WriteTo(writer);
            writer.Close();
            #endregion

            #region проверяем и восстанавливаем необходимое приложение, запускаем его
            String ToolPath = "";
            String ToolId = "csmmain";
            if (args.Length > 1)
            {
                ToolId = args[1];
            };
            switch (ToolId)
            {
                case "csmadmin":
                    Tool = CsmTool.csmadmin;
                    ToolPath = Package.ProvideComponent(
                        new Guid("{89AC374A-B77C-4CD7-BD3E-580D726EFCD5}")
                        , Tool.ToString()
                        , new Guid("{E5957298-538D-44F3-86B5-76D09E721E0E}")
                    );
                    break;
                case "csmmain":
                case "":
                    Tool = CsmTool.csmmain;
                    ToolPath = Package.ProvideComponent(
                        new Guid("{89AC374A-B77C-4CD7-BD3E-580D726EFCD5}")
                        , Tool.ToString()
                        , new Guid("{A8840BA1-D58E-4DAC-A867-2131F2CFE7B6}")
                    );
                    break;
                case "markinv":
                    Tool = CsmTool.markinv;
                    ToolPath = Package.ProvideComponent(
                        new Guid("{89AC374A-B77C-4CD7-BD3E-580D726EFCD5}")
                        , Tool.ToString()
                        , new Guid("{787104E4-96B1-4D9E-A10D-B2D285A47E13}")
                    );
                    break;
                default:
                    System.Environment.Exit(1);
                    break;
            };
            Process.Start(ToolPath);
            #endregion
        }

        #endregion
    }
}
