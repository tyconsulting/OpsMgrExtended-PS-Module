Function Install-OpsMgrSDK
{
<# 
 .Synopsis
  Install OpsMgr SDK DLLs into Windows computer's Global Assembly Cache (GAC)

 .Description
  Install OpsMgr SDK DLLs into Windows computer's Global Assembly Cache (GAC) located in %windir%\Assembly folder. If all the DLLs have been loaded into the GAC, a boolean value $true will be returned, otherwise, a boolean value of $false is returned if any there are any errors occurred.
  
 .Parameter -Path
  Folder path to where the OpsMgr SDK DLL files are located.

 .Example
  # Install OpsMgr SDK DLLs from C:\Temp\SDK
  Install-OpsMgrSDK -Path C:\Temp\SDK

 .Example
  # Install OpsMgr SDK DLLs from the OpsMgrExtended module folder
  Install-OpsMgrSDK
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$false,HelpMessage='Please enter the folder path for OpsMgr SDK DLLs')][Alias('p')][String]$Path = $PSScriptRoot
    )

    If (!([AppDomain]::CurrentDomain.GetAssemblies() |Where-Object { $_.FullName -eq 'System.EnterpriseServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a' }))
    {
        Write-verbose 'Loading Assembly System.EnterpriseServices...'
        [System.Reflection.Assembly]::Load('System.EnterpriseServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a') | Out-Null
    }


    $arrDLLs = @()
    $arrDLLs += 'Microsoft.EnterpriseManagement.Core.dll'
    $arrDLLs += 'Microsoft.EnterpriseManagement.OperationsManager.dll'
    $arrDLLs += 'Microsoft.EnterpriseManagement.Runtime.dll'
    
    $AssemblyVersion = '7.0.5000.0'
    $MSPublicKeyToken = '31bf3856ad364e35'
    $bAllLoaded = $false
    #Check if all DLLs exist in the specified folder
    $bDLLsExist = $true
    Foreach ($DLL in $arrDLLs)
    {
        If (!(Test-Path (Join-Path $Path $DLL)))
        {
            Write-Error "'$DLL' does not exist in folder '$Path'!"
            Return
        }
    }
    
    #Checking Assembly properties before adding to GAC
    Foreach ($DLL in $arrDLLs)
    {
        $DLLPath = Join-Path $Path $DLL
        $DLLAssembly = [System.Reflection.Assembly]::LoadFile($DLLPath)

        
        $AssemblyName = $DLLAssembly.GetName()
        $AssemblyVersion = $AssemblyName.Version.ToString()
        #Version
        If ($AssemblyVersion -ne $AssemblyVersion)
        {
            Write-Error "Incorrect Assembly version detected in $DLL. Detected assembly version : $AssemblyVersion`, expected version: 7.0.5000.0. Please make sure the OpsMgr 2012 R2 SDK DLLs are used."
            Return $false
        }
        #Public Key Length
        $PKByteArray = $AssemblyName.GetPublicKeyToken()
        [string]$strPKToken = ''
        Foreach ($item in $PKByteArray)
        {
            $strPKToken = $strPKToken + ('{0:x0}' -f $item)
        }

        If ($strPKToken -ine $MSPublicKeyToken)
        {
            Write-Error "$DLL assembly public key token is not correct."
            Return $false
        }
    }

    #Load DLLs into GAC
    $PublishObject = New-Object System.EnterpriseServices.Internal.Publish
    $bAllLoaded = $true
    Foreach ($DLL in $arrDLLs)
    {
        $DLLPath = Join-Path $Path $DLL
        $DLLAssembly = [System.Reflection.Assembly]::LoadFile($DLLPath)
        Try {
            Write-verbose "Adding $DLLPath to GAC..."
            $PublishObject.GacInstall($DLLPath)

        } Catch {
            $bAllLoaded = $false
        }
    }

    $bAllLoaded
}

