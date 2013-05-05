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
		Position=0
	)]
	[System.IO.FileInfo]
    [ValidateNotNullOrEmpty()]
	$CsmDB
,
	# Инструмент АИС Метроконтроль, который требуется запустить для указанной базы данных.
	[Parameter(
	)]
	[String]
    [ValidateSet( 'CsmMain', 'CsmAdmin', 'MarkInv' )]
	$CsmTool = 'CsmMain'
)

# $CsmDB = "X:\AMF\DSL\RCN\Metrcontrol\02.03.0000.0000\Prj\Metrocontrol\.csmdb examples\ncsm.csmdb23";

function Get-IniContent {
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

$Shell = New-Object -ComObject Shell.Application;
$ShellFolder = $Shell.NameSpace( [System.IO.Path]::GetDirectoryName( $CsmDB ) );
$ShellFile = $ShellFolder.ParseName( [System.IO.Path]::GetFileName( $CsmDB ) );
$ShellFile.Verbs()

(
    New-Object -ComObject Shell.Application
).NameSpace(
    [System.IO.Path]::GetDirectoryName( $CsmDB )
).ParseName(
    [System.IO.Path]::GetFileName( $CsmDB )
).InvokeVerb( $CsmTool );

