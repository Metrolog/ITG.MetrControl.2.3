using System;
using System.Text;
using System.Runtime.InteropServices;

namespace ITG.Ini
{
    class IniDocument
    {
        readonly
        public
        String
        FilePath;

        [DllImport(
            "kernel32"
            , CharSet=CharSet.Unicode
            , SetLastError=true
        )]
        [return: MarshalAs(UnmanagedType.Error)] 
        static
        extern
        bool
        WritePrivateProfileString(
            [In, MarshalAs(UnmanagedType.LPWStr)] String Section
            , [In, MarshalAs(UnmanagedType.LPWStr)] String Key
            , [In, MarshalAs(UnmanagedType.LPWStr)] String Value
            , [In, MarshalAs(UnmanagedType.LPWStr)] String FilePath
        );

        [DllImport(
            "kernel32"
            , CharSet=CharSet.Unicode
            , SetLastError=true
        )]
        [return: MarshalAs(UnmanagedType.U4)]
        static
        extern
        int
        GetPrivateProfileString(
            [In, MarshalAs(UnmanagedType.LPWStr)] String Section
            , [In, MarshalAs(UnmanagedType.LPWStr)] String Key
            , [In, MarshalAs(UnmanagedType.LPWStr)] StringBuilder Default
            , [Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder RetVal
            , [In, MarshalAs(UnmanagedType.U4)] int Size
            , [In, MarshalAs(UnmanagedType.LPWStr)] String FilePath
        );

        public 
        IniDocument(
            String FilePath
        )
        {
            this.FilePath = new System.IO.FileInfo(FilePath).FullName.ToString();
        }

        public
        String
        this[
            String Section
            , String Key 
        ]
        {
            get
            {
                return Read(Section, Key);
            }
            set
            {
                Write(Section, Key, value); 
            } 
        }

        public
        String
        Read(
            String Section
            , String Key
        )
        {
            StringBuilder RetVal = new StringBuilder(255);
            GetPrivateProfileString(
                Section
                , Key
                , null
                , RetVal
                , RetVal.Capacity
                , FilePath
            );
            return RetVal.ToString();
        }

        public
        void
        Write(
            String Section
            , String Key
            , String Value
        )
        {
            WritePrivateProfileString(
                Section
                , Key
                , Value
                , FilePath
            );
        }

        public
        void
        DeleteKey(
            String Section
            , String Key
        )
        {
            Write(
                Section
                , Key
                , null
            );
        }

        public
        void
        DeleteSection(
            String Section
        )
        {
            Write(
                Section
                , null
                , null
            );
        }

        public
        bool
        KeyExists(
            String Section
            , String Key
        )
        {
            return Read(Section, Key).Length > 0 ? true : false;
        }
    }
}
