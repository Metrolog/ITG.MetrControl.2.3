using System;
using System.Text;
using System.Runtime.InteropServices;

namespace ITG.Deployment.WindowsInstaller
{
    public
    class Package
    {
        public
        enum
        InstallMode : int
        {
            NoSourceResolution = -3,
            NoDetection = -2,
            Existing = -1,
            Default = 0,
        }

        public
        enum
        Error : int
        {
            SUCCESS = 0,
            FILE_NOT_FOUND = 2,
            PATH_NOT_FOUND = 3,
            ACCESS_DENIED = 5,
            INVALID_HANDLE = 6,
            INVALID_DATA = 13,
            INVALID_PARAMETER = 87,
            OPEN_FAILED = 110,
            DISK_FULL = 112,
            CALL_NOT_IMPLEMENTED = 120,
            BAD_PATHNAME = 161,
            NO_DATA = 232,
            MORE_DATA = 234,
            NO_MORE_ITEMS = 259,
            DIRECTORY = 267,
            INSTALL_USEREXIT = 1602,
            INSTALL_FAILURE = 1603,
            FILE_INVALID = 1006,
            UNKNOWN_PRODUCT = 1605,
            UNKNOWN_FEATURE = 1606,
            UNKNOWN_COMPONENT = 1607,
            UNKNOWN_PROPERTY = 1608,
            INVALID_HANDLE_STATE = 1609,
            INSTALL_SOURCE_ABSENT = 1612,
            BAD_QUERY_SYNTAX = 1615,
            INSTALL_PACKAGE_INVALID = 1620,
            FUNCTION_FAILED = 1627,
            INVALID_TABLE = 1628,
            DATATYPE_MISMATCH = 1629,
            CREATE_FAILED = 1631,
            SUCCESS_REBOOT_INITIATED = 1641,
            SUCCESS_REBOOT_REQUIRED = 3010,
        }

        [DllImport(
            "msi.dll"
            , CharSet = CharSet.Unicode
            , SetLastError = false
        )]
        [return: MarshalAs(UnmanagedType.Error)]
        static
        extern
        Error
        MsiProvideComponent(
            [In, MarshalAs(UnmanagedType.LPWStr)]        String Product
            , [In, MarshalAs(UnmanagedType.LPWStr)]      String Feature
            , [In, MarshalAs(UnmanagedType.LPWStr)]      String Component
            , [In, MarshalAs(UnmanagedType.U4)]          InstallMode Mode
            , [In, Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder Path
            , [In, Out, MarshalAs(UnmanagedType.U4)] ref int cchPathBuf
        );
        
        public
        static
        String
        ProvideComponent(
            Guid Product
            , String Feature
            , Guid Component
            , InstallMode installMode = InstallMode.Default
        )
        {
            StringBuilder Path = new StringBuilder(1024);
            int PathBufferSize = Path.Capacity;

            Error error = MsiProvideComponent(
                Product.ToString("B")
                , Feature
                , Component.ToString("B")
                , installMode
                , Path
                , ref PathBufferSize
            );

            if ( error == Error.MORE_DATA ) {
                Path.Capacity = ++PathBufferSize;
                error = MsiProvideComponent(
                    Product.ToString("B")
                    , Feature
                    , Component.ToString("B")
                    , installMode
                    , Path
                    , ref PathBufferSize
                );
            };

            Marshal.ThrowExceptionForHR( (int)error );
            return Path.ToString();            
        }

    }
}
