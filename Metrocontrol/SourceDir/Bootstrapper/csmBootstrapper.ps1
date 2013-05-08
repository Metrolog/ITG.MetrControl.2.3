<#
.Synopsis
	Загрузчик инструментов АИС Метроконтроль
.Description
	Загрузчик инструментов АИС Метроконтроль. В качестве аргумента принимает
    путь к файлу .csmdb (по структуре - .ini файл), формирует на его основе
    CnnSettings.xml файл в профиле пользователя, после чего инициализирует
    запуск инструмента АИС Метроконтроль через вызов глагола через методы 
    Shell (с целью поддержки механизма install-on-demand MSI).
#>
[CmdletBinding(
	ConfirmImpact = 'Low',
	SupportsShouldProcess = $true
)]

param (
	# Полный путь к .csmdb файлу.
	[Parameter(
		Position=1
	)]
	[System.IO.FileInfo]
    [ValidateNotNullOrEmpty()]
	$CsmDB
,
	# Инструмент АИС Метроконтроль, который требуется запустить для указанной базы данных.
	[Parameter(
		Position=2
	)]
	[String]
    [ValidateSet( 'CsmMain', 'CsmAdmin', 'MarkInv' )]
	$CsmTool = 'CsmMain'
)

Function Get-IniContent {
[CmdletBinding(
	ConfirmImpact = 'Low',
	SupportsShouldProcess = $false
)]

    param (
	    # Полный путь к .ini файлу.
	    [Parameter(
		    Position=0
	    )]
	    [System.IO.FileInfo]
        [ValidateNotNullOrEmpty()]
        [Alias('Path')]
	    $LiteralPath
    )

    $result = New-Object -TypeName PSObject;
    $currentSection = 'null';
    switch -regex -file $LiteralPath
    {
        "^(;.*)$" {
        } 
        "^\[\s*(?<section>.+?)\s*\]\s*$" {
            $currentSection = $matches['section'];
            Add-Member `
                -InputObject $result `
                -MemberType NoteProperty `
                -Name $currentSection `
                -Value (
                    New-Object -TypeName PSObject
                ) `
            ;
        }
        "^(?:(?:`"(?<id>.+?)`")|(?<id>\S+?))\s*=\s*(?:(?:`"(?<value>.*?)`")|(?<value>.*?))\s*$" {
            Add-Member `
                -InputObject $result.$currentSection `
                -MemberType NoteProperty `
                -Name ( $matches['id'] ) `
                -Value ( $matches['value'] ) `
            ;
        }
    }
    return $result;
}

$CsmDBData = Get-IniContent -LiteralPath $CsmDB;

$ConfigPath = `
(Join-Path `
    -Path (Join-Path `
        -Path (Join-Path `
            -Path ( [System.Environment]::GetFolderPath( 'LocalApplicationData' ) ) `
            -ChildPath 'IFirst' `
        ) `
        -ChildPath 'MetrControl' `
    )`
    -ChildPath 'CnnSettings.xml' `
);

$Config = [xml]@"
<?xml version="1.0" encoding="utf-8"?>
<entries>
	<entry key="Key">35AA16F410699668C19C86A111D7A1287FD6D0FB33490C9B</entry>
	<entry key="IV">3CE48E956DFB399A</entry>
	<entry key="iFirst.SP.Ryabkov.CrossSessionData.UniversalSettingsSaver key: Assembly version: ">1.48.0.1</entry>
	<entry key="SQLConnectLib.SQLConnecter key: server">$( $CsmDBData.MetrControlDB.Server )</entry>
	<entry key="SQLConnectLib.SQLConnecter key: db">$( $CsmDBData.MetrControlDB.Database )</entry>
	<entry key="SQLConnectLib.SQLConnecter key: user">$( $CsmDBData.MetrControlDB.Login )</entry>
	<entry key="SQLConnectLib.SQLConnecter key: passwd">$( $CsmDBData.MetrControlDB.PasswordHash )</entry>
	<entry key="SQLConnectLib.SQLConnecter key: timeout">-1</entry>
	<entry key="SQLConnectLib.SQLConnecter key: ntauth">$( $CsmDBData.MetrControlDB.NTLM -eq 'yes' )</entry>
	<entry key="csmusers.frmUsers key: Default User ID: ">1</entry>
</entries>
"@

$Writer = [System.Xml.XmlWriter]::Create(
    $ConfigPath `
    , ( New-Object `
		-TypeName System.Xml.XmlWriterSettings `
		-Property @{
			Indent = $true;
			OmitXmlDeclaration = $false;
			NamespaceHandling = [System.Xml.NamespaceHandling]::OmitDuplicates;
			NewLineOnAttributes = $false;
			CloseOutput = $true;
			IndentChars = "`t";
		} `
	) `
);
$Config.WriteTo( $Writer );
$Writer.Close();

Add-Type `
    -Language CSharp `
    -TypeDefinition @"

namespace Microsoft.Deployment.WindowsInstaller {

using System;
using System.Text;
using System.Runtime.InteropServices;
using System.Diagnostics.CodeAnalysis;

public
class API {

public
enum
InstallMode : int {
    NoSourceResolution = -3,
    NoDetection        = -2,
    Existing           = -1,
    Default            = 0,
}

public
enum
Error : uint {
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
    , CharSet=CharSet.Unicode
    , SetLastError=false
)]
[return: MarshalAs(UnmanagedType.Error)] 
public
static
extern
Error
MsiProvideComponent(
    [In, MarshalAs(UnmanagedType.LPWStr)]      String Product,
    [In, MarshalAs(UnmanagedType.LPWStr)]      String Feature,
    [In, MarshalAs(UnmanagedType.LPWStr)]      String Component,
    [In, MarshalAs(UnmanagedType.U4)]          InstallMode Mode,
    [In, Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder Path,
    [In, Out, MarshalAs(UnmanagedType.U4)] ref uint cchPathBuf
);

}

}
"@

Function Provide-MsiComponent {
[CmdletBinding(
	ConfirmImpact = 'Medium',
	SupportsShouldProcess = $false
)]

    param (
        [System.Guid]
        [ValidateNotNull()]
        $ProductCode
    ,
        [String]
        [ValidateNotNullOrEmpty()]
        $Feature
    ,
        [System.Guid]
        [ValidateNotNull()]
        $ComponentCode
    )

    [System.Text.StringBuilder] $Path = New-Object -TypeName System.Text.StringBuilder -ArgumentList 1024;
    [uint] $PathBufSize = $Path.Capacity;

    [Microsoft.Deployment.WindowsInstaller.API+Error] $err = [Microsoft.Deployment.WindowsInstaller.API]::MsiProvideComponent(
        $ProductCode.ToString('B'), 
        $Feature,
        $ComponentCode.ToString('B'),
        [Microsoft.Deployment.WindowsInstaller.API+InstallMode]::Default,
        $Path,
        [ref] $PathBufSize
    );

    if ( $err -eq [Microsoft.Deployment.WindowsInstaller.API+Error]::MORE_DATA ) {
        $Path.Capacity = ++$PathBufSize;
        $err = [Microsoft.Deployment.WindowsInstaller.API]::MsiProvideComponent(
            $ProductCode.ToString('B'), 
            $Feature,
            $ComponentCode.ToString('B'),
            [Microsoft.Deployment.WindowsInstaller.API+InstallMode]::Default,
            $Path,
            [ref] $PathBufSize
        );
    };

    [System.Runtime.InteropServices.Marshal]::ThrowExceptionForHR( $err );
    return $Path.ToString();
}

$ToolsComponents = @{
    csmmain = @{
        Product = [GUID]'{89AC374A-B77C-4CD7-BD3E-580D726EFCD5}';
        Feature = 'csmmain';
        Component = [GUID]'{A8840BA1-D58E-4DAC-A867-2131F2CFE7B6}';
    };
    csmadmin = @{
        Product = [GUID]'{89AC374A-B77C-4CD7-BD3E-580D726EFCD5}';
        Feature = 'csmadmin';
        Component = [GUID]'{E5957298-538D-44F3-86B5-76D09E721E0E}';
    };
    markinv = @{
        Product = [GUID]'{89AC374A-B77C-4CD7-BD3E-580D726EFCD5}';
        Feature = 'markinv';
        Component = [GUID]'{787104E4-96B1-4D9E-A10D-B2D285A47E13}';
    };
}; 

$ToolPath = Provide-MsiComponent `
    -ProductCode ( $ToolsComponents.$CsmTool.Product ) `
    -Feature ( $ToolsComponents.$CsmTool.Feature ) `
    -Component ( $ToolsComponents.$CsmTool.Component ) `
;

if ( $ToolPath ) {
    Start-Process `
        -FilePath $ToolPath `
        -WindowStyle Normal `
    ;
} else {
    Throw "Приложение $ToolPath не установлено.";
};