Function Import-OpsMgrSDK
{
<# 
 .Synopsis
  Load OpsMgr 2012 SDK DLLs

 .Description
  Load OpsMgr 2012 SDK DLLs from either the Global Assembly Cache or from the DLLs located in OpsMgrSDK PS module directory. It will use GAC if the DLLs are already loaded in GAC. If all the DLLs have been loaded, a boolean value $true will be returned, otherwise, a boolean value of $false is returned if any there are any errors occurred.

 .Example
  # Load the OpsMgr SDK DLLs
  Import-SDK

#>
    #OpsMgr 2012 R2 SDK DLLs
    $arrDLLs = @()
    $arrDLLs += 'Microsoft.EnterpriseManagement.Core.dll'
    $arrDLLs += 'Microsoft.EnterpriseManagement.OperationsManager.dll'
    $arrDLLs += 'Microsoft.EnterpriseManagement.Runtime.dll'
    $DLLVersion = '7.0.5000.0'
    $PublicKeyToken='31bf3856ad364e35'

    #Load SDKs
    $bSDKLoaded = $true
    Foreach ($DLL in $arrDLLs)
    {
        $AssemblyName = $DLL.TrimEnd('.dll')
        #try load from GAC first
        Try {
            Write-Verbose "Trying to load $AssemblyName from GAC..."
            [Void][System.Reflection.Assembly]::Load("$AssemblyName, Version=$DLLVersion, Culture=neutral, PublicKeyToken=$PublicKeyToken")
        } Catch {
            Write-Verbose "Unable to load $AssemblyName from GAC. Trying PowerShell module base folder..."
            #Can't load from GAC, now try PS module folder
            Try {
                $DLLFilePath = Join-Path $PSScriptRoot $DLL
                [Void][System.Reflection.Assembly]::LoadFrom($DLLFilePath)
            } Catch {
                Write-Verbose "Unable to load $DLL from either GAC or the OpsMgrExtended Powershell Module base folder. Please verify if the SDK DLLs exist in at least one location!"
                $bSDKLoaded = $false
            }
        }
    }
    $bSDKLoaded
}

Function Connect-OMManagementGroup
{
<# 
 .Synopsis
  Connect to OpsMgr Management Group using SDK

 .Description
  Connect to OpsMgr Management Group Data Access Service using SDK

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name.

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

  .Parameter -DLLPath
  Optionally, specify an alternative path to the OpsMgr SDK DLLs if they have not been installed in GAC.

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01"
  Connect-OMManagementGroup -SDK "OpsMgrMS01"

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" using different credential
  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  $MG = Connect-OMManagementGroup -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" using current user's credential
  $MG = Connect-OMManagementGroup -SDK "OpsMgrMS01"
  OR
  $MG = Connect-OMManagementGroup -Server "OPSMGRMS01"

 .Example
  # Connect to OpsMgr management group using the SMA connection "OpsMgrSDK_TYANG"
  $SDKCOnnection = Get-AutomationConnection "OpsMgrSDK_TYANG"
  $MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null
    )
	If ($SDKConnection)
	{
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password = ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	}
    #Check User name and password parameter
    If ($Username)
    {
        If (!$Password)
        {
            Write-Error "Password for user name $Username must be specified!"
			Return $null
        }
    }

    #Try Loadings SDK DLLs in case they haven't been loaded already
    $bSDKLoaded = Import-OpsMgrSDK

    #Connect to the management group
    if ($bSDKLoaded)
    {
        $MGConnSetting = New-Object Microsoft.EnterpriseManagement.ManagementGroupConnectionSettings($SDK)
        If ($Username -and $Password)
        {
            $MGConnSetting.UserName = $Username
            $MGConnSetting.Password = $Password
        }
        $MG = New-Object Microsoft.EnterpriseManagement.ManagementGroup($MGConnSetting)
    }
    $MG
}

#load the OpsMgrExnteded.Types Assemblies
If (!([AppDomain]::CurrentDomain.GetAssemblies() |Where-Object { $_.FullName -eq 'OpsMgrExtended.Types, Version=1.0.0.0, Culture=neutral, PublicKeyToken=23140eab7fb5cf37' }))
{
    $OpsMgrExtendedTypesDLLPath = Join-Path $PSScriptRoot "OpsMgrExtended.Types.Dll"
    Add-Type -Path $OpsMgrExtendedTypesDLLPath
}