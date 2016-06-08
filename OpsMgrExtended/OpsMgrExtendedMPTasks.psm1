Function Get-OMManagementPack
{
<# 
 .Synopsis
  Get a particular management pack by name or get all management pack in an OpsMgr management group.

 .Description
  Get a particular management pack by providing the managemnet pack name or get all management pack in an OpsMgr management group using OpsMgr SDK. A Microsoft.EnterpriseManagement.Configuration.ManagementPack object is returned if a management pack is retrieved and an array is returned when retriving all management packs. Otherwise, a NULL value is returned if no management packs are not found.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -Name
  Management Pack name
 
 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then get the management pack "TYANG.Lab.Test":
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Name: "TYANG.Lab.Test"

   $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
   $MP = Get-OMManagementPack -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -Name "TYANG.Lab.Test"

 .Example
  # Connect to OpsMgr management group using the SMA connection "OpsMgrSDK_TYANG" and get the management pack "TYANG.Lab.Test":

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  $MP = Get-OMManagementPack -SDKConnection $SDKConnection -Name "TYANG.Lab.Test"

 .Example
  # Connect to OpsMgr management group using the SMA connection "OpsMgrSDK_TYANG" and get all management packs:

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  $MPs = Get-OMManagementPack -SDKConnection $SDKConnection
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$false,HelpMessage='Please enter management pack name')][String]$Name = $null
    )

    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

	if ($Name)
	{
		$strMPquery = "Name = '$Name'"
		$mpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strMPquery)
		$MP = $MG.GetManagementPacks($mpCriteria)[0]
		if ($MP)
		{
			$MPVersion = $MP.Version
			If ($MP.Sealed)
			{
				Write-verbose "Sealed Management pack `"$Name`" found. Version: $MPVersion."
			} else {
				Write-verbose "Unsealed Management pack `"$Name`" found. Version: $MPVersion."
			}
		} else {
			Write-Error "Unable to find the management pack with name `"$Name`"."
		}
		$MP
	} else {
		$MPs = $MG.GetManagementPacks()
		$MPCount = $MPs.Count
		Write-Verbose "There are totally $MPCount management packs in the management group."
		$MPs
	}
}

Function New-OMManagementPack
{
<# 
 .Synopsis
  Create a new unsealed management pack in an OpsMgr management group.

 .Description
  Create a new unsealed management pack in an OpsMgr management group using OpsMgr SDK. A boolean value $true will be returned if the MP creation has been successful, otherwise, a boolean value of $false is returned if any there are any errors occurred during the creation process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -Name
  Management Pack name

 .Parameter -DisplayName
  Management Pack display name

 .Parameter -Description
  Management Pack description

 .Parameter -Version
  Management Pack version

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create an unsealed management pack with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Name: "TYANG.Lab.Test"
   DisplayName: "TYANG Lab Test"
   Version: 1.0.0.0 (default version number)

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  $MPCreated = New-OMManagementPack -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -Name "TYANG.Lab.Test" -DisplayName "TYANG Lab Test"

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create an unsealed management pack with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Name: "TYANG.Lab.Test"
   DisplayName: "TYANG Lab Test"
   Description "Test Managemnet Pack Description"
   Version: 0.0.0.1

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  $MPCreated = New-OMManagementPack -SDKConnection $SDKConnection -Name "TYANG.Lab.Test" -DisplayName "TYANG Lab Test" -Description "Test Managemnet Pack Description" -Version "0.0.0.1"
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')][String]$Name,
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack display name')][String]$DisplayName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter management pack description')][String]$Description,
        [Parameter(Mandatory=$false,HelpMessage='Please enter management pack version')][System.Version]$Version="1.0.0.0"
    )

    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    $mpStore = New-Object Microsoft.EnterpriseManagement.Configuration.IO.ManagementPackFileStore
    $mp = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPack($Name, $DisplayName, $version, $mpStore)
    $mp.DefaultLanguageCode = 'ENU'
    $mpDefaultLanCode = $MP.DefaultLanguageCode
    $LanguagePack = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackLanguagePack($mp, $mpDefaultLanCode)
    $DisplayString = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDisplayString($mp, $mpDefaultLanCode)
    $Displaystring.Name = $DisplayName
    if ($Description)
    {
        $Displaystring.Description = $Description
    }

	#Add reference to Microsoft.SystemCenter.Library
	Write-Verbose "Adding reference for 'Microsoft.SystemCenter.Library'`..."
    $RefmpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name = 'Microsoft.SystemCenter.Library' AND Sealed = 'TRUE'")
    $RefMP = $MG.GetManagementPacks($RefmpCriteria)[0]
	If (!$RefMP)
    {
        Write-Error "Unable to find the Reference Sealed MP with the name '$ReferenceMPName'."
        Return $false
    } else {
        $RefMPVersion = $RefMP.Version
        $RefMPKeyToken = $RefMP.KeyToken
		Write-Verbose "MP 'Microsoft.SystemCenter.Library' Key Token: $RefMPKeyToken"
		Write-Verbose "MP 'Microsoft.SystemCenter.Library' Version: $RefMPVersion"
    }
    $objMPRef = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackReference($RefMP)
	$mp.References.Add('SystemCenter', $objMPRef)

	#Save the MP
	Write-Verbose "Saving MP $Name"
    Try {
        $mp.verify()
		$mp.acceptchanges()
        $MG.ImportManagementPack($mp)
        $Result = $true
		Write-Verbose "Management Pack $Name successfully created."
    } Catch {
        $Result = $false
		$mp.RejectChanges()
		Write-Error "Failed to create Management Pack $Name."
    }
    $Result
}

Function Remove-OMManagementPack
{
<# 
 .Synopsis
  Remove a management pack from an OpsMgr management group.

 .Description
  Remove a management pack from an OpsMgr management group using OpsMgr SDK. A boolean value $true will be returned if the MP removal has been successful, otherwise, a boolean value of $false is returned if any there are any errors occurred during the removal process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -Name
  Management Pack name

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then remove a management pack with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Name: "TYANG.Lab.Test"

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  $MPRemoved = Remove-OMManagementPack -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -Name "TYANG.Lab.Test"

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then remove a management pack with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Name: "TYANG.Lab.Test"

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  $MPRemoved = Remove-OMManagementPack -SDKConnection $SDKConnection -Name "TYANG.Lab.Test"
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')][String]$Name
    )

    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

	Write-Verbose "Getting manamgement pack `"$Name`"."
    $strMPquery = "Name = '$Name'"
	$mpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strMPquery)
	$MP = $MG.GetManagementPacks($mpCriteria)[0]
	if (!$MP)
	{
		Write-Error "Unable to find the management pack with name `"$Name`"."
		Return $false
	} else {
		$MPVersion = $MP.Version
		If ($MP.Sealed)
		{
			Write-verbose "Sealed Management pack `"$Name`" found. Version: $MPVersion."
		} else {
			Write-verbose "Unsealed Management pack `"$Name`" found. Version: $MPVersion."
		}
	}

	#Save the MP
	Write-Verbose "Deleting management pack `"$Name`" from management group now."
    Try {
       $MG.UninstallManagementPack($MP)
        $Result = $true
		Write-Verbose "Management Pack $Name successfully deleted."
    } Catch {
        $Result = $false
		Write-Error $_.Exception
		Write-Error "Failed to delete Management Pack $Name."
    }
    $Result
}

Function New-OM2StateEventMonitor
{
<# 
 .Synopsis
  Create a 2-state event monitor in OpsMgr.

 .Description
  Create a 2-state event monitor in OpsMgr using OpsMgr SDK. A boolean value $true will be returned if the moniotr creation has been successful, otherwise, a boolean value of $false is returned if any there are any errors occurred during the creation process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -MPName
  Name for the unsealed MP of which the monitor is going to stored.

 .Parameter -MonitorName
  Monitor name

 .Parameter -MonitorDisplayName
  Monitor Display Name

 .Parameter -ClassName
  Monitoring Class Name

 .Parameter -ParentMonitor
  The Parent aggregate monitor. Possible Values: Availability, Performance, Configuration, Security.

 .Parameter -EventLog
  The name of the event log where the log entry is generated. i.e. System, Application or Security.

 .Parameter -Publisher
  The publisher / provider of the event log entry. This value can be obtained by going to the XML view in the Details tab in Event viewer, and this value is the Provider Name value.

 .Parameter -UnhealthyEventID
  The event ID that makes the monitor unhealthy.

 .Parameter -HealthyEventID
  The event ID that makes the monitor healthy.

 .Parameter -UnhealthyState
  Specify the unhealthy state of the monitor. Possible Values: Warning, Error.

 .Parameter -Disabled
  Specify if the monitor is disabled by default.

 .Parameter -IncreaseMPVersion
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a 2-state event monitor with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Management Pack Name: "TYANG.Lab.Test"
   Monitor Name: "Test.2State.Event.Monitor"
   Monitor Display Name: "Test 2State Event Monitor"
   Monitoring Class name: "Microsoft.Windows.Server.OperatingSystem"
   Parent Monitor: Availability
   Event Log: Application
   Publisher: WSH
   Unhealthy Event ID: 2
   Healthy Event ID: 4
   Unhealthy State: Warning
  
  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  New-OM2StateEventMonitor -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -MPName "TYANG.Lab.Test" -MonitorName "Test.2State.Event.Monitor" -MonitorDisplayName "Test 2State Event Monitor" -ClassName "Microsoft.Windows.Server.OperatingSystem" -ParentMonitor "Availability" -EventLog "Application" -Publisher "WSH" -UnhealthyEventID 2 -HealthyEventID 4 -UnhealthyState "Warning"

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a 2-state event monitor with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Management Pack Name: "TYANG.Lab.Test"
   Monitor Name: "Test.2State.Event.Monitor"
   Monitor Display Name: "Test 2State Event Monitor"
   Monitoring Class name: "Microsoft.Windows.Server.OperatingSystem"
   Parent Monitor: Availability
   Event Log: Application
   Publisher: WSH
   Unhealthy Event ID: 2
   Healthy Event ID: 4
   Unhealthy State: Error
   Disabled by default
   Increase Management Pack version by 0.0.0.1

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  New-OM2StateEventMonitor -SDKConnection $SDKConnection -MPName "TYANG.Lab.Test" -MonitorName "Test.2State.Event.Monitor" -MonitorDisplayName "Test 2State Event Monitor" -ClassName "Microsoft.Windows.Server.OperatingSystem" -ParentMonitor "Availability" -EventLog "Application" -Publisher "WSH" -UnhealthyEventID 2 -HealthyEventID 4 -UnhealthyState "Error" -Disabled $true -IncreaseMPVersion $true
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')][String]$MPName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter monitor name')][String]$MonitorName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter monitor display name')][String]$MonitorDisplayName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter monitoring class name')][String]$ClassName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Parent monitor')][ValidateSet('Availability', 'Performance', 'Configuration', 'Security')][Alias('parent')][String]$ParentMonitor,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Event Log Name')][Alias('log')][String]$EventLog,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Event Log Publisher Name')][String]$Publisher,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Unhealthy Event ID')][Int32]$UnhealthyEventID,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Healthy Event ID')][Int32]$HealthyEventID,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Monitor Unhealthy State')][ValidateSet('Warning', 'Error')][String]$UnhealthyState,
		[Parameter(Mandatory=$false,HelpMessage='Please specify if the monitor is disabled by default')][Boolean]$Disabled = $false,
        [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')][Boolean]$IncreaseMPVersion = $false

    )
    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the unsealed MP
    $strMPquery = "Name = '$MPName'"
    $mpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strMPquery)
    $MP = $MG.GetManagementPacks($mpCriteria)[0]

    If ($MP)
    {
        #MP found, now check if it is sealed
        If ($MP.sealed)
        {
            Write-Error 'Unable to save to the management pack specified. It is sealed. Please specify an unsealed MP.'
            return $false
        }
    } else {
        Write-Error 'The management pack specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

    #Get the monitoring Class
    $strMCQuery = "Name = '$ClassName'"
    $mcCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria($strMCQuery)
    $MonitoringClass = $MG.GetMonitoringClasses($mcCriteria)[0]
    if (!$MonitoringClass)
    {
        Write-Error 'The monitoring class specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

    #Get the monitor type
    $strMTquery = "Name = 'Microsoft.Windows.2SingleEventLog2StateMonitorType'"
    $MTCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorTypeCriteria($strMTquery)
    $MonitorType = $MG.GetUnitMonitorTypes($MTCriteria)[0]

    #Create new monitor
	If ($Disabled -eq $true)
	{
		$EnabledProperty = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::false
	} else {
		$EnabledProperty = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
	}
    $newMonitor = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitor($mp, $MonitorName, [Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Public)
    $newMonitor.DisplayName = $MonitorDisplayName
	$newMonitor.Enabled = $EnabledProperty
    $newMonitor.TypeID = $MonitorType
    $newMonitor.Target = $MonitoringClass

    #Set Parent monitor
    $strParentMonitorQuery = "Name ='System.Health.$ParentMonitor"+"State'"
    $ParentMonitorCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitorCriteria($strParentMonitorQuery)
    $objParentMonitor = $MG.GetMonitors($ParentMonitorCriteria)[0]
    $newMonitor.ParentMonitorID = $objParentMonitor

	#Monitor category
	$MonitorCategory = $ParentMonitor + "Health"
	$newMonitor.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::$MonitorCategory

    #monitor configuration
    $newMonitor.Remotable = $false
    $MonitorConfig = @"
<FirstComputerName/>
          <FirstLogName>$EventLog</FirstLogName>
          <FirstExpression>
            <And>
              <Expression>
                <SimpleExpression>
                  <ValueExpression>
                    <XPathQuery Type="UnsignedInteger">EventDisplayNumber</XPathQuery>
                  </ValueExpression>
                  <Operator>Equal</Operator>
                  <ValueExpression>
                    <Value Type="UnsignedInteger">$UnhealthyEventID</Value>
                  </ValueExpression>
                </SimpleExpression>
              </Expression>
              <Expression>
                <SimpleExpression>
                  <ValueExpression>
                    <XPathQuery Type="String">PublisherName</XPathQuery>
                  </ValueExpression>
                  <Operator>Equal</Operator>
                  <ValueExpression>
                    <Value Type="String">$Publisher</Value>
                  </ValueExpression>
                </SimpleExpression>
              </Expression>
            </And>
          </FirstExpression>
          <SecondComputerName/>
          <SecondLogName>$EventLog</SecondLogName>
          <SecondExpression>
            <And>
              <Expression>
                <SimpleExpression>
                  <ValueExpression>
                    <XPathQuery Type="UnsignedInteger">EventDisplayNumber</XPathQuery>
                  </ValueExpression>
                  <Operator>Equal</Operator>
                  <ValueExpression>
                    <Value Type="UnsignedInteger">$HealthyEventID</Value>
                  </ValueExpression>
                </SimpleExpression>
              </Expression>
              <Expression>
                <SimpleExpression>
                  <ValueExpression>
                    <XPathQuery Type="String">PublisherName</XPathQuery>
                  </ValueExpression>
                  <Operator>Equal</Operator>
                  <ValueExpression>
                    <Value Type="String">$Publisher</Value>
                  </ValueExpression>
                </SimpleExpression>
              </Expression>
            </And>
          </SecondExpression>
"@
    $newMonitor.Configuration= $MonitorConfig

    #Configure Health State
    $strUnhealthyStateIndetifier = 'EventLogMonitor'+$UnhealthyState+'State'
    $objHealthyState = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($newMonitor, 'EventLogMonitorHealthyState')
    $objUnhealthyState = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($newMonitor, $strUnhealthyStateIndetifier)
    $objHealthyState.HealthState = 'Success'
    $objHealthyState.MonitorTypeStateID = 'SecondEventRaised'
    $objUnhealthyState.HealthState = $UnhealthyState
    $objUnhealthyState.MonitorTypeStateID = 'FirstEventRaised'
    $newMonitor.OperationalStateCollection.Add($objHealthyState)
    $newMonitor.OperationalStateCollection.Add($objUnhealthyState)

    #Configure Alert Settings
    $newMonitor.AlertSettings = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorAlertSettings
    $newMonitor.AlertSettings.AlertOnState = $UnhealthyState
    $newMonitor.AlertSettings.AutoResolve = $true
    $newMonitor.AlertSettings.AlertPriority = 'Normal'
    $newMonitor.AlertSettings.AlertSeverity = $UnhealthyState
    $AlertStringResourceID = $MonitorName+'.AlertMessage'
    $AlertParameter1 = "`$Data/Context/EventDescription`$"
    $newMonitor.AlertSettings.AlertParameter1 = $AlertParameter1
    $AlertMessage = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackStringResource($MP, $AlertStringResourceID)
    $AlertMessage.DisplayName = "$MonitorDisplayName Alert"
    $AlertMessage.Description = '{0}'
    $newMonitor.AlertSettings.AlertMessage = $AlertMessage

    #Increase MP version
    If ($IncreaseMPVersion)
    {
        $CurrentVersion = $MP.Version.Tostring()
        $vIncrement = $CurrentVersion.Split('.')
        $vIncrement[$vIncrement.Length - 1] = ([System.Int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
        $NewVersion = ([System.String]::Join('.', $vIncrement))
        $MP.Version = $NewVersion
    }

    #Verify and save the monitor
    Try {
        $MP.verify()
        $MP.AcceptChanges()
        $Result = $true
		Write-Verbose "2-State Event Monitor '$MonitorName' successfully created in Management Pack '$MPName'($($MP.Version))."
    } Catch {
        $Result = $false
		$MP.RejectChanges()
        Write-Error "Unable to create 2-State Event monitor $MonitorName in management pack $MPName."
    }
    $Result
}

Function New-OMServiceMonitor
{
<# 
 .Synopsis
  Create a Windows service monitor in OpsMgr.

 .Description
  Create a Windows service monitor in OpsMgr using OpsMgr SDK. A boolean value $true will be returned if the monitor creation has been successful, otherwise, a boolean value of $false is returned if any there are any errors occurred during the creation process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -MPName
  Name for the unsealed MP of which the monitor is going to stored.

 .Parameter -MonitorName
  Monitor name

 .Parameter -MonitorDisplayName
  Monitor Display Name

 .Parameter -ClassName
  Monitoring Class Name. Please note this parameter accepts the monitoring class name, not the display name.

 .Parameter -ParentMonitor
  The Parent aggregate monitor. Possible Values: Availability, Performance, Configuration, Security.

 .Parameter -ServiceName
  The name of the service that needs to be monitored. Please specify the service name, not the display name.

 .Parameter -IgnoreStartupType 
  By default, the service monitor only alert when the startup type is set to Automatic. Set this parameter to true to ignore the startup type. i.e. Alerting when the service is disabled.

 .Parameter -UnhealthyWhenRunning
  By default, the service monitor is configured in a way that it becomes unhealthy when the service is not running. Set this parameter to true if you'd like to monitor to be configured in a reverse way (unhealthy when the service is running).

 .Parameter -UnhealthyState
  Specify the unhealthy state of the monitor. Possible Values: Warning, Error.

 .Parameter -Disabled
  Specify if the monitor is disabled by default.

 .Parameter -IncreaseMPVersion
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a service monitor with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Management Pack Name: "TYANG.Lab.Test"
   Monitor Name: "Test.Windows.Time.Service.Monitor"
   Monitor Display Name: "Test Windows Time Service Monitor"
   Monitoring Class name: "Microsoft.Windows.Server.OperatingSystem"
   Parent Monitor: Availability
   Service Name: w32time
   Unhealthy State: Error
  
  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  New-OMServiceMonitor -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -MPName "TYANG.Lab.Test" -MonitorName "Test.Windows.Time.Service.Monitor" -MonitorDisplayName "Test Windows Time Service Monitor" -ClassName "Microsoft.Windows.Server.OperatingSystem" -ParentMonitor "Availability" -ServiceName "w32time" -UnhealthyState "Error"

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a service monitor with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Management Pack Name: "TYANG.Lab.Test"
   Monitor Name: "Test.Windows.Time.Service.Monitor"
   Monitor Display Name: "Test Windows Time Service Monitor"
   Monitoring Class name: "Microsoft.Windows.Server.OperatingSystem"
   Parent Monitor: Availability
   Service Name: w32time
   Ignore Service Start Type
   Monitor Unhealthy when service is running
   Unhealthy State: Warning
   Disabled by default
   Increase Management Pack version by 0.0.0.1

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  New-OMServiceMonitor -SDKConnection $SDKConnection -MPName "TYANG.Lab.Test" -MonitorName "Test.Windows.Time.Service.Monitor" -MonitorDisplayName "Test Windows Time Service Monitor" -ClassName "Microsoft.Windows.Server.OperatingSystem" -ParentMonitor "Availability" -ServiceName "w32time" -IgnoreStartupType $true -UnhealthyWhenRunning $true -UnhealthyState "Warning" -Disabled $true  -IncreaseMPVersion $true

#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')][String]$MPName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter monitor name')][String]$MonitorName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter monitor display name')][String]$MonitorDisplayName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter monitoring class name')][String]$ClassName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Parent monitor')][ValidateSet('Availability', 'Performance', 'Configuration', 'Security')][Alias('parent')][String]$ParentMonitor,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Service Name')][Alias('Service')][String]$ServiceName,
        [Parameter(Mandatory=$false,HelpMessage='Ignore Service Start Type')][Boolean]$IgnoreStartupType = $false,
        [Parameter(Mandatory=$false,HelpMessage='Monitor becomes unhealthy when the service IS running')][Boolean]$UnhealthyWhenRunning = $false,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Monitor Unhealthy State')][ValidateSet('Warning', 'Error')][String]$UnhealthyState,
		[Parameter(Mandatory=$false,HelpMessage='Please specify if the monitor is disabled by default')][Boolean]$Disabled = $false,
        [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')][Boolean]$IncreaseMPVersion = $false
    )
    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the unsealed MP
    $strMPquery = "Name = '$MPName'"
    $mpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strMPquery)
    $MP = $MG.GetManagementPacks($mpCriteria)[0]

    If ($MP)
    {
        #MP found, now check if it is sealed
        If ($MP.sealed)
        {
            Write-Error 'Unable to save to the management pack specified. It is sealed. Please specify an unsealed MP.'
            return $false
        }
    } else {
        Write-Error 'The management pack specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

    #Get the monitoring Class
    $strMCQuery = "Name = '$ClassName'"
    $mcCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria($strMCQuery)
    $MonitoringClass = $MG.GetMonitoringClasses($mcCriteria)[0]
    if (!$MonitoringClass)
    {
        Write-Error 'The monitoring class specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

    #Get the monitor type
    $strMTquery = "Name = 'Microsoft.Windows.CheckNTServiceStateMonitorType'"
    $MTCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorTypeCriteria($strMTquery)
    $MonitorType = $MG.GetUnitMonitorTypes($MTCriteria)[0]

    #Create new monitor
	If ($Disabled -eq $true)
	{
		$EnabledProperty = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::false
	} else {
		$EnabledProperty = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
	}
    $newMonitor = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitor($mp, $MonitorName, [Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Internal)
    $newMonitor.DisplayName = $MonitorDisplayName
    $newMonitor.TypeID = $MonitorType
	$newMonitor.Enabled = $EnabledProperty
    $newMonitor.Target = $MonitoringClass

    #Set Parent monitor
    $strParentMonitorQuery = "Name ='System.Health.$ParentMonitor"+"State'"
    $ParentMonitorCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitorCriteria($strParentMonitorQuery)
    $objParentMonitor = $MG.GetMonitors($ParentMonitorCriteria)[0]
    $newMonitor.ParentMonitorID = $objParentMonitor

	#Monitor category
	$MonitorCategory = $ParentMonitor + "Health"
	$newMonitor.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::$MonitorCategory
    #monitor configuration
    $newMonitor.Remotable = $false
    
    If ($IgnoreStartupType)
    {
        $bCheckStartupType = $false
    } else {
        $bCheckStartupType = $true
    }

    $MonitorConfig = @"
<ComputerName />
<ServiceName>$ServiceName</ServiceName>
<CheckStartupType>$bCheckStartupType</CheckStartupType>
"@
    $newMonitor.Configuration= $MonitorConfig

    #Configure Health State
    $objSvcRunningState = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($newMonitor, 'Running')
    $objSvcRunningState.MonitorTypeStateID = 'Running'
    $objSvcRunningState.DisplayName = 'Running'
    $objSvcRunningState.Description = 'Running'

    $objSvcNotRunningState = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($newMonitor, 'NotRunning')
    $objSvcNotRunningState.MonitorTypeStateID = 'NotRunning'
    $objSvcNotRunningState.DisplayName = 'NotRunning'
    $objSvcNotRunningState.Description = 'NotRunning'

    If ($UnhealthyWhenRunning)
    {        
        #Running = unhealthy
        $objSvcRunningState.HealthState = $UnhealthyState
        $objSvcNotRunningState.HealthState = 'Success'
    } else {
        #Running = healthy
        $objSvcRunningState.HealthState = 'Success'
        $objSvcNotRunningState.HealthState = $UnhealthyState
    }
    $newMonitor.OperationalStateCollection.Add($objSvcRunningState)
    $newMonitor.OperationalStateCollection.Add($objSvcNotRunningState)

    #Configure Alert Settings
    $newMonitor.AlertSettings = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorAlertSettings
    $newMonitor.AlertSettings.AlertOnState = $UnhealthyState
    $newMonitor.AlertSettings.AutoResolve = $true
    $newMonitor.AlertSettings.AlertPriority = 'Normal'
    $newMonitor.AlertSettings.AlertSeverity = $UnhealthyState
    $AlertStringResourceID = $MonitorName+'.AlertMessage'
    $AlertParameter1 = "`$Data/Context/Property[@Name='DisplayName']`$"
    $newMonitor.AlertSettings.AlertParameter1 = $AlertParameter1
    $AlertMessage = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackStringResource($MP, $AlertStringResourceID)
    $AlertMessage.DisplayName = "$MonitorDisplayName Alert"
    If ($UnhealthyWhenRunning)
    {
        $AlertMessage.Description = "The '{0}' service is currently running."
    } else {
        $AlertMessage.Description = "The '{0}' service is not running."
    }
    $newMonitor.AlertSettings.AlertMessage = $AlertMessage

    #Increase MP version
    If ($IncreaseMPVersion)
    {
        $CurrentVersion = $MP.Version.Tostring()
        $vIncrement = $CurrentVersion.Split('.')
        $vIncrement[$vIncrement.Length - 1] = ([System.Int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
        $NewVersion = ([System.String]::Join('.', $vIncrement))
        $MP.Version = $NewVersion
    }

    #Verify and save the monitor
    Try {
        $MP.verify()
        $MP.AcceptChanges()
        $Result = $true
		Write-Verbose "Service Monitor '$MonitorName' successfully created in Management Pack '$MPName'($($MP.Version))."
    } Catch {
        $Result = $false
		$MP.RejectChanges()
        Write-Error "Unable to create service monitor $MonitorName in management pack $MPName."
    }
    $Result
}

Function New-OM2StatePerformanceMonitor
{
<# 
 .Synopsis
  Create a 2-state performance monitor in OpsMgr.

 .Description
  Create a 2-state performance monitor in OpsMgr using OpsMgr SDK. A boolean value $true will be returned if the monitor creation has been successful, otherwise, a boolean value of $false is returned if any there are any errors occurred during the creation process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -MPName
  Name for the unsealed MP of which the monitor is going to stored.

 .Parameter -MonitorName
  Monitor name

 .Parameter -MonitorDisplayName
  Monitor Display Name

 .Parameter -ClassName
  Monitoring Class Name

 .Parameter -ParentMonitor
  The Parent aggregate monitor. Possible Values: Availability, Performance, Configuration, Security. If it is not specified, it would be defaulted to "Performance"

 .Parameter -CounterName
  The name of the performance counter. i.e. "% Processor Time".

 .Parameter -ObjectName
  The name of the performance Object. i.e. "Processor".

 .Parameter -InstanceName
  The name of the instance. i.e. "_Total". If this parameter is not selected, all instances for the specified counter will be included.

 .Parameter -Threshold
  Threshold Value. i.e. 70

 .Parameter -UnhealthyWhenUnder
  By default, the monitor becomes unhealthy when over the threshold. Set -UnhealthyWhenUnder parameter to true when you want to configure the monitor to become unhealthy when the performance reading is UNDER threshold.

 .Parameter -Frequency
  Specify how often (in seconds) does the monitor run. i.e. 900 (15 minutes) 

 .Parameter -Disabled
  Specify if the monitor is disabled by default.

 .Parameter -IncreaseMPVersion
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a 2-state performance monitor with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Management Pack Name: "TYANG.Lab.Test"
   Monitor Name: "Test.2State.Performance.Monitor"
   Monitor Display Name: "Test 2State Performance Monitor"
   Monitoring Class name: "Microsoft.Windows.Server.OperatingSystem"
   Parent Monitor: Performance
   Counter Name: "% Processor Time"
   Object Name: "Processor"
   Instance Name: "_Total"
   Threshold: 70
   Frequency: 900 seconds (15 minutes)
   Monitor unhealthy state: Warning

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  New-OM2StatePerformanceMonitor -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -MPName "TYANG.Lab.Test" -MonitorName "Test.2State.Performance.Monitor" -MonitorDisplayName "Test 2State Performance Monitor" -ClassName "Microsoft.Windows.Server.OperatingSystem" -CounterName "% Processor Time" -ObjectName "Processor" -InstanceName "_Total" -Threshold 70 -Frequency 900 -UnhealthyState "Warning"

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a 2-state performance monitor with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Management Pack Name: "TYANG.Lab.Test"
   Monitor Name: "Test.2State.Performance.Monitor"
   Monitor Display Name: "Test 2State Performance Monitor"
   Monitoring Class name: "Microsoft.Windows.Server.OperatingSystem"
   Parent Monitor: Performance
   Counter Name: "% Processor Time"
   Object Name: "Processor"
   Select All Instances
   Threshold: 70
   Monitor becomes unhealthy when below threshold
   Frequency: 900 seconds (15 minutes)
   Monitor unhealthy state: Error
   Disabled by default
   Increase Management Pack version by 0.0.0.1

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  New-OM2StatePerformanceMonitor -SDKConnection $SDKConnection -MPName "TYANG.Lab.Test" -MonitorName "Test.2State.Performance.Monitor" -MonitorDisplayName "Test 2State Performance Monitor" -ClassName "Microsoft.Windows.Server.OperatingSystem" -CounterName "% Processor Time" -ObjectName "Processor" -Threshold 70 -UnhealthyWhenUnder $true -Frequency 900 -UnhealthyState "Error" -Disabled $true -IncreaseMPVersion $true

#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')][String]$MPName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter monitor name')][String]$MonitorName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter monitor display name')][String]$MonitorDisplayName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter monitoring class name')][String]$ClassName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter Parent monitor')][ValidateSet('Availability', 'Performance', 'Configuration', 'Security')][Alias('parent')][String]$ParentMonitor = 'Performance',
        [Parameter(Mandatory=$true,HelpMessage='Please enter Counter Name')][Alias('Counter')][String]$CounterName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Object name')][Alias('Object')][String]$ObjectName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter Instance Name')][Alias('Instance')][String]$Instancename,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the threshold')][Int32]$Threshold,
        [Parameter(Mandatory=$false,HelpMessage='Monitor becomes unhealthy when the performance reading is under the threshold')][Boolean]$UnhealthyWhenUnder = $false,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the frequency')][Int32]$Frequency,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Monitor Unhealthy State')][ValidateSet('Warning', 'Error')][String]$UnhealthyState,
		[Parameter(Mandatory=$false,HelpMessage='Please specify if the monitor is disabled by default')][Boolean]$Disabled = $false,
        [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')][Boolean]$IncreaseMPVersion = $false

    )
    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the unsealed MP
    $strMPquery = "Name = '$MPName'"
    $mpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strMPquery)
    $MP = $MG.GetManagementPacks($mpCriteria)[0]

    If ($MP)
    {
        #MP found, now check if it is sealed
        If ($MP.sealed)
        {
            Write-Error 'Unable to save to the management pack specified. It is sealed. Please specify an unsealed MP.'
            return $false
        }
    } else {
        Write-Error 'The management pack specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

    #Get the monitoring Class
    $strMCQuery = "Name = '$ClassName'"
    $mcCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria($strMCQuery)
    $MonitoringClass = $MG.GetMonitoringClasses($mcCriteria)[0]
    if (!$MonitoringClass)
    {
        Write-Error 'The monitoring class specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

    #Get the monitor type
    $strMTquery = "Name = 'System.Performance.ThresholdMonitorType'"
    $MTCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorTypeCriteria($strMTquery)
    $MonitorType = $MG.GetUnitMonitorTypes($MTCriteria)[0]

    #Create new monitor
	If ($Disabled -eq $true)
	{
		$EnabledProperty = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::false
	} else {
		$EnabledProperty = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
	}
    $newMonitor = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitor($mp, $MonitorName, [Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Internal)
    $newMonitor.DisplayName = $MonitorDisplayName
    $newMonitor.TypeID = $MonitorType
	$newMonitor.Enabled = $EnabledProperty
    $newMonitor.Target = $MonitoringClass

    #Set Parent monitor
    $strParentMonitorQuery = "Name ='System.Health.$ParentMonitor"+"State'"
    $ParentMonitorCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitorCriteria($strParentMonitorQuery)
    $objParentMonitor = $MG.GetMonitors($ParentMonitorCriteria)[0]
    $newMonitor.ParentMonitorID = $objParentMonitor

	#Monitor category
	$MonitorCategory = $ParentMonitor + "Health"
	$newMonitor.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::$MonitorCategory

    #monitor configuration
    $newMonitor.Remotable = $false
    If (!$Instancename)
    {
        #Must be in lower case, therefore using string instead of boolean variable
        $strAllInstances = 'true'
    } else {
        $strAllInstances = 'false'
    }
    $MonitorConfig = @"
<ComputerName />
<CounterName>$CounterName</CounterName>
<ObjectName>$ObjectName</ObjectName>
<InstanceName>$InstanceName</InstanceName>
<AllInstances>$strAllInstances</AllInstances>
<Frequency>$Frequency</Frequency>
<Threshold>$Threshold</Threshold>
"@
    $newMonitor.Configuration= $MonitorConfig

    #Configure Health State
    $objUnderThresholdState = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($newMonitor, 'UnderThreshold')
    $objOverThresholdState = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($newMonitor, 'OverThreshold')
    $objUnderThresholdState.MonitorTypeStateID = 'UnderThreshold'
    $objOverThresholdState.MonitorTypeStateID = 'OverThreshold'
    If ($UnhealthyWhenUnder)
    {
        $objUnderThresholdState.HealthState = $UnhealthyState   
        $objOverThresholdState.HealthState = 'Success'
    } else {
        $objUnderThresholdState.HealthState = 'Success'
        $objOverThresholdState.HealthState = $UnhealthyState
    }
    $newMonitor.OperationalStateCollection.Add($objUnderThresholdState)
    $newMonitor.OperationalStateCollection.Add($objOverThresholdState)

    #Configure Alert Settings
    $newMonitor.AlertSettings = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorAlertSettings
    $newMonitor.AlertSettings.AlertOnState = $UnhealthyState
    $newMonitor.AlertSettings.AutoResolve = $true
    $newMonitor.AlertSettings.AlertPriority = 'Normal'
    $newMonitor.AlertSettings.AlertSeverity = $UnhealthyState
    $AlertStringResourceID = $MonitorName+'.AlertMessage'
    $AlertParameter1 = "`$Data[Default='']/Context/InstanceName`$"
    $AlertParameter2 = "`$Data[Default='']/Context/ObjectName`$"
    $AlertParameter3 = "`$Data[Default='']/Context/CounterName`$"
    $AlertParameter4 = "`$Data[Default='']/Context/Value`$"
    $AlertParameter5 = "`$Data[Default='']/Context/TimeSampled`$"
    $newMonitor.AlertSettings.AlertParameter1 = $AlertParameter1
    $newMonitor.AlertSettings.AlertParameter2 = $AlertParameter2
    $newMonitor.AlertSettings.AlertParameter3 = $AlertParameter3
    $newMonitor.AlertSettings.AlertParameter4 = $AlertParameter4
    $newMonitor.AlertSettings.AlertParameter5 = $AlertParameter5
    $AlertMessage = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackStringResource($MP, $AlertStringResourceID)
    $AlertMessage.DisplayName = "$MonitorDisplayName Alert"
    $AlertMessage.Description = @"
Instance {0}
Object {1}
Counter {2}
Has a value {3}
At time {4}
"@
    $newMonitor.AlertSettings.AlertMessage = $AlertMessage

    #Increase MP version
    If ($IncreaseMPVersion)
    {
        $CurrentVersion = $MP.Version.Tostring()
        $vIncrement = $CurrentVersion.Split('.')
        $vIncrement[$vIncrement.Length - 1] = ([System.Int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
        $NewVersion = ([System.String]::Join('.', $vIncrement))
        $MP.Version = $NewVersion
    }

    #Verify and save the monitor
    Try {
        $MP.verify()
        $MP.AcceptChanges()
        $Result = $true
		Write-Verbose "2-State Performance Monitor '$MonitorName' successfully created in Management Pack '$MPName'($($MP.Version))."
    } Catch {
        $Result = $false
		$MP.RejectChanges()
        Write-Error "Unable to create 2-State Performance monitor $MonitorName in management pack $MPName."
    }
    $Result
}

Function New-OMPerformanceCollectionRule
{
<# 
 .Synopsis
  Create a performance collection rule in OpsMgr.

 .Description
  Create a performance collection rule in OpsMgr using OpsMgr SDK. A boolean value $true will be returned if the performance collection rule creation has been successful, otherwise, a boolean value of $false is returned if any there are any errors occurred during the creation process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -MPName
  Name for the unsealed MP of which the rule is going to stored.

 .Parameter -RuleName
  Rule name

 .Parameter -RuleDisplayName
  Rule Display Name

 .Parameter -ClassName
  Monitoring Class Name

 .Parameter -CounterName
  The name of the performance counter. i.e. "% Processor Time".

 .Parameter -ObjectName
  The name of the performance Object. i.e. "Processor".

 .Parameter -InstanceName
  The name of the instance. i.e. "_Total". If this parameter is not selected, all instances for the specified counter will be included.

 .Parameter -Frequency
  Specify how often (in seconds) does the rule run. i.e. 900 (15 minutes) 

 .Parameter -Disabled
  Specify if the rule is disabled by default.

 .Parameter -IncreaseMPVersion
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a performance colleciton rule with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Management Pack Name: "TYANG.Lab.Test"
   Rule Name: "Test.Performance.Collection.Rule"
   Rule Display Name: "Test Performance Collection Rule"
   Monitoring Class name: "Microsoft.Windows.Server.OperatingSystem"
   Counter Name: "% Processor Time"
   Object Name: "Processor"
   Instance Name: "_Total"
   Frequency: 900 seconds (15 minutes)

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  New-OMPerformanceCollectionRule -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -MPName "TYANG.Lab.Test" -RuleName "Test.Performance.Collection.Rule" -RuleDisplayName "Test Performance Collection Rule" -ClassName "Microsoft.Windows.Server.OperatingSystem" -CounterName "% Processor Time" -ObjectName "Processor" -InstanceName "_Total" -Frequency 900

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a performance collection rule with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Management Pack Name: "TYANG.Lab.Test"
   Rule Name: "Test.Performance.Collection.Rule"
   Rule Display Name: "Test Performance Collection Rule"
   Monitoring Class name: "Microsoft.Windows.Server.OperatingSystem"
   Counter Name: "% Processor Time"
   Object Name: "Processor"
   Select All Instances
   Frequency: 900 seconds (15 minutes)
   Disabled by default
   Increase Management Pack version by 0.0.0.1

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  New-OMPerformanceCollectionRule -SDKConnection $SDKConnection -MPName "TYANG.Lab.Test" -RuleName "Test.Performance.Collection.Rule" -RuleDisplayName "Test Performance Collection Rule" -ClassName "Microsoft.Windows.Server.OperatingSystem" -CounterName "% Processor Time" -ObjectName "Processor" -Frequency 900 -Disabled $true  -IncreaseMPVersion $true

#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')][String]$MPName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter rule name')][String]$RuleName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter rule display name')][String]$RuleDisplayName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter monitoring class name')][String]$ClassName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Counter Name')][Alias('Counter')][String]$CounterName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Object name')][Alias('Object')][String]$ObjectName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter Instance Name')][Alias('Instance')][String]$Instancename,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the frequency')][Int32]$Frequency,
		[Parameter(Mandatory=$false,HelpMessage='Please specify if the rule is disabled by default')][Boolean]$Disabled = $false,
        [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')][Boolean]$IncreaseMPVersion
    )
    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the unsealed MP
    $strMPquery = "Name = '$MPName'"
    $mpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strMPquery)
    $MP = $MG.GetManagementPacks($mpCriteria)[0]

    If ($MP)
    {
        #MP found, now check if it is sealed
        If ($MP.sealed)
        {
            Write-Error 'Unable to save to the management pack specified. It is sealed. Please specify an unsealed MP.'
            return $false
        }
    } else {
        Write-Error 'The management pack specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

    #Get the monitoring Class
    $strMCQuery = "Name = '$ClassName'"
    $mcCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria($strMCQuery)
    $MonitoringClass = $MG.GetMonitoringClasses($mcCriteria)[0]
    if (!$MonitoringClass)
    {
        Write-Error 'The monitoring class specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

    #Create new rule
	If ($Disabled -eq $true)
	{
		$EnabledProperty = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::false
	} else {
		$EnabledProperty = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
	}
    $newRule = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackRule($mp, $RuleName)
    $newRule.DisplayName = $RuleDisplayName
	$newRule.Enabled = $EnabledProperty
    $newRule.Target = $MonitoringClass
    $newRule.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::PerformanceCollection

    #Configure Data Source module
    $DSModuleType = $MG.GetMonitoringModuleTypes('System.Performance.DataProvider')[0]
    $DSModule = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDataSourceModule($newRule, 'DS')
    $DSModule.TypeID = $DSModuleType

    If (!$Instancename)
    {
        #Must be in lower case, therefore using string instead of boolean variable
        $strAllInstances = 'true'
    } else {
        $strAllInstances = 'false'
    }

    $DSConfig = @"
<ComputerName />
<CounterName>$CounterName</CounterName>
<ObjectName>$ObjectName</ObjectName>
<InstanceName>$InstanceName</InstanceName>
<AllInstances>$strAllInstances</AllInstances>
<Frequency>$Frequency</Frequency>
"@
    $DSModule.Configuration = $DSConfig
    $newRule.DataSourceCollection.Add($DSModule)

    #Configure Write Action modules
    $DBWAModuleType = $MG.GetMonitoringModuleTypes('Microsoft.SystemCenter.CollectPerformanceData')[0]
    $DWWAModuleType = $MG.GetMonitoringModuleTypes('Microsoft.SystemCenter.DataWarehouse.PublishPerformanceData')[0]

    $DBWAModule = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackWriteActionModule($newRule, 'WriteToDB')
    $DBWAModule.TypeID = $DBWAModuleType

    $DWWAModule = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackWriteActionModule($newRule, 'WriteToDW')
    $DWWAModule.TypeID = $DWWAModuleType

    $newRule.WriteActionCollection.Add($DBWAModule)
    $newRule.WriteActionCollection.Add($DWWAModule)

    #Increase MP version
    If ($IncreaseMPVersion)
    {
        $CurrentVersion = $MP.Version.Tostring()
        $vIncrement = $CurrentVersion.Split('.')
        $vIncrement[$vIncrement.Length - 1] = ([System.Int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
        $NewVersion = ([System.String]::Join('.', $vIncrement))
        $MP.Version = $NewVersion
    }

    #Verify and save the monitor
    Try {
        $MP.verify()
        $MP.AcceptChanges()
        $Result = $true
		Write-Verbose "Performance Collection Rule '$RuleName' successfully created in Management Pack '$MPName'($($MP.Version))."
    } Catch {
        $Result = $false
		$MP.RejectChanges()
        Write-Error "Unable to create Performance Collection Rule $RuleName in management pack $MPName."
    }
    $Result
}

Function New-OMEventCollectionRule
{
<# 
 .Synopsis
  Create an event collection rule in OpsMgr.

 .Description
  Create an event collection rule in OpsMgr using OpsMgr SDK. A boolean value $true will be returned if the event collection rule creation has been successful, otherwise, a boolean value of $false is returned if any there are any errors occurred during the creation process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -MPName
  Name for the unsealed MP of which the rule is going to stored.

 .Parameter -RuleName
  Rule name

 .Parameter -RuleDisplayName
  Rule Display Name

 .Parameter -ClassName
  Monitoring Class Name

 .Parameter -EventLog
  The name of the event log where the log entry is generated. i.e. System, Application or Security.

 .Parameter -Publisher
  The publisher / provider of the event log entry. This value can be obtained by going to the XML view in the Details tab in Event viewer, and this value is the Provider Name value.

 .Parameter -EventID
  The event ID that makes the monitor unhealthy.

 .Parameter -Disabled
  Specify if the rule is disabled by default.

 .Parameter -IncreaseMPVersion
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create an event colleciton rule with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Management Pack Name: "TYANG.Lab.Test"
   Rule Name: "Test.Event.Collection.Rule"
   Rule Display Name: "Test Event Collection Rule"
   Monitoring Class name: "Microsoft.Windows.Server.OperatingSystem"
   Event Log: Application
   Publisher: WSH
   Event ID: 2

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  New-OMEventCollectionRule -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -MPName "TYANG.Lab.Test" -RuleName "Test.Event.Collection.Rule" -RuleDisplayName "Test Event Collection Rule" -ClassName "Microsoft.Windows.Server.OperatingSystem" -EventLog "Application" -Publisher "WSH" -EventID 2

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create an event collection rule with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Management Pack Name: "TYANG.Lab.Test"
   Rule Name: "Test.Event.Collection.Rule"
   Rule Display Name: "Test Event Collection Rule"
   Monitoring Class name: "Microsoft.Windows.Server.OperatingSystem"
   Event Log: Application
   Publisher: WSH
   Event ID: 2
   Disabled by default
   Increase Management Pack version by 0.0.0.1

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  New-OMEventCollectionRule -SDKConnection $SDKConnection -MPName "TYANG.Lab.Test" -RuleName "Test.Event.Collection.Rule" -RuleDisplayName "Test Event Collection Rule" -ClassName "Microsoft.Windows.Server.OperatingSystem" -EventLog "Application" -Publisher "WSH" -EventID 2 -Disabled $true  -IncreaseMPVersion $true

#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')][String]$MPName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter rule name')][String]$RuleName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter rule display name')][String]$RuleDisplayName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter monitoring class name')][String]$ClassName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Event Log Name')][Alias('log')][String]$EventLog,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Event Log Publisher Name')][String]$Publisher,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the Event ID')][Int32]$EventID,
		[Parameter(Mandatory=$false,HelpMessage='Please specify if the rule is disabled by default')][Boolean]$Disabled = $false,
        [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')][Boolean]$IncreaseMPVersion
    )
    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the unsealed MP
    $strMPquery = "Name = '$MPName'"
    $mpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strMPquery)
    $MP = $MG.GetManagementPacks($mpCriteria)[0]

    If ($MP)
    {
        #MP found, now check if it is sealed
        If ($MP.sealed)
        {
            Write-Error 'Unable to save to the management pack specified. It is sealed. Please specify an unsealed MP.'
            return $false
        }
    } else {
        Write-Error 'The management pack specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

    #Get the monitoring Class
    $strMCQuery = "Name = '$ClassName'"
    $mcCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria($strMCQuery)
    $MonitoringClass = $MG.GetMonitoringClasses($mcCriteria)[0]
    if (!$MonitoringClass)
    {
        Write-Error 'The monitoring class specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

    #Create new rule
	If ($Disabled -eq $true)
	{
		$EnabledProperty = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::false
	} else {
		$EnabledProperty = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
	}
    $newRule = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackRule($mp, $RuleName)
    $newRule.DisplayName = $RuleDisplayName
	$newRule.Enabled = $EnabledProperty
    $newRule.Target = $MonitoringClass
    $newRule.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::EventCollection

    #Configure Data Source module
    $DSModuleType = $MG.GetMonitoringModuleTypes('Microsoft.Windows.EventProvider')[0]
    $DSModule = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDataSourceModule($newRule, 'DS')
    $DSModule.TypeID = $DSModuleType

    If (!$Instancename)
    {
        #Must be in lower case, therefore using string instead of boolean variable
        $strAllInstances = 'true'
    } else {
        $strAllInstances = 'false'
    }

    $DSConfig = @"
<ComputerName />
<LogName>$EventLog</LogName>
<Expression>
    <And>
    <Expression>
        <SimpleExpression>
        <ValueExpression>
            <XPathQuery Type="UnsignedInteger">EventDisplayNumber</XPathQuery>
        </ValueExpression>
        <Operator>Equal</Operator>
        <ValueExpression>
            <Value Type="UnsignedInteger">$EventID</Value>
        </ValueExpression>
        </SimpleExpression>
    </Expression>
    <Expression>
        <SimpleExpression>
        <ValueExpression>
            <XPathQuery Type="String">PublisherName</XPathQuery>
        </ValueExpression>
        <Operator>Equal</Operator>
        <ValueExpression>
            <Value Type="String">$Publisher</Value>
        </ValueExpression>
        </SimpleExpression>
    </Expression>
    </And>
</Expression>
"@
    $DSModule.Configuration = $DSConfig
    $newRule.DataSourceCollection.Add($DSModule)

    #Configure Write Action modules
    $DBWAModuleType = $MG.GetMonitoringModuleTypes('Microsoft.SystemCenter.CollectEvent')[0]
    $DWWAModuleType = $MG.GetMonitoringModuleTypes('Microsoft.SystemCenter.DataWarehouse.PublishEventData')[0]

    $DBWAModule = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackWriteActionModule($newRule, 'CollectToDB')
    $DBWAModule.TypeID = $DBWAModuleType

    $DWWAModule = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackWriteActionModule($newRule, 'CollectToDW')
    $DWWAModule.TypeID = $DWWAModuleType

    $newRule.WriteActionCollection.Add($DBWAModule)
    $newRule.WriteActionCollection.Add($DWWAModule)

	#Increase MP version
    If ($IncreaseMPVersion)
    {
        $CurrentVersion = $MP.Version.Tostring()
        $vIncrement = $CurrentVersion.Split('.')
        $vIncrement[$vIncrement.Length - 1] = ([System.Int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
        $NewVersion = ([System.String]::Join('.', $vIncrement))
        $MP.Version = $NewVersion
    }

    #Verify and save the monitor
    Try {
        $MP.verify()
        $MP.AcceptChanges()
        $Result = $true
		Write-Verbose "Event Collection Rule '$RuleName' successfully created in Management Pack '$MPName'($($MP.Version))."
    } Catch {
        $Result = $false
		$MP.RejectChanges()
        Write-Error "Unable to create Event Collection Rule $RuleName in management pack $MPName."
    }
    $Result
}

Function New-OMManagementPackReference
{
<# 
 .Synopsis
  Add a management pack reference to an unsealed management pack

 .Description
  Add a sealed MP reference to an unsealed management pack using OpsMgr SDK. A boolean value $true will be returned if the reference has been successfully added, otherwise, a boolean value of $false is returned if any there are any errors occurred during the creation process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -ReferenceMPName
  Name of the referenced sealed management pack.

 .Parameter -Alias
  Reference Alias for the referenced sealed management pack.

 .Parameter -UnsealedMPName
  Name of the unsealed MP where the reference is going to be added to.

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then add a reference of sealed MP 'Microsoft.Windows.Server.2008.Monitoring' to the unsealed management pack YourCompany.Windows.Overrides:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Referencing Sealed MP Name: "Microsoft.Windows.Server.2008.Monitoring"
   Alias: "Win2K8Mon"
   Unsealed destination Management Pack name: YourCompany.Windows.Overrides

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  New-OMManagementPackReference -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -ReferenceMPName "Microsoft.Windows.Server.2008.Monitoring" -Alias "Win2K8Mon" -UnsealedMPName "YourCompany.Windows.Overrides"

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then add a reference of sealed MP 'Microsoft.Windows.Server.2008.Monitoring' to the unsealed management pack YourCompany.Windows.Overrides:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Referencing Sealed MP Name: "Microsoft.Windows.Server.2008.Monitoring"
   Alias: "Win2K8Mon"
   Unsealed destination Management Pack name: YourCompany.Windows.Overrides

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  New-OMManagementPackReference -SDKConnection $SDKConnection -ReferenceMPName "Microsoft.Windows.Server.2008.Monitoring" -Alias "Win2K8Mon" -UnsealedMPName "YourCompany.Windows.Overrides"
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][System.Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][System.String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][System.String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter referenced sealed MP name')][System.String]$ReferenceMPName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter preferred alias for the referenced sealed MP')][System.String]$Alias,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the destination unsealed MP name')][System.String]$UnsealedMPName
    )
    
    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the Reference MP
    Write-Verbose "Getting Reference MP $ReferenceMPName`..."
    $strMPquery = "Name = '$ReferenceMPName' AND Sealed = 'TRUE'"
    $mpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strMPquery)
    $RefMP = $MG.GetManagementPacks($mpCriteria)[0]
    If (!$RefMP)
    {
        Write-Error "Unable to find the Reference Sealed MP with the name '$ReferenceMPName'."
        Return $false
    } else {
        $Version = $RefMP.Version
        $KeyToken = $RefMP.KeyToken
        Write-Verbose "Reference MP Version: $Version"
        Write-Verbose "Reference MP Key Token: $KeyToken"
    }

    #Get the destination unsealed MP
    Write-Verbose "Getting Unsealed MP $UnsealedMPName`..."
    $strMPquery = "Name = '$UnsealedMPName' AND Sealed = 'FALSE'"
    $mpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strMPquery)
    $DestMP = $MG.GetManagementPacks($mpCriteria)[0]
    If (!$DestMP)
    {
        Write-Error "Unable to find the unsealed MP with the name '$UnsealedMPName'."
		Return $false
    } else {
        Write-Verbose "Adding reference for $ReferenceMPName`..."
        $objMPRef = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackReference($DestMP, $ReferenceMPName, $KeyToken, $Version)

        #Verify and save the monitor
        Write-Verbose "Verifying $UnsealedMPName and save changes..."
        Try {
			$DestMP.References.Add($Alias, $objMPRef)
            $DestMP.verify()
            $DestMP.AcceptChanges()
            $Result = $true
			Write-Verbose "MP Reference for sealed MP '$ReferenceMPName' (Alias: $Alias; KeyToken: $KeyToken; Version: $Version) added to '$UnsealedMPName'."
        } Catch {
            $Result = $false
			$DestMP.RejectChanges()
            Write-Error "Unable to add MP Reference for $ReferenceMPName (Alias: $Alias; KeyToken: $KeyToken; Version: $Version) to $UnsealedMPName."
        }
    }
	$Result
}

Function New-OMPropertyOverride
{
<# 
 .Synopsis
  Create a property override in OpsMgr.

 .Description
  Create a property override in OpsMgr using OpsMgr SDK. A boolean value $true will be returned if the override creation has been successful, otherwise, a boolean value of $false is returned if any there are any errors occurred during the creation process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -MPName
  Name for the unsealed MP of which the override is going to stored.

 .Parameter -OverrideType
  type of the override (MonitorPropertyOverride; RulePropertyOverride, DiscoveryPropertyOverride, DiagnosticPropertyOverride or RecoveryPropertyOverride)

 .Parameter -OverrideName
  Override name

 .Parameter -OverrideDisplayName
  Override Display Name

 .Parameter -OverrideType
  Type of property override. Possible values are: 'MonitorPropertyOverride', 'RulePropertyOverride', 'DiscoveryPropertyOverride', 'DiagnosticPropertyOverride' and 'RecoveryPropertyOverride'

 .Parameter -OverrideWorkflow
  The workflow (rule, monitor or discovery) to be overriden.

 .Parameter -OverrideTarget
  Override Target (context)

 .Parameter -ContextInstance
  Override context instance can be a monitoring object or a group that the override should apply to.

 .Parameter -OverrideProperty
  The property of the workflow which is going to be overriden.

 .Parameter -OverrideValue
  The new value of that the override is going set for the override property

 .Parameter -Enforce (boolean)
  Specify if the override is enforced.

 .Parameter -IncreaseMPVersion (boolean)
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a property override with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Management Pack Name: "TYANG.Lab.Override"
   Override Type: RulePropertyOverride
   Override Name: Disable.Test.Event.Collection.Rule.Override
   Override Display Name: Disable Test Event Collection Rule Override
   Override Workflow: "Test.Event.Collection.Rule"
   Target: "Test.Instance.Group"
   Override Property: Enabled
   Override Value: False
   Enforced: False

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  New-OMPropertyOverride -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -MPName "TYANG.Lab.Override" -OverrideType 'RulePropertyOverride' -OverrideName Disable.Test.Event.Collection.Rule.Override -OverrideDisplayName "Disable Test Event Collection Rule Override" -OverrideWorkflow "Test.Event.Collection.Rule" -Target "Test.Instance.Group" -OverrideProperty Enabled -OverrideValue False

 .Example
   # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a property override with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Management Pack Name: "TYANG.Lab.Override"
   Override Type: MonitorPropertyOverride
   Override Name: Disable.Test.Service.Monitor.Override
   Override Workflow: "Test.Service.Monitor"
   Target: "Microsoft.Windows.Computer"
   Context Instance: "6015832d-affa-7a01-10cb-37a37699d904"
   Override Property: Enabled
   Override Value: False
   Enforced: True
   Increase Management Pack version by 0.0.0.1

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  New-OMPropertyOverride -SDKConnection $SDKConnection -MPName "TYANG.Lab.Override" -OverrideType MonitorPropertyOverride -OverrideName Disable.Test.Service.Monitor.Override -OverrideWorkflow "Test.Service.Monitor" -Target "Microsoft.Windows.Computer" -ContextInstance "6015832d-affa-7a01-10cb-37a37699d904" -OverrideProperty Enabled -OverrideValue False -Enforced $true -IncreaseMPVersion $true

#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][System.Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][System.String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][System.String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')][System.String]$MPName,
		[Parameter(Mandatory=$true,HelpMessage='Please enter Override Type')][ValidateSet('MonitorPropertyOverride', 'RulePropertyOverride', 'DiscoveryPropertyOverride', 'DiagnosticPropertyOverride', 'RecoveryPropertyOverride')][System.String]$OverrideType,
        [Parameter(Mandatory=$true,HelpMessage='Please enter override name')][System.String]$OverrideName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter override display name')][System.String]$OverrideDisplayName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter override workflow name')][System.String]$OverrideWorkflow,
        [Parameter(Mandatory=$true,HelpMessage='Please enter override target')][Alias('target')][System.String]$OverrideTarget,
		[Parameter(Mandatory=$false,HelpMessage='Please enter override context instance ID')][Alias('Instance')][System.String]$ContextInstance = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter override property')][System.String]$OverrideProperty,
        [Parameter(Mandatory=$true,HelpMessage='Please enter override value')]$OverrideValue,
		[Parameter(Mandatory=$false,HelpMessage='Set override to Enforced')][System.Boolean]$Enforced=$false,
        [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')][System.Boolean]$IncreaseMPVersion=$false
    )
    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the unsealed MP
    $strMPquery = "Name = '$MPName'"
    $mpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strMPquery)
    $MP = $MG.GetManagementPacks($mpCriteria)[0]

    If ($MP)
    {
        #MP found, now check if it is sealed
        If ($MP.sealed)
        {
            Write-Error 'Unable to save to the management pack specified. It is sealed. Please specify an unsealed MP.'
            return $false
        }
    } else {
        Write-Error 'The management pack specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

    #Get the monitoring Class (Override target / context)
    $strMCQuery = "Name = '$OverrideTarget'"
    $mcCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria($strMCQuery)
    $MonitoringClass = $MG.GetMonitoringClasses($mcCriteria)[0]
    if (!$MonitoringClass)
    {
        Write-Error 'The override target (context) specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

    #Make sure override name has the MP name as prefix
	If ($OverrideName -notmatch $MPName)
	{
		$OverrideName= "$MPName.$OverrideName"	
	}

	#Create new override
	Switch ($OverrideType)
	{
		"MonitorPropertyOverride"
		{
			$WorkflowCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitorCriteria("Name='$OverrideWorkflow'")
			$Workflow = $MG.GetMonitors($WorkflowCriteria)[0]
			$Override = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorPropertyOverride($MP, $OverrideName)
			$Override.Monitor = $Workflow
		}
		"RulePropertyOverride"
		{
			$WorkflowCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringRuleCriteria("Name='$OverrideWorkflow'")
			$Workflow = $MonitoringClass.GetMonitoringRules($WorkflowCriteria)[0]
			$Override = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackRulePropertyOverride($MP, $OverrideName)
			$Override.Rule = $Workflow
		}
		'DiscoveryPropertyOverride'
		{
			$WorkflowCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringDiscoveryCriteria("Name='$OverrideWorkflow'")
			$Workflow = $MonitoringClass.GetMonitoringDiscoveries($WorkflowCriteria)[0]
			$Override = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscoveryPropertyOverride($MP, $OverrideName)
			$Override.Discovery = $Workflow
		}
		'DiagnosticPropertyOverride'
		{
			$WorkflowCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringDiagnosticCriteria("Name='$OverrideWorkflow'")
			$Workflow = $MonitoringClass.GetMonitoringDiagnostics($WorkflowCriteria)[0]
			$Override = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiagnosticPropertyOverride($MP, $OverrideName)
			$Override.Diagnostic = $Workflow
		}
		'RecoveryPropertyOverride'
		{
			$WorkflowCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringRecoveryCriteria("Name='$OverrideWorkflow'")
			$Workflow = $MonitoringClass.GetMonitoringRecoveries($WorkflowCriteria)[0]
			$Override = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackRecoveryPropertyOverride($MP, $OverrideName)
			$Override.Recovery = $Workflow
		}
	}
	
	#Finishing creating overrides
	$Override.Property = $OverrideProperty
	$Override.Value = $OverrideValue
	$Override.Context = $MonitoringClass
	If ($ContextInstance.Length -gt 0)
	{
		$Override.ContextInstance = $ContextInstance
	}
	If ($OverrideDisplayName)
	{
		$Override.DisplayName = $OverrideDisplayName
	}
	If ($Enforced)
	{
		$Override.Enforced = $true
	}

	#Increase MP version
    If ($IncreaseMPVersion)
    {
        $CurrentVersion = $MP.Version.Tostring()
        $vIncrement = $CurrentVersion.Split('.')
        $vIncrement[$vIncrement.Length - 1] = ([System.Int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
        $NewVersion = ([System.String]::Join('.', $vIncrement))
        $MP.Version = $NewVersion
    }

    #Verify and save the MP
    Try {
        $MP.verify()
        $MP.AcceptChanges()
        $Result = $true
		Write-Verbose "Override '$OverrideName' successfully created in Management Pack '$MPName'($($MP.Version))."
    } Catch {
        $Result = $false
        Write-Error "Unable to create override $OverrideName in management pack $MPName."
		$MP.RejectChanges()
    }
    $Result
}

Function New-OMConfigurationOverride
{
<# 
 .Synopsis
  Create a configuration override in OpsMgr.

 .Description
  Create a configuration (parameter) override in OpsMgr using OpsMgr SDK. A boolean value $true will be returned if the override creation has been successful, otherwise, a boolean value of $false is returned if any there are any errors occurred during the creation process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -MPName
  Name for the unsealed MP of which the override is going to stored.

 .Parameter -OverrideType
  Type of configuration override. Possible values are: 'MonitorConfigurationOverride', 'RuleConfigurationOverride', 'DiscoveryConfigurationOverride', 'DiagnosticConfigurationOverride' and 'RecoveryConfigurationOverride'

 .Parameter -OverrideName
  Override name

 .Parameter -OverrideDisplayName
  Override Display Name

 .Parameter -OverrideWorkflow
  The workflow (rule, monitor or discovery) to be overriden.

 .Parameter -Target
  Override Target (context)

 .Parameter -ContextInstance
  Override context instance can be a monitoring object or a group that the override should apply to.

 .Parameter -OverrideParamter
  The configuration parameter of the workflow which is going to be overriden.

 .Parameter -OverrideValue
  The new value of that the override is going set for the override property

 .Parameter -Enforce (boolean)
  Specify if the override is enforced.

 .Parameter -IncreaseMPVersion (boolean)
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a configuration override with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Management Pack Name: "TYANG.Lab.Override"
   Override Type: RuleConfigurationOverride
   Override Name: Test.Performance.Collection.Rule.Interval.Override
   Override Display Name: Test Performance Collection Rule Interval Override
   Override Workflow: "Test.Performance.Collection.Rule"
   Target: "Test.Instance.Group"
   Override parameter: intervalseconds
   Override Value: 600
   Enforced: False

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  New-OMConfigurationOverride -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -MPName "TYANG.Lab.Override" -OverrideType RuleConfigurationOverride -OverrideName Test.Performance.Collection.Rule.Interval.Override -OverrideDisplayName "Test Performance Collection Rule Interval Override" -OverrideWorkflow "Test.Performance.Collection.Rule" -Target "Test.Instance.Group" -OverrideParameter IntervalSeconds -OverrideValue 600

 .Example
   # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a configuration override with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Management Pack Name: "TYANG.Lab.Override"
   Override Type: MonitorConfigurationOverride
   Override Name: Test.Performance.Monitor.Interval.Override
   Override Workflow: "Test.Performance.Monitor"
   Target: "Microsoft.Windows.Computer"
   Context Instance: "6015832d-affa-7a01-10cb-37a37699d904"
   Override Property: IntervalSeconds
   Override Value: 600
   Enforced: True
   Increase Management Pack version by 0.0.0.1

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  New-OMConfigurationOverride -SDKConnection $SDKConnection -MPName "TYANG.Lab.Override" -OverrideType MonitorConfigurationOverride -OverrideName Test.Performance.Monitor.Interval.Override -OverrideWorkflow "Test.Performance.Monitor" -Target "Microsoft.Windows.Computer" -ContextInstance "6015832d-affa-7a01-10cb-37a37699d904" -OverrideParameter IntervalSeconds -OverrideValue 600 -Enforced $true -IncreaseMPVersion $true

#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][System.Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][System.String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][System.String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')][System.String]$MPName,
		[Parameter(Mandatory=$true,HelpMessage='Please enter Override Type')][ValidateSet('MonitorConfigurationOverride', 'RuleConfigurationOverride', 'DiscoveryConfigurationOverride', 'DiagnosticConfigurationOverride', 'RecoveryConfigurationOverride')][System.String]$OverrideType,
        [Parameter(Mandatory=$true,HelpMessage='Please enter override name')][System.String]$OverrideName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter override display name')][System.String]$OverrideDisplayName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter override workflow name')][System.String]$OverrideWorkflow,
        [Parameter(Mandatory=$true,HelpMessage='Please enter override target')][Alias('target')][System.String]$OverrideTarget,
		[Parameter(Mandatory=$false,HelpMessage='Please enter override context instance ID')][Alias('Instance')][System.String]$ContextInstance = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter override configuration parameter')][System.String]$OverrideParameter,
        [Parameter(Mandatory=$true,HelpMessage='Please enter override value')]$OverrideValue,
		[Parameter(Mandatory=$false,HelpMessage='Set override to Enforced')][System.Boolean]$Enforced=$false,
        [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')][System.Boolean]$IncreaseMPVersion=$false
    )
    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the unsealed MP
    $strMPquery = "Name = '$MPName'"
    $mpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strMPquery)
    $MP = $MG.GetManagementPacks($mpCriteria)[0]

    If ($MP)
    {
        #MP found, now check if it is sealed
        If ($MP.sealed)
        {
            Write-Error 'Unable to save to the management pack specified. It is sealed. Please specify an unsealed MP.'
            return $false
        }
    } else {
        Write-Error 'The management pack specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

    #Get the monitoring Class (Override target / context)
    $strMCQuery = "Name = '$OverrideTarget'"
    $mcCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria($strMCQuery)
    $MonitoringClass = $MG.GetMonitoringClasses($mcCriteria)[0]
    if (!$MonitoringClass)
    {
        Write-Error 'The override target (context) specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

    #Make sure override name has the MP name as prefix
	If ($OverrideName -notmatch $MPName)
	{
		$OverrideName= "$MPName.$OverrideName"	
	}

	#Create new override
	Switch ($OverrideType)
	{
		"MonitorConfigurationOverride"
		{
			$WorkflowCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitorCriteria("Name='$OverrideWorkflow'")
			$Workflow = $MG.GetMonitors($WorkflowCriteria)[0]
		}
		"RuleConfigurationOverride"
		{
			$WorkflowCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringRuleCriteria("Name='$OverrideWorkflow'")
			$Workflow = $MonitoringClass.GetMonitoringRules($WorkflowCriteria)[0]		
		}
		'DiscoveryConfigurationOverride'
		{
			$WorkflowCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringDiscoveryCriteria("Name='$OverrideWorkflow'")
			$Workflow = $MonitoringClass.GetMonitoringDiscoveries($WorkflowCriteria)[0]
		}
		'DiagnosticConfigurationOverride'
		{
			$WorkflowCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringDiagnosticCriteria("Name='$OverrideWorkflow'")
			$Workflow = $MonitoringClass.GetMonitoringDiagnostics($WorkflowCriteria)[0]
		}
		'RecoveryConfigurationOverride'
		{
			$WorkflowCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringRecoveryCriteria("Name='$OverrideWorkflow'")
			$Workflow = $MonitoringClass.GetMonitoringRecoveries($WorkflowCriteria)[0]
		}
	}

	$objOverrideParameter = $Workflow.GetOverrideableParameters() | Where-Object{$_.Name -ieq $OverrideParameter}
	If (!$objOverrideParameter)
	{
		Write-Error "Unable to find an overrideable parameter with name '$OverrideParameter' for $($Workflow.Name)!"
		return $false
	} else {
		Write-Verbose "The override parameter '$OverrideParameter' is valid."
	}

	Switch ($OverrideType)
	{
		"MonitorConfigurationOverride"
		{
			Write-Verbose 'Creating Monitor Configuration Override...'
			#Find the override paramters
			$objParameters = $Workflow.GetOverrideableParameters()
		}
		"RuleConfigurationOverride"
		{
			Write-Verbose 'Creating Rule Configuration Override...'
			#Find the override paramters by module
			$objParameters = $Workflow.GetOverrideableParametersByModule()
		}
		'DiscoveryConfigurationOverride'
		{
			Write-Verbose 'Creating Discovery Configuration Override...'
			#Find the override paramter by module
			$objParameters = $Workflow.GetOverrideableParametersByModule()
		}
		'DiagnosticConfigurationOverride'
		{
			Write-Verbose 'Creating Diagnostic Configuration Override...'
			#Find the override paramter by module
			$objParameters = $Workflow.GetOverrideableParametersByModule()
		}
		'RecoveryConfigurationOverride'
		{
			Write-Verbose 'Creating Recovery Configuration Override...'
			#Find the override paramter by module
			$objParameters = $Workflow.GetOverrideableParametersByModule()
		}
	}
	
	#Get all overrideable parameters and its module based on the name
	$arrModules = New-Object System.Collections.ArrayList
	Foreach ($module in $objParameters.keys)
	{
		foreach ($parameter in $objParameters.$module)
		{
			if ($parameter.name -ieq $OverrideParameter)
			{
				$objParameter = New-Object psobject
				Add-Member -InputObject $objParameter -MemberType NoteProperty -Name Module -Value  $module.name
				Add-Member -InputObject $objParameter -MemberType NoteProperty -Name Parameter -Value  $parameter.name
				[System.Void]$arrModules.Add($objParameter)
			}
		}
	}
	#If there are more than one parameter returned, exit with error
	If ($arrModules.Count -gt 1)
	{
		Write-Error "There are $($arrModules.count) overrideable parameters with the name $OverrideParameter1. The script will not continue. To ensure the correct overrideable parameter is selected, please create the override manually."
		Return $false
	}

	#Create Override
	
	Switch ($OverrideType)
	{
		"MonitorConfigurationOverride"
		{
			$Override = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorConfigurationOverride($MP, $OverrideName)
			$Override.Monitor = $Workflow
		}
		"RuleConfigurationOverride"
		{
			$Override = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackRuleConfigurationOverride($MP, $OverrideName)
			$Override.Rule = $Workflow
			$Override.Module = $arrModules[0].Module
		}
		'DiscoveryConfigurationOverride'
		{
			$Override = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscoveryConfigurationOverride($MP, $OverrideName)
			$Override.Discovery = $Workflow
			$Override.Module = $arrModules[0].Module
		}
		'DiagnosticConfigurationOverride'
		{
			$Override = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiagnosticConfigurationOverride($MP, $OverrideName)
			$Override.Diagnostic = $Workflow
			$Override.Module = $arrModules[0].Module
		}
		'RecoveryConfigurationOverride'
		{
			$Override = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackRecoveryConfigurationOverride($MP, $OverrideName)
			$Override.Recovery = $Workflow
			$Override.Module = $arrModules[0].Module
		}
	}
	$Override.Parameter = $OverrideParameter
	$Override.Value = $OverrideValue
	$Override.Context = $MonitoringClass
	If ($ContextInstance.Length -gt 0)
	{
		$Override.ContextInstance = $ContextInstance
	}
	If ($OverrideDisplayName)
	{
		$Override.DisplayName = $OverrideDisplayName
	} Else {
		Write-Verbose 'Override DisplayName was not specified. The override will not have a display name.'
	}
	If ($Enforced)
	{
		$Override.Enforced = $true
	}
	#Increase MP version
    If ($IncreaseMPVersion)
    {
        $CurrentVersion = $MP.Version.Tostring()
        $vIncrement = $CurrentVersion.Split('.')
        $vIncrement[$vIncrement.Length - 1] = ([System.Int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
        $NewVersion = ([System.String]::Join('.', $vIncrement))
        $MP.Version = $NewVersion
    }

    #Verify and save the MP
    Try {
        $MP.verify()
        $MP.AcceptChanges()
        $Result = $true
		Write-Verbose "Override '$OverrideName' successfully created in Management Pack '$MPName'($($MP.Version))."
    } Catch {
        $Result = $false
        Write-Error "Unable to create override $OverrideName in management pack $MPName."
		$MP.RejectChanges()
    }
    $Result
}

Function New-OMOverride
{
<# 
 .Synopsis
  Create an override in OpsMgr.

 .Description
  Create an override in OpsMgr using OpsMgr SDK. A boolean value $true will be returned if the override creation has been successful, otherwise, a boolean value of $false is returned if any there are any errors occurred during the creation process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -MPName
  Name for the unsealed MP of which the override is going to stored.

 .Parameter -OverrideName
  Override name

 .Parameter -OverrideDisplayName
  Override Display Name

 .Parameter -OverrideWorkflow
  The workflow (rule, monitor or discovery) to be overriden.

 .Parameter -WorkflowType
  The type of the override workflow. Possible values are: 'Monitor', 'Rule', 'Discovery', 'Diagnostic' and 'Recovery'.

 .Parameter -Target
  Override Target (context)

 .Parameter -ContextInstance
  Override context instance can be a monitoring object or a group that the override should apply to.

 .Parameter -OverrideParamter
  The configuration parameter of the workflow which is going to be overriden.

 .Parameter -OverrideValue
  The new value of that the override is going set for the override property

 .Parameter -Enforce (boolean)
  Specify if the override is enforced.

 .Parameter -IncreaseMPVersion (boolean)
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create an override with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Management Pack Name: "TYANG.Lab.Override"
   Override Name: Test.Performance.Collection.Rule.Interval.Override
   Override Display Name: Test Performance Collection Rule Interval Override
   Override Workflow: "Test.Performance.Collection.Rule"
   Workflow Type: Rule
   Target: "Test.Instance.Group"
   Override parameter: intervalseconds
   Override Value: 600
   Enforced: False

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  New-OMOverride -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -MPName "TYANG.Lab.Override" -OverrideName Test.Performance.Collection.Rule.Interval.Override -OverrideDisplayName "Test Performance Collection Rule Interval Override" -OverrideWorkflow "Test.Performance.Collection.Rule" -WorkflowType "Rule" -Target "Test.Instance.Group" -OverrideParameter IntervalSeconds -OverrideValue 600

 .Example
   # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create an override with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Management Pack Name: "TYANG.Lab.Override"
   Override Workflow: "Test.Performance.Monitor"
   Workflow Type: Monitor
   Target: "Microsoft.Windows.Computer"
   Context Instance: "6015832d-affa-7a01-10cb-37a37699d904"
   Override Property: IntervalSeconds
   Override Value: 600
   Enforced: True
   Increase Management Pack version by 0.0.0.1

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  New-OMOverride -SDKConnection $SDKConnection -MPName "TYANG.Lab.Override" -OverrideWorkflow "Test.Performance.Monitor" -WorkflowType "Monitor" -Target "Microsoft.Windows.Computer" -ContextInstance "6015832d-affa-7a01-10cb-37a37699d904" -OverrideParameter IntervalSeconds -OverrideValue 600 -Enforced $true -IncreaseMPVersion $true
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][System.Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][System.String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][System.String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')][System.String]$MPName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter override name')][System.String]$OverrideName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter override display name')][System.String]$OverrideDisplayName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter override workflow name')][System.String]$OverrideWorkflow,
		[Parameter(Mandatory=$true,HelpMessage='Please enter workflow Type')][ValidateSet('Monitor', 'Rule', 'Discovery', 'Diagnostic', 'Recovery')][System.String]$WorkflowType,
        [Parameter(Mandatory=$true,HelpMessage='Please enter override target')][Alias('target')][System.String]$OverrideTarget,
		[Parameter(Mandatory=$false,HelpMessage='Please enter override context instance ID')][Alias('Instance')][System.String]$ContextInstance = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter override parameter')][System.String]$OverrideParameter,
        [Parameter(Mandatory=$true,HelpMessage='Please enter override value')]$OverrideValue,
		[Parameter(Mandatory=$false,HelpMessage='Set override to Enforced')][System.Boolean]$Enforced=$false,
        [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')][System.Boolean]$IncreaseMPVersion=$false
    )
    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the unsealed MP
	Write-Verbose "Checking Management Pack $MPName`..."
    $strMPquery = "Name = '$MPName'"
    $mpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strMPquery)
    $MP = $MG.GetManagementPacks($mpCriteria)[0]

    If ($MP)
    {
        #MP found, now check if it is sealed
        If ($MP.sealed)
        {
            Write-Error 'Unable to save to the management pack specified. It is sealed. Please specify an unsealed MP.'
            return $false
        }
    } else {
        Write-Error 'The management pack specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

    #Get the monitoring Class (Override target / context)
	Write-Verbose "Getting the monitoring object $OverrideTarget`..."
    $strMCQuery = "Name = '$OverrideTarget'"
    $mcCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria($strMCQuery)
    $MonitoringClass = $MG.GetMonitoringClasses($mcCriteria)[0]
    if (!$MonitoringClass)
    {
        Write-Error 'The override target (context) specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

	#Get the override workflow an detect override type
	Write-Verbose "Getting the override $WorkFlowType $OverrideWorkflow`..."
	Switch ($WorkflowType)
	{
		"Monitor"
		{
			$WorkflowCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitorCriteria("Name='$OverrideWorkflow'")
			$Workflow = $MG.GetMonitors($WorkflowCriteria)[0]
			#Add all possible property overrides into arraylists then determine if the parameter is a valid override property
			#The complete list is documented here: (http://msdn.microsoft.com/en-us/library/microsoft.enterprisemanagement.configuration.managementpackmonitorpropertyoverride.aspx?cs-save-lang=1&cs-lang=csharp#code-snippet-2)
			#Common properties for unit, aggregate and dependency monitors
			$arrMonitorOverrideProperties = New-Object System.Collections.ArrayList
			[System.Void]$arrMonitorOverrideProperties.Add("enabled")
			[System.Void]$arrMonitorOverrideProperties.Add("autoresolve")
			[System.Void]$arrMonitorOverrideProperties.Add("alertpriority")
			[System.Void]$arrMonitorOverrideProperties.Add("alertonstate")
			[System.Void]$arrMonitorOverrideProperties.Add("alertseverity")
			
			#Unit monitor
			$arrUnitMonitorOverrideProperties = New-Object System.Collections.ArrayList
			[System.Void]$arrUnitMonitorOverrideProperties.Add("generatealert")
			
			#aggregate monitr
			$arrAggregateMonitorOverrideProperties = New-Object System.Collections.ArrayList
			[System.Void]$arrAggregateMonitorOverrideProperties.Add("algorithm")

			#dependency monitr
			$arrDependencyMonitorOverrideProperties = New-Object System.Collections.ArrayList
			[System.Void]$arrDependencyMonitorOverrideProperties.Add("algorithm")
			[System.Void]$arrDependencyMonitorOverrideProperties.Add("memberinmaintenance")
			[System.Void]$arrDependencyMonitorOverrideProperties.Add("memberunavailable")
			[System.Void]$arrDependencyMonitorOverrideProperties.Add("ignorememberinmaintenance")
			[System.Void]$arrDependencyMonitorOverrideProperties.Add("ignorememberunavailable")
			
			#Get Monitor Type
			$MonitorType = $Workflow.Gettype().Name
			$bPropertyOverride = $false
			Switch ($MonitorType)
			{
				#Unit Monitor
				"UnitMonitor"
				{
					if ($arrMonitorOverrideProperties.Contains($($OverrideParameter.ToLower())) -or $arrUnitMonitorOverrideProperties.Contains($($OverrideParameter.ToLower())))
					{
						$bPropertyOverride = $true
					}
				}
				#Aggregate Monitor
				"InternalRollupMonitor"
				{
					if ($arrMonitorOverrideProperties.Contains($($OverrideParameter.ToLower())) -or $arrAggregateMonitorOverrideProperties.Contains($($OverrideParameter.ToLower())))
					{
						$bPropertyOverride = $true
					}
				}
				#Dependency Monitor
				"ExternalRollupMonitor"
				{
					if ($arrMonitorOverrideProperties.Contains($($OverrideParameter.ToLower())) -or $arrDependencyMonitorOverrideProperties.Contains($($OverrideParameter.ToLower())))
					{
						$bPropertyOverride = $true
					}
				}
			}
			 
		}
		"Rule"
		{
			$WorkflowCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringRuleCriteria("Name='$OverrideWorkflow'")
			$Workflow = $MonitoringClass.GetMonitoringRules($WorkflowCriteria)[0]
			#The only possible override property for rules is Enabled (http://msdn.microsoft.com/en-us/library/microsoft.enterprisemanagement.configuration.managementpackrulepropertyoverride.aspx)
			If ($OverrideParameter -ieq "Enabled")
			{
				$bPropertyOverride = $true
			} else {
				$bPropertyOverride = $false
			}
		}
		'Discovery'
		{
			$WorkflowCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringDiscoveryCriteria("Name='$OverrideWorkflow'")
			$Workflow = $MonitoringClass.GetMonitoringDiscoveries($WorkflowCriteria)[0]
			#The only possible override property for discoveries is Enabled (http://msdn.microsoft.com/en-us/library/microsoft.enterprisemanagement.configuration.managementpackdiscoverypropertyoverride.aspx)
			If ($OverrideParameter -ieq "Enabled")
			{
				$bPropertyOverride = $true
			} else {
				$bPropertyOverride = $false
			}
		}
		'Diagnostic'
		{
			$WorkflowCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringDiagnosticCriteria("Name='$OverrideWorkflow'")
			$Workflow = $MonitoringClass.GetMonitoringDiagnostics($WorkflowCriteria)[0]
			#The only possible override property for diagnostics is Enabled (http://msdn.microsoft.com/en-us/library/microsoft.enterprisemanagement.configuration.managementpackdiagnosticpropertyoverride.aspx)
			If ($OverrideParameter -ieq "Enabled")
			{
				$bPropertyOverride = $true
			} else {
				$bPropertyOverride = $false
			}
		}
		'Recovery'
		{
			$WorkflowCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringRecoveryCriteria("Name='$OverrideWorkflow'")
			$Workflow = $MonitoringClass.GetMonitoringRecoveries($WorkflowCriteria)[0]
			#The only possible override property for recoveries is Enabled (http://msdn.microsoft.com/en-us/library/microsoft.enterprisemanagement.configuration.managementpackrecoverypropertyoverride.aspx)
			If ($OverrideParameter -ieq "Enabled")
			{
				$bPropertyOverride = $true
			} else {
				$bPropertyOverride = $false
			}
		}
	}
	$ConfigParameter = $workflow.GetOverrideableParameters() |Where-Object{$_.Name -ieq $OverrideParameter}
	#Detect Override type (Configuration Override vs Property Override)
	if (!$bPropertyOverride -and !$ConfigParameter)
	{
		Write-Error "The override parameter $OverrideParameter is neither an overrideable property nor an overrideable configuration parameter. Please make sure the correct parameter is specified."
		Return $false
	} elseif ($bPropertyOverride -and $ConfigParameter)
	{
		Write-Error "The override parameter $OverrideParameter is detected to be both a valid overrideable property and a valid overrideable configuration parameter. Unable to determine which parameter / property needs to be overrided. Please create the override manually."
		Return $false
	} elseif ($ConfigParameter.Count -gt 1)
	{
		Write-Error "There are multiple overrideable configuration parameters detected with the same name: $OverrideParameter. Unable to determine which parameter needs to be overrided. Please create the override manually."
		Return $false
	} elseif ($ConfigParameter.count -eq 1)
	{
		$bConfigParameter = $true
	}

	#Determine the override name if not specified
	if (!$OverrideName)
	{
		if ($ContextInstance -ne $null)
		{
			$OverrideName = $MP.Name + "." + $OverrideWorkflow.Replace(".","") + "." + $WorkflowType + ".Property." + $OverrideParameter + ".Context." + $OverrideTarget.Replace(".","") + ".Instance." + $ContextInstance.Replace("-", "") + '.Override'
		} else {
			$OverrideName = $MP.Name + "." + $OverrideWorkflow.Replace(".","") + "." + $WorkflowType + ".Property." + $OverrideParameter + ".Context." + $OverrideTarget.Replace(".","") + '.Override'
		}

		if ($OverrideName.Length -gt 256)
		{
			$OverrideName = $MP.Name + "." + $OverrideWorkflow.Replace(".","") + "." + $WorkflowType + "." + ([System.Guid]::NewGuid().ToString()).Replace("-","") + ".Override"
		}
		if ($OverrideName.Length -gt 256)
		{
			$OverrideName = $MP.Name + ([System.Guid]::NewGuid().ToString()).Replace("-","") + ".Override" 
		}
		Write-Verbose "Override Name (ID) generated: $OverrideName"
	} else {
		If ($OverrideName -notcontains $MPName)
		{
			$OverrideName= "$MPName.$OverrideName"	
			Write-Verbose "Override Name (ID) updated to: $OverrideName"
		}
	}

	#Determine override type and create override
	If ($bPropertyOverride)
	{
		#Create Property override
		Switch ($WorkflowType)
		{
			"Monitor"
			{
				$OverrideType = 'MonitorPropertyOverride'
			}
			"Rule"
			{
				$OverrideType = 'RulePropertyOverride'
			}
			'Discovery'
			{
				$OverrideType = 'DiscoveryPropertyOverride'
			}
			'Diagnostic'
			{
				$OverrideType = 'DiagnosticPropertyOverride'
			}
			'Recovery'
			{
				$OverrideType = 'RecoveryPropertyOverride'
			}
		}
		#Create override
		Write-Verbose "Creating $OverrideType"
		$Result = New-OMPropertyOverride -SDK $SDK -Username $Username -Password $Password -MPName $MPName -OverrideType  $OverrideType -OverrideName $OverrideName -OverrideDisplayName  $OverrideDisplayName -OverrideWorkflow  $OverrideWorkflow -OverrideTarget  $OverrideTarget -ContextInstance $ContextInstance -OverrideProperty $OverrideParameter -OverrideValue $OverrideValue -Enforced $Enforced -IncreaseMPVersion $IncreaseMPVersion
	} elseif ($ConfigParameter) {
		#Create configuration override
		Switch ($WorkflowType)
		{
			"Monitor"
			{
				$OverrideType = 'MonitorConfigurationOverride'
			}
			"Rule"
			{
				$OverrideType = 'RuleConfigurationOverride'
			}
			'Discovery'
			{
				$OverrideType = 'DiscoveryConfigurationOverride'
			}
			'Diagnostic'
			{
				$OverrideType = 'DiagnosticConfigurationOverride'
			}
			'Recovery'
			{
				$OverrideType = 'RecoveryConfigurationOverride'
			}
		}
		#Create Override
		Write-Verbose "Creating $OverrideType"
		$Result = New-OMConfigurationOverride -SDK $SDK -Username $Username -Password $Password -MPName $MPName -OverrideType $OverrideType -OverrideName $OverrideName -OverrideDisplayName $OverrideDisplayName -OverrideWorkfloW $OverrideWorkflow -OverrideTarget  $OverrideTarget -ContextInstance $ContextInstance -OverrideParameter $OverrideParameter -OverrideValue $OverrideValue -Enforced  $Enforced -IncreaseMPVersion  $IncreaseMPVersion
	}
	$Result
}

Function Remove-OMOverride
{
<# 
 .Synopsis
  Remove an override in OpsMgr.

 .Description
  Remove an override in OpsMgr using OpsMgr SDK. A boolean value $true will be returned if the override removal has been successful, otherwise, a boolean value of $false is returned if any there are any errors occurred during the removal process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -OverrideName
  Override name

 .Parameter -IncreaseMPVersion (boolean)
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then delete an override with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Override Name: Test.Performance.Collection.Rule.Interval.Override
  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  Remove-OMOverride -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -OverrideName Test.Performance.Collection.Rule.Interval.Override

 .Example
   # Connect to OpsMgr management group via management server "OpsMgrMS01" and then delete an override with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Override Name: Test.Performance.Collection.Rule.Interval.Override
   Increase Management Pack version by 0.0.0.1
  
  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  Remove-OMOverride -SDKConnection $SDKConnection -OverrideName Test.Performance.Collection.Rule.Interval.Override -IncreaseMPVersion $true
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][System.Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][System.String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][System.String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter override name')][System.String]$OverrideName,
        [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')][System.Boolean]$IncreaseMPVersion=$false
    )
    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the override
	Write-Verbose "Getting Override $OverrideName"
	$strQuery = "Name = '$OverrideName'"
	$OverrideCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringOverrideCriteria($strQuery)
	$Override = $MG.GetMonitoringOverrides($OverrideCriteria)[0]

	If (!$Override)
	{
		Write-Error "Unable to find the override with name $OverrideName"
		Return $false
	}

	Write-Verbose "Getting the override management pack"
    $MP = $Override.GetManagementPack()

    If ($MP.sealed)
    {
        Write-Error "Unable to delete the override $overrideName because it is stored in a sealed management pack. Please create another override in a unsealed management pack to override the parameter again."
        return $false
    }
	$MPName = $MP.Name

	#Deleting the override
	Write-Verbose "Deleting override $OverrideName"
	$Override.Status = "PendingDelete"
	
	#Increase MP version
    If ($IncreaseMPVersion)
    {
        $CurrentVersion = $MP.Version.Tostring()
        $vIncrement = $CurrentVersion.Split('.')
        $vIncrement[$vIncrement.Length - 1] = ([System.Int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
        $NewVersion = ([System.String]::Join('.', $vIncrement))
        $MP.Version = $NewVersion
    }

  #Verify and save the MP
    Try {
        $MP.verify()
        $MP.AcceptChanges()
        $Result = $true
		Write-Verbose "Override '$OverrideName' successfully deleted from Management Pack '$MPName'($($MP.Version))."
    } Catch {
        $Result = $false
        Write-Error "Unable to create override $OverrideName in management pack $MPName."
		$MP.RejectChanges()
    }
	$Result
}

Function New-OMInstanceGroup
{
<# 
 .Synopsis
  Create an empty instance group in OpsMgr.

 .Description
  Create an empty instance group in OpsMgr using OpsMgr SDK. The group membership must be populated manually or via another script. A boolean value $true will be returned if the group creation has been successful, otherwise, a boolean value of $false is returned if any there are any errors occurred during the creation process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -MPName
  Name for the unsealed MP of which the instance group class definition and discovery is going to stored.

 .Parameter -InstanceGroupName
  Instance Group name

 .Parameter -InstanceGroupDisplayName
  Instance Group Display Name

 .Parameter -IncreaseMPVersion (boolean)
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create an empty instance group with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Management Pack Name: "TYANG.Lab.Groups"
   Instance Group Name: Test.Instance.Group
   Instance Group Display Name: Test Instance Group

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  New-OMInstanceGroup -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -MPName "TYANG.Lab.Groups" -InstanceGroupName "Test.Instance.Group" -InstanceGroupDisplayName "Test Instance Group"

 .Example
   # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create an empty instance group with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Management Pack Name: "TYANG.Lab.Groups"
   Instance Group Name: Test.Instance.Group
   Increase Management Pack version by 0.0.0.1

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  New-OMInstanceGroup -SDKConnection $SDKConnection -MPName "TYANG.Lab.Groups" -InstanceGroupName "Test.Instance.Group" -IncreaseMPVersion $true
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][System.Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][System.String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][System.String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')][System.String]$MPName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Instance Group name')][Alias('Name')][System.String]$InstanceGroupName,
		[Parameter(Mandatory=$false,HelpMessage='Please enter Instance Group Display Name')][Alias('DisplayName')][System.String]$InstanceGroupDisplayName = $null,
        [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')][System.Boolean]$IncreaseMPVersion=$false
    )
    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.UserName
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the unsealed MP
	Write-Verbose "Checking Management Pack $MPName`..."
    $strMPquery = "Name = '$MPName'"
    $mpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strMPquery)
    $MP = $MG.GetManagementPacks($mpCriteria)[0]

    If ($MP)
    {
        #MP found, now check if it is sealed
        If ($MP.sealed)
        {
            Write-Error 'Unable to save to the management pack specified. It is sealed. Please specify an unsealed MP.'
            return $false
        }
    } else {
        Write-Error 'The management pack specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

	#Make sure this MP is referencing the "Microsoft.SystemCenter.Library" MP
	Write-Verbose "Getting the alias for 'Microsoft.SystemCenter.Library' MP"
	$SystemCenterLibAlias = ($MP.References | Where-Object {$_.Value -like '*Microsoft.SystemCenter.Library*'}).key
	If (!$SystemCenterLibAlias)
	{
		Write-Verbose "$MPName is not referencing 'Microsoft.SystemCenter.Library'. Creating the reference now."
		$SystemCenterLibAlias = "SystemCenter"
		$AddAlias = New-OMManagementPackReference -SDK $SDK -Username $Username -Password $Password -ReferenceMPName 'Microsoft.SystemCenter.Library' -Alias $SystemCenterLibAlias -UnsealedMPName $MPName 
		
	}
	Write-Verbose "alias for 'Microsoft.SystemCenter.Library' reference is '$SystemCenterLibAlias'"

	#Make sure this MP is referencing the "System.Library" MP
	Write-Verbose "Getting the alias for 'System.Library' MP"
	$SystemLibAlias = ($MP.References | Where-Object {$_.Value -like '*System.Library*'}).key
	If (!$SystemLibAlias)
	{
		Write-Verbose "$MPName is not referencing 'System.Library'. Creating the reference now."
		$SystemLibAlias = "System"
		$AddAlias = New-OMManagementPackReference -SDK $SDK -Username $Username -Password $Password -ReferenceMPName 'System.Library' -Alias $SystemLibAlias -UnsealedMPName $MPName 
		
	}
	Write-Verbose "alias for 'System.Library' reference is '$SystemLibAlias'"
			
	#Make sure this MP is referencing the "Microsoft.SystemCenter.InstanceGroup.Library" MP
	Write-Verbose "Getting the alias for 'Microsoft.SystemCenter.InstanceGroup.Library' MP"
	$SCIGAlias = ($MP.References | Where-Object {$_.Value -like '*Microsoft.SystemCenter.InstanceGroup.Library*'}).key
	If (!$SCIGAlias)
	{
		Write-Verbose "$MPName is not referencing 'Microsoft.SystemCenter.InstanceGroup.Library'. Creating the reference now."
		$AddAlias = New-OMManagementPackReference -SDK $SDK -Username $Username -Password $Password -ReferenceMPName 'Microsoft.SystemCenter.InstanceGroup.Library' -Alias 'SCIG' -UnsealedMPName $MPName 
		$SCIGAlias = "SCIG"
	}
	Write-Verbose "alias for 'Microsoft.SystemCenter.InstanceGroup.Library' reference is '$SCIGAlias'"

	#Group population fomula
		#Group population expression
	$formula = '<MembershipRule Comment="Empty_Rule">' + ` 
		"<MonitoringClass>`$MPElement[Name=`"$SCIGAlias!Microsoft.SystemCenter.InstanceGroup`"]$</MonitoringClass>" + ` 
		"<RelationshipClass>`$MPElement[Name=`"$SCIGAlias!Microsoft.SystemCenter.InstanceGroupContainsEntities`"]$</RelationshipClass>" + ` 
		'<Expression>' + ` 
		'<SimpleExpression>' + ` 
		'<ValueExpression>' + ` 
		'<Value>True</Value>' + ` 
		'</ValueExpression>' + ` 
		'<Operator>Equal</Operator>' + ` 
		'<ValueExpression>' + ` 
		'<Value>False</Value>' + ` 
		'</ValueExpression>' + ` 
		'</SimpleExpression>' + ` 
		'</Expression>' + ` 
		'</MembershipRule>'

	#Create group class
	Write-Verbose "Creating empty instane group $InstanceGroupName now."
	Write-Verbose "Group Population fomular for $InstanceGroupName`: $formula"
	If (!$InstanceGroupDisplayName)
	{
		$InstanceGroupDisplayName = $InstanceGroupName
	}

	$Group = New-Object Microsoft.EnterpriseManagement.Monitoring.CustomMonitoringObjectGroup($MPName,$InstanceGroupName,$InstanceGroupDisplayName,$formula)
	$GroupFullName = "$($Group.NameSpace)`.$($Group.Name)"
	Write-Verbose "Group Full Name: $GroupFullName"
	
    Try {
		$MP.InsertCustomMonitoringObjectGroup($Group)
		#Increase MP version
		If ($IncreaseMPVersion)
		{
			$CurrentVersion = $MP.Version.Tostring()
			$vIncrement = $CurrentVersion.Split('.')
			$vIncrement[$vIncrement.Length - 1] = ([System.Int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
			$NewVersion = ([System.String]::Join('.', $vIncrement))
			Write-Verbose "Increasing MP version to $NewVersion"
			$MP.Version = $NewVersion
		}
		#Verify and save the MP
		Write-Verbose "Saving Management Pack $MPName"
        $MP.verify()
        $MP.AcceptChanges()
        $Result = $true
		Write-Verbose "Empty instance group '$GroupFullName' successfully created in Management Pack '$MPName'($($MP.Version))."
    } Catch {
        $Result = $false
        Write-Error "Unable to create Instance Group $GroupFullName in management pack $MPName."
		$MP.RejectChanges()
    }
	$Result
}

Function New-OMComputerGroup
{
<# 
 .Synopsis
  Create an empty computer group in OpsMgr.

 .Description
  Create an empty computer group in OpsMgr using OpsMgr SDK. The group membership must be populated manually or via another script. A boolean value $true will be returned if the group creation has been successful, otherwise, a boolean value of $false is returned if any there are any errors occurred during the creation process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -MPName
  Name for the unsealed MP of which the computer group class definition and discovery is going to stored.

 .Parameter -ComputerGroupName
  Computer Group name

 .Parameter -ComputerGroupDisplayName
  Computer Group Display Name

 .Parameter -IncreaseMPVersion (boolean)
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create an empty computer group with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Management Pack Name: "TYANG.Lab.Groups"
   Computer Group Name: Test.Computer.Group
   Computer Group Display Name: Test Computer Group

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  New-OMComputerGroup -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -MPName "TYANG.Lab.Groups" -ComputerGroupName "Test.Computer.Group" -ComputerGroupDisplayName "Test Instance Group"

 .Example
   # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create an empty computer group with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Management Pack Name: "TYANG.Lab.Groups"
   Computer Group Name: Test.Computer.Group
   Increase Management Pack version by 0.0.0.1
  
  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  New-OMComputerGroup -SDKConnection $SDKConnection -MPName "TYANG.Lab.Groups" -ComputerGroupName "Test.Instance.Group" -IncreaseMPVersion $true
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][System.Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][System.String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][System.String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')][System.String]$MPName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Computer Group name')][Alias('Name')][System.String]$ComputerGroupName,
		[Parameter(Mandatory=$false,HelpMessage='Please enter Computer Group Display Name')][Alias('DisplayName')][System.String]$ComputerGroupDisplayName = $null,
        [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')][System.Boolean]$IncreaseMPVersion=$false
    )
    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.UserName
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the unsealed MP
	Write-Verbose "Checking Management Pack $MPName`..."
    $strMPquery = "Name = '$MPName'"
    $mpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strMPquery)
    $MP = $MG.GetManagementPacks($mpCriteria)[0]

    If ($MP)
    {
        #MP found, now check if it is sealed
        If ($MP.sealed)
        {
            Write-Error 'Unable to save to the management pack specified. It is sealed. Please specify an unsealed MP.'
            return $false
        }
    } else {
        Write-Error 'The management pack specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

	#Make sure this MP is referencing the "Microsoft.SystemCenter.Library" MP
	Write-Verbose "Getting the alias for 'Microsoft.SystemCenter.Library' MP"
	$SystemCenterLibAlias = ($MP.References | Where-Object {$_.Value -like '*Microsoft.SystemCenter.Library*'}).key
	If (!$SystemCenterLibAlias)
	{
		Write-Verbose "$MPName is not referencing 'Microsoft.SystemCenter.Library'. Creating the reference now."
		$SystemCenterLibAlias = "SystemCenter"
		$AddAlias = New-OMManagementPackReference -SDK $SDK -Username $Username -Password $Password -ReferenceMPName 'Microsoft.SystemCenter.Library' -Alias $SystemCenterLibAlias -UnsealedMPName $MPName 
		
	}
	Write-Verbose "alias for 'Microsoft.SystemCenter.Library' reference is '$SystemCenterLibAlias'"

	#Make sure this MP is referencing the "Microsoft.Windows.Library" MP
	Write-Verbose "Getting the alias for 'Microsoft.Windows.Library' MP"
	$WindowsLibAlias = ($MP.References | Where-Object {$_.Value -like '*Microsoft.Windows.Library*'}).key
	If (!$WindowsLibAlias)
	{
		Write-Verbose "$MPName is not referencing 'Microsoft.Windows.Library'. Creating the reference now."
		$WindowsLibAlias = "Windows"
		$AddAlias = New-OMManagementPackReference -SDK $SDK -Username $Username -Password $Password -ReferenceMPName 'Microsoft.Windows.Library' -Alias $WindowsLibAlias -UnsealedMPName $MPName 
		
	}
	Write-Verbose "alias for 'Microsoft.SystemCenter.Library' reference is '$SystemCenterLibAlias'"

	#Create group class
	#Make sure the computer group name starts with the MP namespace
	$MPPrefix = "$MPName`."
	If (!($ComputerGroupName.StartsWith($MPPrefix)))
	{
		$OldComputerGroupName = $ComputerGroupName
		$ComputerGroupName = "$MPPrefix" + "$ComputerGroupName"
		Write-Verbose "Changing Computer group name to include MP name as prefix. Group name will be changed from `"$OldComputerGroupName`" to `"$ComputerGroupName`"."
	}
	Write-Verbose "Creating empty computer group $ComputerGroupName now."
	$ComputerGroupClassCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria("Name='Microsoft.SystemCenter.ComputerGroup'")
	$ComputerGroupClass = $MG.GetMonitoringClasses($ComputerGroupClassCriteria)[0]
	$RelationshipClassCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria("Name='Microsoft.SystemCenter.ComputerGroupContainsComputer'")
	$RelationshipClass = $MG.GetMonitoringRelationshipClass([Microsoft.EnterpriseManagement.Configuration.SystemMonitoringRelationshipClass]::ComputerGroupContainsComputer)
	$GroupClass = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackClass($MP, $ComputerGroupName, "Public")
	$GroupClass.Singleton = $true
	$GroupClass.Base = $ComputerGroupClass
	If ($ComputerGroupDisplayName)
	{
		$GroupClass.DisplayName = $ComputerGroupDisplayName
	}
	
	#Group population expression
	$GroupPopExpression = '<RuleId>$MPElement$</RuleId>' + ` 
		"<GroupInstanceId>`$MPElement[Name=`"$ComputerGroupName`"]`$</GroupInstanceId>" + `
		'<MembershipRules>' + `
		'<MembershipRule Comment="Empty Rule">' + ` 
		"<MonitoringClass>`$MPElement[Name=`"$WindowsLibAlias!Microsoft.Windows.Computer`"]$</MonitoringClass>" + ` 
		"<RelationshipClass>`$MPElement[Name=`"$SystemCenterLibAlias!Microsoft.SystemCenter.ComputerGroupContainsComputer`"]$</RelationshipClass>" + ` 
		'<Expression>' + ` 
		'<SimpleExpression>' + ` 
		'<ValueExpression>' + ` 
		'<Value>True</Value>' + ` 
		'</ValueExpression>' + ` 
		'<Operator>Equal</Operator>' + ` 
		'<ValueExpression>' + ` 
		'<Value>False</Value>' + ` 
		'</ValueExpression>' + ` 
		'</SimpleExpression>' + ` 
		'</Expression>' + ` 
		'</MembershipRule>' + `
		'</MembershipRules>'
	
	Write-Verbose "Group Population Expression for $ComputerGroupName`: $GroupPopExpression"

    Try {
		Write-Verbose "Creating $ComputerGroupName now."
		#Group discovery
		$GroupDiscovery = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscovery($MP, "$ComputerGroupName.Discovery")
		$GroupDiscovery.Category = "Discovery"
		$GroupDiscovery.DisplayName = "$ComputerGroupName Discovery"
		$GroupDiscovery.Description = "Group populator for $ComputerGroupName"
		$GroupDiscovery.Remotable = $true
		$Relationship = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscoveryRelationship
		$Relationship.TypeID=$RelationshipClass
		$GroupDiscovery.DiscoveryRelationshipCollection.Add($Relationship)
		$GroupDiscovery.Target = $GroupClass
		$GroupDiscovery.DataSource = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDataSourceModule($GroupDiscovery, "GroupPop")
		$GroupDiscovery.DataSource.TypeID = $MG.GetMonitoringModuleTypes("Microsoft.SystemCenter.GroupPopulator")[0]
		$GroupDiscovery.DataSource.Configuration = $GroupPopExpression

		#Increase MP version
		If ($IncreaseMPVersion)
		{
			$CurrentVersion = $MP.Version.Tostring()
			$vIncrement = $CurrentVersion.Split('.')
			$vIncrement[$vIncrement.Length - 1] = ([System.Int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
			$NewVersion = ([System.String]::Join('.', $vIncrement))
			Write-Verbose "Increasing MP version to $NewVersion"
			$MP.Version = $NewVersion
		}
		#Verify and save the MP
		Write-Verbose "Saving Management Pack $MPName"
        $MP.verify()
        $MP.AcceptChanges()
        $Result = $true
		Write-Verbose "Empty computer group '$ComputerGroupName' successfully created in Management Pack '$MPName'($($MP.Version))."
    } Catch {
        $Result = $false
        Write-Error "Unable to create Computer Group $ComputerGroupName in management pack $MPName."
		$MP.RejectChanges()
    }
	$Result
}

Function Remove-OMGroup
{
<# 
 .Synopsis
  Remove a group in OpsMgr.

 .Description
  Remove an instance group or computer group in OpsMgr using OpsMgr SDK. A boolean value $true will be returned if the group removal has been successful, otherwise, a boolean value of $false is returned if any there are any errors occurred during the removal process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -GroupName
  Group name

 .Parameter -IncreaseMPVersion (boolean)
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then delete an instance group with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Instance Group Name: Test.Instance.Group

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  Remove-OMGroup -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -GroupName Test.Instance.Group

 .Example
   # Connect to OpsMgr management group via management server "OpsMgrMS01" and then delete a computer group with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Computer Group Name: Test.Computer.Group
   Increase Management Pack version by 0.0.0.1
  
  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  Remove-OMGroup -SDKConnection $SDKConnection -GroupName Test.Computer.Group -IncreaseMPVersion $true
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][System.Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][System.String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][System.String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter group name')][System.String]$GroupName,
        [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')][System.Boolean]$IncreaseMPVersion=$false
    )
    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the group
	Write-Verbose "Getting group $GroupName"
	$Group = $MG.GetMonitoringClasses($GroupName)[0]

	If (!$Group)
	{
		Write-Error "Unable to find the group with name $GroupName"
		Return $false
	}

	#Get the management pack where the group class is defined
	Write-Verbose "Getting the group management pack"
    $GroupMP = $Group.GetManagementPack()

    If ($GroupMP.sealed)
    {
        Write-Error "Unable to delete the group $GroupName because it is stored in a sealed management pack."
        return $false
    }

	$MPName = $GroupMP.Name

	#Deleting the group
	Write-Verbose "Deleting group $GroupName"
	$Group.Status = "PendingDelete"
	
	#Delete the group discoveries
	#Since the group is created in an unsealed MP, the discoveries must be in the same unsealed MP. therefore, there's no need to consider scenarios where discoveries are from different MPs.
	Write-Verbose "Deleting discoveries for group $GroupName"
	$GroupDiscoveries = $Group.GetMonitoringDiscoveries()
	Foreach ($Discovery in $GroupDiscoveries)
	{
		$Discovery.Status = "PendingDelete"
	}

	#Increase MP version
    If ($IncreaseMPVersion)
    {
        $CurrentVersion = $GroupMP.Version.Tostring()
        $vIncrement = $CurrentVersion.Split('.')
        $vIncrement[$vIncrement.Length - 1] = ([System.Int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
        $NewVersion = ([System.String]::Join('.', $vIncrement))
        $GroupMP.Version = $NewVersion
    }

  #Verify and save the MP
    Try {
        $GroupMP.verify()
        $GroupMP.AcceptChanges()
        $Result = $true
		Write-Verbose "Group '$GroupName' successfully deleted from Management Pack '$MPName'($($GroupMP.Version))."
    } Catch {
        $Result = $false
        Write-Error "Unable to delete group $GroupName in management pack $MPName."
		$GroupMP.RejectChanges()
    }
	$Result
}

Function Copy-OMManagementPack
{
<# 
 .Synopsis
  Copy an unsealed management pack from a source OpsMgr management group to the destination management group.

 .Description
  Copy an unsealed management pack from a source OpsMgr management group to the destination management group using OpsMgr SDK. A boolean value $true will be returned if the MP has been successfully copied from the source management group to the destination management group, otherwise, a boolean value of $false is returned if any there are any errors occurred during the copy process.

 .Parameter -SourceSDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table) for the source Management Group.

 .Parameter -DestinationSDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table) for the destination Management Group.

 .Parameter -SourceSDK
  Management Server name for the source Management Group

 .Parameter -SourceUserName
  Alternative user name to connect to the source management group (optional).

 .Parameter -SourcePassword
  Alternative password to connect to the source management group (optional).

 .Parameter -DestinationSDK
  Management Server name for the destination Management Group

 .Parameter -DestinationUserName
  Alternative user name to connect to the destination management group (optional).

 .Parameter -DestinationPassword
  Alternative password to connect to the destination management group (optional).

 .Parameter -MPName
  Name for the unsealed management pack to be copied from source MP to the destination MP.

 .Parameter -Overwrite
  Specify if the existing management pack in the destination management group will be overwritten.

 .Example
  # Connect to the source OpsMgr management group MG01 and then Copy an unsealed MP to the destination management group MG02 with the following details:
   Source Management Server: "OpsMgrMS01"
   Source Username: "domain1\SCOM.Admin"
   Source Password "password1234"
   Destination Management Server: "SCOM01"
   Destination Username: "domain2\SCOM.Admin"
   Destination Password "abcd5678"
   Unsealed MP Name: "TYANG.Test.MP"

  $SourcePassword = ConvertTo-SecureString -AsPlainText "password1234" -force
  $DestinationPassword = ConvertTo-SecureString -AsPlainText "abcd5678" -force
  Copy-OMManagementPack -SourceSDK "OpsMgrMS01" -SourceUsername "domain1\SCOM.Admin" -SourcePassword $SourcePassword -DestinationSDK "SCOM01" -DestinationUsername "domain2\SCOM.Admin" -DestinationPassword $DestinationPassword -MPName "TYANG.Test.MP"

 .Example
   # Connect to the source OpsMgr management group MG01 and then Copy an unsealed MP to the destination management group MG02 with the following details:
   Source OpsMgrSDK Connection (Used in SMA): "MG01"
   Destination OpsMgrSDK Connection (Used in SMA): "MG02"
   Unsealed MP Name: "TYANG.Test.MP"
  
  $SourceSDKConnection = Get-AutomationConnection -Name MG01
  $DestinationSDKConnection = Get-AutomationConnection -Name MG02
  Copy-OMManagementPack -SourceSDKConnection $SourceSDKConnection -DestinationSDKConnection $DestinationSDKCOnnection -MPName "TYANG.Test.MP"

 .Example
   # Connect to the source OpsMgr management group via management server "OpsMgrMS01" and then Copy an unsealed MP to the destination management group via management server SCOM01 with the following details:
   Source Management Group Management Server: OpsMgrMS01
   SourceUsername: "domainA\SCOM.Admin"
   SourcePassword "password1234"
   Destination Management Group Management Server: SCOM01
   DestinationUsername: "domainB\SCOM.Admin"
   DestinationPassword "password5678"
   Unsealed MP Name: "TYANG.Test.MP"
   Overwrite existing MP in Destination MG

  Copy-OMManagementPack -SourceSDK OpsMgrMS01 -SourceUsername "domainA\SCOM.Admin" -SourcePassword "password1234" -DestinationSDK SCOM01 -DestinationUserName "domainB\SCOM.Admin" -DestinationPassword "password5678" -MPName "TYANG.Test.MP" -Overwrite $true
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('SourceMG','s')][System.Object]$SourceSDKConnection,
		[Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('DestinationMG','d')][System.Object]$DestinationSDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('SDAS','SServer')][System.String]$SourceSDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('su')][System.String]$SourceUsername = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('sp')][System.String]$SourcePassword = $null,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DDAS','DServer')][System.String]$DestinationSDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('du')][System.String]$DestinationUsername = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('dp')][System.String]$DestinationPassword = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Management Pack name')][System.String]$MPName,
		[Parameter(Mandatory=$false,HelpMessage='Please specify if existing Management Pack in the destination management group will be overwritten.')][System.Boolean]$Overwrite = $false
    )
	
	#Connect to the source MG
	If ($SourceSDKConnection)
	{
		Write-Verbose "Connecting to the Source Management Group via SDK $($SourceSDKConnection.ComputerName)`..."
		$SourceMG = Connect-OMManagementGroup -SDKConnection $SourceSDKConnection
		$SourceSDK = $SourceSDKConnection.ComputerName
		$SourceUsername = $SourceSDKConnection.Username
		$SourcePassword= ConvertTo-SecureString -AsPlainText $SourceSDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to the Source Management Group via SDK $SourceSDK`..."
		If ($SourceUsername -and $SourcePassword)
		{
			$SourceMG = Connect-OMManagementGroup -SDK $SourceSDK -UserName $SourceUsername -Password $SourcePassword
		} else {
			$SourceMG = Connect-OMManagementGroup -SDK $SourceSDK
		}
	}
	$SourceMGName = $SourceMG.Name
	Write-Verbose "Source Management Group name: `"$SourceMGName`""

	#Connect to the destination MG
	If ($DestinationSDKConnection)
	{
		Write-Verbose "Connecting to the Destination Management Group via SDK $($DestinationSDKConnection.ComputerName)`..."
		$DestinationMG = Connect-OMManagementGroup -SDKConnection $DestinationSDKConnection
		$DestinationSDK = $DestinationSDKConnection.ComputerName
		$DestinationUsername = $DestinationSDKConnection.Username
		$DestinationPassword= ConvertTo-SecureString -AsPlainText $DestinationSDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to the Destination Management Group via SDK $DestinationSDK`..."
		If ($DestinationUsername -and $DestinationPassword)
		{
			$DestinationMG = Connect-OMManagementGroup -SDK $DestinationSDK -UserName $DestinationUsername -Password $DestinationPassword
		} else {
			$DestinationMG = Connect-OMManagementGroup -SDK $DestinationSDK
		}
	}
	$DestinationMGName = $DestinationMG.Name
	Write-Verbose "Destination Management Group name: `"$DestinationMGName`""

	#Get the MP from the source MG
	Write-Verbose "Getting management pack `"$MPName` from the source management group $SourceMGName"
	$strSourceMPQuery = "Name = '$MPName'"
	$SourceMPCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strSourceMPQuery)
	$SourceMP =$SourceMG.GetManagementPacks($SourceMPCriteria)[0]
	If (!$SourceMP)
	{
		Write-Error "Unable to find management pack `"$MPName`" in the source management group $SourceMGName."
		Return $false
	}
	#Make sure the source MP is unsealed
	If ($SourceMP.Sealed)
	{
		Write-Error "The managmeent pack `"$MPName`" in the source management group is sealed. Unable to copy sealed management packs."
		Return $false
	}

	#Check existing MP in the destination MG
	$ExistingDestMP = $DestinationMG.GetManagementPacks($SourceMPCriteria)[0]
	if ($ExistingDestMP)
	{
		#MP already exists in the destination MG.
		Write-Verbose "`'$MPName`" already exists in destination management group $DestinationMGName."
		if ($ExistingDestMP.Sealed)
		{
			#The existing MP is also sealed.
			Write-Error "The management pack `"$MPName`" already exists in the destination management group $DestinationMGName and it is sealed. Unable to continue. exit now."
			Return $false
		} else {
			if ($Overwrite)
			{
				Write-Verbose "The existing management pack in the destination management group $DestinationMGName will be overwritten."
			} else {
				Write-Error "Aborting. The management pack `"$MPName`" already exists in destination management group. Please use `"-Overwrite `$true`" parameter if you want to overwrite the existing management pack in the destination management group."
				Return $false
			}
		}
	}

	#read the content (XML) of the source MP
	Write-Verbose "Reading MP `"$MPName`" content."
	$MPStringBuilder = New-Object System.Text.StringBuilder
	$SourceMPWriter = New-Object Microsoft.EnterpriseManagement.Configuration.IO.ManagementPackXmlWriter([System.Xml.XmlWriter]::Create($MPStringBuilder))
	[System.Void]$SourceMPWriter.WriteManagementPack($SourceMP)

	#Write the MP to the destination MG
	Write-Verbose "Writing MP `"$MPName`" to the destination management group $DestinationMGName."
	$StringReader = New-Object System.IO.StringReader $MPStringBuilder.ToString()
	$DestMPStore = New-Object Microsoft.EnterpriseManagement.Configuration.IO.ManagementPackFileStore
	$DestMP = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPack($StringReader, $DestMPStore)
	
    Try {
        $DestinationMG.ImportManagementPack($DestMP)
        $Result = $true
		Write-Verbose "Management Pack `"$MPName`" successfully written to the destination management group $DestinationMGName."
    } Catch {
        $Result = $false
		$DestMP.RejectChanges()
		$InnException = $_.Exception.InnerException.InnerException
		Write-Error $InnException
		Write-Error "Failed to write Management Pack `"$MPName`" to the destination management group $DestinationMGName. Possible causes: one or more referencing sealed MPs in `"$MPName`" does not exist in the destination management group $DestinationMGName."
    }
    $Result
}

Function Get-OMDAMembers
{
<# 
 .Synopsis
  Get monitoring objects that are members of a Distributed Application in OpsMgr.

 .Description
  Get monitoring objects that are members of a Distributed Application in OpsMgr using OpsMgr SDK. By default, this function only retrieves objects one level down. Users can use -Recursive parameter to retrieve all objects within the DA hierarchy. 

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -DAFullName
  Full Name for the Distributed Application.

 .Parameter -DADisplayName
  Alternatively, specify the Distributed Application display name. Please keep in mind the display name is not unique. if there are more than 1 DAs having the same display name, the script will fail.

 .Parameter -Recursive
  Set this parameter to true when retrieving all objects. WARNING: depending on the size of the DA, this could take a very long time.

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then get members of the ConfigMgr DA:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   DA Full Name: "Microsoft.SystemCenter2012.ConfigurationManagement"

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  Get-OMDAMembers -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -DAFullName "Microsoft.SystemCenter2012.ConfigurationManagement"

 .Example
   # Connect to OpsMgr management group via management server "OpsMgrMS01" and then get members of the ConfigMgr DA:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   DA Display Name: "ConfigMgr"
   Get all members in the hierarchy (recursive lookup)
  
  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  Get-OMDAMembers -SDKConnection $SDKConnection -DADisplayName "ConfigMgr" -Recursive $true
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')]
		[Parameter(ParameterSetName='SearchFullName',Mandatory=$false,HelpMessage='Please specify the SMA Connection object')]
		[Parameter(ParameterSetName='SearchDisplayName',Mandatory=$false,HelpMessage='Please specify the SMA Connection object')]
		[Alias('Connection','c')][System.Object]$SDKConnection,

		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')]
		[Parameter(ParameterSetName='SearchFullName',Mandatory=$false,HelpMessage='Please enter the Management Server name')]
		[Parameter(ParameterSetName='SearchDisplayName',Mandatory=$false,HelpMessage='Please enter the Management Server name')]
		[Alias('DAS','Server','s')][System.String]$SDK,

        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')]
		[Parameter(ParameterSetName='SearchFullName',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')]
		[Parameter(ParameterSetName='SearchDisplayName',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')]
		[Alias('u')][System.String]$Username = $null,

        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')]
		[Parameter(ParameterSetName='SearchFullName',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')]
		[Parameter(ParameterSetName='SearchDisplayName',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')]
		[Alias('p')][SecureString]$Password = $null,

        [Parameter(ParameterSetName='SearchFullName',Mandatory=$true,HelpMessage='Please enter Distributed Application Full name')]
		[Alias('Name')][System.String]$DAFullName,

		[Parameter(ParameterSetName='SearchDisplayName',Mandatory=$true,HelpMessage='Please enter Distributed Application Display Name')]
		[Alias('DisplayName')][System.String]$DADisplayName,

        [Parameter(Mandatory=$false,HelpMessage='Use Recursive lookup')][System.Boolean]$Recursive=$false
    )
    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.UserName
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the DA Monitoring Class
	Write-Verbose "Getting monitoring class for Distributed Applications (`"System.Service`")."
	$strMCQuery = "Name = 'System.Service'"
	$mcCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria($strMCQuery)
	$MonitoringClass = $MG.GetMonitoringClasses($mcCriteria)[0]
	If ($DAFullName)
	{
		Write-Verbose "Getting the Distributed Application using full name '$DAFullName'."
		$DACriteria = New-Object Microsoft.EnterpriseManagement.Monitoring.MonitoringObjectGenericCriteria("FullName = '$DAFullName'")
		$DA = $MG.GetMonitoringObjects($DACriteria, $MonitoringClass)[0]
	} elseif ($DADisplayName) {
		Write-Verbose "Getting the Distributed Application using displayn name '$DADisplayName'."
		$DACriteria = New-Object Microsoft.EnterpriseManagement.Monitoring.MonitoringObjectGenericCriteria("DisplayName = '$DADisplayName'")
		$DA = $MG.GetMonitoringObjects($DACriteria, $MonitoringClass)
	}

	If ($DA.Count -gt 1)
	{
		#The Displayname specified is not unique, multiple DA found.
		$DAMembers = $NULL
		Write-Error "Found multiple Distributed Application with display name '$DADisplayName'. Unable to continue."
		Return $false
	} else {
		if ($Recursive)
		{
			Write-Verbose "Getting the members for Distributed Application with TraversalDepth: Recursive."
			$DAmembers = $DA.GetRelatedMonitoringObjects([Microsoft.EnterpriseManagement.Common.TraversalDepth]::Recursive)
		} else {
			Write-Verbose "Getting the members for Distributed Application with TraversalDepth: OneLevel."
			$DAmembers = $DA.GetRelatedMonitoringObjects([Microsoft.EnterpriseManagement.Common.TraversalDepth]::OneLevel)
		}
	}
	#Create an arraylist to store DA members and DA itself.
	$arrMonitoringObjects = New-Object System.Collections.ArrayList
	#Firstly add the DA itself
	[void]$arrMonitoringObjects.Add($DA)
	#Then add each member
	Foreach ($Member in $DAMembers)
	{
		[Void]$arrMonitoringObjects.Add($Member)
	}
	#Return the Arraylist
	$arrMonitoringObjects
}
Function New-OMAlertConfiguration
{
<# 
 .Synopsis
  Create a new OpsMgrExtended.AlertConfiguration object that can be passed to the New-OMRule function as an input.

 .Description
  Create a new OpsMgrExtended.AlertConfiguration object that can be passed to the New-OMRule function as an input. A OpsMgrExtended.AlertConfiguration object is returned. This object is required for the New-OMRule function when creating an alert generating rule.

 .Parameter -AlertName
  The Alert name / Title

 .Parameter -AlertDescription
  The Alert Description. Please use {0}, {1} etc. to coresponding the alert parameters defined in your alert generating rule's Write Action module'.

 .Parameter -LanguagePackID
  The ID of the Language Pack where the alert message is created under. i.e. "ENU"

 .Parameter -StringResource
  The ID of the alert message string resource.
  
 .Example
  # Create an OpsMgrExtended.AlertConfiguration instance for an alert generating rule:

  $DSModuleConfig = New-OMAlertConfiguration -AlertName "Test Alert" -AlertDescription "Something is not working on computer {0}." -LanguagePackID "ENU" -StringResource "My.ManagementPack.NameSpace.My.Alert.Generating.Rule.AlertMessage"
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter The Alert Name')][System.String]$AlertName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter The Alert Description')][System.String]$AlertDescription,
        [Parameter(Mandatory=$false,HelpMessage='Please enter The Language Pack ID')][System.String]$LanguagePackID = "ENU",
        [Parameter(Mandatory=$true,HelpMessage='Please enter the Alert Message String Resource ID')][System.String]$StringResource
    )

	#Make sure the OpsMgrExnteded.Types Assembly is loaded
	If (!([AppDomain]::CurrentDomain.GetAssemblies() |Where-Object { $_.FullName -eq 'OpsMgrExtended.Types, Version=1.0.0.0, Culture=neutral, PublicKeyToken=23140eab7fb5cf37' }))
	{
		$OpsMgrExtendedTypesDLLPath = Join-Path $PSScriptRoot "OpsMgrExtended.Types.Dll"
		Add-Type -Path $OpsMgrExtendedTypesDLLPath
	}
	$objAlertConfig = New-Object OpsMgrExtended.AlertConfiguration -Property @{AlertName = $AlertName; AlertDescription = $AlertDescription; LanguagePackID = $LanguagePackID; StringResource = $StringResource}
	$objAlertConfig
}
Function New-OMModuleConfiguration
{
<# 
 .Synopsis
  Create a new OpsMgrExtended.ModuleConfiguration object that can be passed to the New-OMRule function as an input.

 .Description
  Create a new OpsMgrExtended.ModuleConfiguration object that can be passed to the New-OMRule function as an input. A OpsMgrExtended.ModuleConfiguration object is returned.

 .Parameter -ModuleTypeName
  The name of the Module Type (i.e. 'Microsoft.SystemCenter.CollectPerformanceData')

 .Parameter -Configuration
  The module configuration (XML element)

 .Parameter -MemberModuleName
  The member module name that will be used in the rule (i.e. 'DS' or 'WA').

 .Example
  # Create an OpsMgrExtended.ModuleConfiguration instance for the data source module of a performance collection rule:
  $ModuleTypeName = "System.Performance.DataProvider"
  $Configuration = @"
<ComputerName />
<CounterName>% Processor Time</CounterName>
<ObjectName>Processor</ObjectName>
<InstanceName>_Total</InstanceName>
<AllInstances>true</AllInstances>
<Frequency>300</Frequency>
"@
   $MemberModuleName = "DS"
	$RunAsMPName = "Custom.MP"
	$RunAsName = "Custom.MP.Admin.Account"
  $DSModuleConfig = New-OMModuleConfiguration -ModuleTypeName $ModuleTypeName -Configuration $Configuration -MemberModuleName $MemberModuleName -RunAsMPName $RunAsMPName -RunAsName $RunAsName

 .Example
  # Create an OpsMgrExtended.ModuleConfiguration instance for one of the write action modules of a performance collection rule (No configuration required):

  $DSModuleConfig = New-OMModuleConfiguration -ModuleTypeName "Microsoft.SystemCenter.CollectPerformanceData" -MemberModuleName "WriteToDB"

#>
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter The Module Type Name')][System.String]$ModuleTypeName,
		[Parameter(Mandatory=$false,HelpMessage='Please enter the Module configuration (XML element)')][System.String]$Configuration = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the member module name')][System.String]$MemberModuleName,
		[Parameter(Mandatory=$false,HelpMessage='Please enter the Management Pack Name of which the RunAs account is defined')][System.String]$RunAsMPName,
		[Parameter(Mandatory=$false,HelpMessage='Please enter the RunAs account name')][System.String]$RunAsName
    )

	#Make sure the OpsMgrExnteded.Types Assembly is loaded
	If (!([AppDomain]::CurrentDomain.GetAssemblies() |Where-Object { $_.FullName -eq 'OpsMgrExtended.Types, Version=1.0.0.0, Culture=neutral, PublicKeyToken=23140eab7fb5cf37' }))
	{
		$OpsMgrExtendedTypesDLLPath = Join-Path $PSScriptRoot "OpsMgrExtended.Types.Dll"
		Add-Type -Path $OpsMgrExtendedTypesDLLPath
	}
	$objModuleConfig = New-Object OpsMgrExtended.ModuleConfiguration -Property @{ModuleTypeName = $ModuleTypeName; Configuration = $Configuration; MemberModuleName = $MemberModuleName; RunAsMPName = $RunAsMPName; RunAsName = $RunAsName}
	$objModuleConfig
}
Function New-OMRule
{
<# 
 .Synopsis
  Create a rule in OpsMgr.

 .Description
  Create a rule in OpsMgr using OpsMgr SDK. A boolean value $true will be returned if the rule creation has been successful, otherwise, a boolean value of $false is returned if any there are any errors occurred during the creation process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -MPName
  Name for the unsealed MP of which the rule is going to stored.

 .Parameter -RuleName
  Rule name

 .Parameter -RuleDisplayName
  Rule Display Name

 .Parameter -$Category
  The Rule category. For list of valid categories, please refer to: https://msdn.microsoft.com/en-au/library/microsoft.enterprisemanagement.configuration.managementpackcategorytype.aspx

 .Parameter -ClassName
  Monitoring Class Name

 .Parameter -DataSourceModules
  An array containing one or more OpsMgrExtended.ModuleConfiguration objects that define the Data Source modules of the rule.

 .Parameter -ConditionDetectionModule
  Optional parameter. A OpsMgrExtended.ModuleConfiguration object that defines the Condition Detection module of the rule.

 .Parameter -WriteActionModules
  An array containing one or more OpsMgrExtended.ModuleConfiguration objects that define the Write Action modules of the rule.

 .Parameter -Disabled
  Specify if the rule is disabled by default.

 .Parameter -IncreaseMPVersion
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a performance colleciton rule with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Management Pack Name: "TYANG.Lab.Test"
   Rule Name: "Test.Performance.Collection.Rule"
   Rule Display Name: "Test Performance Collection Rule"
   Category: "PerformanceCollection"
   Monitoring Class name: "Microsoft.Windows.Server.OperatingSystem"
   Data Source Module Type Name: "System.Performance.DataProvider"
   Data Source Module Configuration:
	"
	<ComputerName />
	<CounterName>% Processor Time</CounterName>
	<ObjectName>Processor</ObjectName>
	<InstanceName>_Total</InstanceName>
	<AllInstances>true</AllInstances>
	<Frequency>300</Frequency>
	"
   Write Action Module Type #1 Name: 'Microsoft.SystemCenter.CollectPerformanceData'
   Write Action Module Type #2 Name: 'Microsoft.SystemCenter.DataWarehouse.PublishPerformanceData'

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  
  $arrDataSourceModules = @()
  $DAConfig = @"
<ComputerName />
<CounterName>% Processor Time</CounterName>
<ObjectName>Processor</ObjectName>
<InstanceName>_Total</InstanceName>
<AllInstances>true</AllInstances>
<Frequency>300</Frequency>
"@
  $DataSourceConfiguration = New-OMModuleConfiguration -ModuleTypeName "System.Performance.DataProvider" -Configuration $DAConfig -MemberModuleName "DS"
  $DataSourceConfiguration.MemberModuleName = "DS"
  $arrDataSourceModules += $DataSourceConfiguration
  
  $arrWriteActionModules = @()
  $WAWriteToDBConfiguration = New-OMModuleConfiguration -ModuleTypeName "Microsoft.SystemCenter.CollectPerformanceData" -MemberModuleName "WriteToDB"
  $WAWriteToDWConfiguration = New-OMModuleConfiguration -ModuleTypeName "Microsoft.SystemCenter.DataWarehouse.PublishPerformanceData" -MemberModuleName "WriteToDW"
  $arrWriteActionModules += $WAWriteToDBConfiguration
  $arrWriteActionModules += $WAWriteToDWConfiguration

  New-OMRule -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -MPName "TYANG.Lab.Test" -RuleName "Test.Performance.Collection.Rule" -RuleDisplayName "Test Performance Collection Rule" -Category "PerformanceCollection" -ClassName "Microsoft.Windows.Server.OperatingSystem" -DataSourceModules $arrDataSourceModules -WriteActionModules $arrWriteActionModules

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create an event alert rule with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Management Pack Name: "TYANG.Lab.Test"
   Rule Name: "Test.Event.Alert.Rule"
   Rule Display Name: "Test Event Alert Rule"
   Category: "Alert"
   Monitoring Class name: "Microsoft.Windows.Server.OperatingSystem"
   Data Source Module Type Name: "Microsoft.Windows.EventProvider"
   Data Source Module Configuration:
	"
<LogName>System</LogName>
<Expression>
    <And>
    <Expression>
        <SimpleExpression>
        <ValueExpression>
            <XPathQuery Type="UnsignedInteger">EventDisplayNumber</XPathQuery>
        </ValueExpression>
        <Operator>Equal</Operator>
        <ValueExpression>
            <Value Type="UnsignedInteger">11</Value>
        </ValueExpression>
        </SimpleExpression>
    </Expression>
    <Expression>
        <RegExExpression>
        <ValueExpression>
            <XPathQuery Type="String">PublisherName</XPathQuery>
        </ValueExpression>
        <Operator>ContainsSubstring</Operator>
        <Pattern>Disk</Pattern>
        </RegExExpression>
    </Expression>
    <Expression>
        <SimpleExpression>
        <ValueExpression>
            <XPathQuery Type="Integer">EventLevel</XPathQuery>
        </ValueExpression>
        <Operator>Equal</Operator>
        <ValueExpression>
            <Value Type="Integer">1</Value>
        </ValueExpression>
        </SimpleExpression>
    </Expression>
    </And>
</Expression>
	"
   Write Action Module: 'System.Health.GenerateAlert'
   Write Action Module Configuration:
"
<Priority>$iAlertPriority</Priority>
<Severity>$iAlertSeverity</Severity>
<AlertName />
<AlertDescription />
<AlertOwner />
<AlertMessageId>`$MPElement[Name="$RuleName.AlertMessage"]$</AlertMessageId>
<AlertParameters>
    <AlertParameter1>`$Data/LoggingComputer$</AlertParameter1>
    <AlertParameter2>`$Data/EventDescription$</AlertParameter2>
</AlertParameters>
"
   Alert Name: "Windows Disk Controller Error"
   Alert Description:
"
Computer: {0}
Event Description: {1}
"
   Disabled by default
   Increase Management Pack version by 0.0.0.1

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  $arrDataSourceModules = @()
  
  $DAConfig = @"
<LogName>System</LogName>
<Expression>
    <And>
    <Expression>
        <SimpleExpression>
        <ValueExpression>
            <XPathQuery Type="UnsignedInteger">EventDisplayNumber</XPathQuery>
        </ValueExpression>
        <Operator>Equal</Operator>
        <ValueExpression>
            <Value Type="UnsignedInteger">11</Value>
        </ValueExpression>
        </SimpleExpression>
    </Expression>
    <Expression>
        <RegExExpression>
        <ValueExpression>
            <XPathQuery Type="String">PublisherName</XPathQuery>
        </ValueExpression>
        <Operator>ContainsSubstring</Operator>
        <Pattern>Disk</Pattern>
        </RegExExpression>
    </Expression>
    <Expression>
        <SimpleExpression>
        <ValueExpression>
            <XPathQuery Type="Integer">EventLevel</XPathQuery>
        </ValueExpression>
        <Operator>Equal</Operator>
        <ValueExpression>
            <Value Type="Integer">1</Value>
        </ValueExpression>
        </SimpleExpression>
    </Expression>
    </And>
</Expression>
"@
  $DataSourceConfiguration = New-OMModuleConfiguration -ModuleTypeName "Microsoft.Windows.EventProvider" -Configuration $DAConfig -MemberModuleName "DS"
  $arrDataSourceModules += $DataSourceConfiguration
  
  $arrWriteActionModules = @()
  $AlertWAConfig = @"
<Priority>$iAlertPriority</Priority>
<Severity>$iAlertSeverity</Severity>
<AlertName />
<AlertDescription />
<AlertOwner />
<AlertMessageId>`$MPElement[Name="$RuleName.AlertMessage"]$</AlertMessageId>
<AlertParameters>
    <AlertParameter1>`$Data/LoggingComputer$</AlertParameter1>
    <AlertParameter2>`$Data/EventDescription$</AlertParameter2>
</AlertParameters>
"@
  $WAAlertConfiguration = New-OMModuleConfiguration -ModuleTypeName "System.Health.GenerateAlert" -MemberModuleName "Alert" -Configuration $AlertWAConfig
  $arrWriteActionModules += $WAAlertConfiguration

  $arrAlertConfigurations = @()
  $StringResource = "Test.Event.Alert.Rule.AlertMessage"
  $AlertDescription = @"
Computer: {0}
Event Description: {1}
"@
	$AlertConfiguration = New-OMAlertConfiguration -AlertName "Windows Disk Controller Error" -AlertDescription $AlertDescription -StringResource $StringResource
	$arrAlertConfigurations += $AlertConfiguration

  New-OMRule -SDKConnection $SDKConnection -MPName "TYANG.Lab.Test" -RuleName "Test.Performance.Collection.Rule" -RuleDisplayName "Test Performance Collection Rule" -Category "Alert" -ClassName "Microsoft.Windows.Server.OperatingSystem" -DataSourceModules $arrDataSourceModules -WriteActionModules $arrWriteActionModules -Remotable $false -GenerateAlert $true -AlertConfigurations $arrAlertConfigurations -Disabled $true  -IncreaseMPVersion $true

 .Example
  # Connect to OpsMgr management group via SMA connection object "OpsMgrSDK_TYANG" and then create a performance colleciton rule with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Management Pack Name: "TYANG.Lab.Test"
   Rule Name: "Test.SQL.Performance.Collection.Rule"
   Rule Display Name: "Test SQL Performance Collection Rule"
   Category: "PerformanceCollection"
   Monitoring Class name: "Microsoft.SQLServer.2012.DBEngine"
   Data Source Module Type Name: "System.Performance.DataProvider"
   Data Source Module RunAs Profile MP: "Microsoft.SQLServer.Library"
   Data Source Module RunAs Profile Name: "Microsoft.SQLServer.SQLDefaultAccount"
   Data Source Module Configuration:
	"
	<ComputerName />
	<CounterName>Lock Requests/sec</CounterName>
	<ObjectName>SQLServer:Locks</ObjectName>
	<InstanceName>_Total</InstanceName>
	<AllInstances>true</AllInstances>
	<Frequency>300</Frequency>
	"
   Write Action Module Type #1 Name: 'Microsoft.SystemCenter.CollectPerformanceData'
   Write Action Module Type #2 Name: 'Microsoft.SystemCenter.DataWarehouse.PublishPerformanceData'

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  
  $arrDataSourceModules = @()
  $DAConfig = @"
<ComputerName />
<CounterName>% Processor Time</CounterName>
<ObjectName>Processor</ObjectName>
<InstanceName>_Total</InstanceName>
<AllInstances>true</AllInstances>
<Frequency>300</Frequency>
"@
  $DataSourceConfiguration = New-OMModuleConfiguration -ModuleTypeName "System.Performance.DataProvider" -Configuration $DAConfig -MemberModuleName "DS" -RunAsMPName "Microsoft.SQLServer.Library" -RunAsName "Microsoft.SQLServer.SQLDefaultAccount"
  $DataSourceConfiguration.MemberModuleName = "DS"
  $arrDataSourceModules += $DataSourceConfiguration
  
  $arrWriteActionModules = @()
  $WAWriteToDBConfiguration = New-OMModuleConfiguration -ModuleTypeName "Microsoft.SystemCenter.CollectPerformanceData" -MemberModuleName "WriteToDB"
  $WAWriteToDWConfiguration = New-OMModuleConfiguration -ModuleTypeName "Microsoft.SystemCenter.DataWarehouse.PublishPerformanceData" -MemberModuleName "WriteToDW"
  $arrWriteActionModules += $WAWriteToDBConfiguration
  $arrWriteActionModules += $WAWriteToDWConfiguration

  New-OMRule -SDKConnection $SDKConnection -MPName "TYANG.Lab.Test" -RuleName "Test.SQL.Performance.Collection.Rule" -RuleDisplayName "Test SQL Performance Collection Rule" -Category "PerformanceCollection" -ClassName "Microsoft.SQLServer.2012.DBEngine" -DataSourceModules $arrDataSourceModules -WriteActionModules $arrWriteActionModules
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')]
		[Alias('Connection','c')]
		[ValidateNotNullOrEmpty()]
		[Object]$SDKConnection,

		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')]
		[Alias('DAS','Server','s')]
		[ValidateNotNullOrEmpty()]
		[String]$SDK,

        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')]
		[Alias('u')]
		[ValidateNotNullOrEmpty()]
		[String]$Username = $null,

        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')]
		[Alias('p')]
		[ValidateNotNullOrEmpty()]
		[SecureString]$Password = $null,

        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')]
		[ValidateNotNullOrEmpty()]
		[String]$MPName,

        [Parameter(Mandatory=$true,HelpMessage='Please enter rule name')]
		[ValidateNotNullOrEmpty()]
		[String]$RuleName,

        [Parameter(Mandatory=$true,HelpMessage='Please enter rule display name')]
		[ValidateNotNullOrEmpty()]
		[String]$RuleDisplayName,

        [Parameter(Mandatory=$true,HelpMessage='Please enter rule Category')]
		[ValidateSet("Alert","AvailabilityHealth","ConfigurationHealth","ConnectorFramework","Custom","Discovery","DSIntegration","EventCollection","ExceptionMonitoring","Maintenance","Notification","Operations","PerformanceCollection","PerformanceHealth","SecurityHealth","SoftwareAndUpdates","StateCollection","System")]
		[String]$Category,

        [Parameter(Mandatory=$true,HelpMessage='Please enter monitoring class name')]
		[ValidateNotNullOrEmpty()]
		[String]$ClassName,

        [Parameter(Mandatory=$true,HelpMessage='Please specify the Data source modules configurations')]
		[Alias('DS')]
		[ValidateNotNullOrEmpty()]
		[OpsMgrExtended.ModuleConfiguration[]]$DataSourceModules,

        [Parameter(Mandatory=$false,HelpMessage='Please specify the condition detection module configuration')]
		[Alias('CD')]
		[ValidateNotNullOrEmpty()]
		[OpsMgrExtended.ModuleConfiguration]$ConditionDetectionModule,

        [Parameter(Mandatory=$true,HelpMessage='Please specify the Write Action modules configurations')]
		[Alias('W')]
		[ValidateNotNullOrEmpty()]
		[OpsMgrExtended.ModuleConfiguration[]]$WriteActionModules,

		[Parameter(Mandatory=$false,HelpMessage='Please specify if the rule is generating alerts')]
		[Alias('alert')]
		[ValidateNotNullOrEmpty()]
		[Boolean]$GenerateAlert = $false,

		[Parameter(Mandatory=$false,HelpMessage='Please specify the alert configurations')]
		[ValidateScript({if ($GenerateAlert -eq $true){$_.count -gt 0}})]
		[OpsMgrExtended.AlertConfiguration[]]$AlertConfigurations,

		[Parameter(Mandatory=$false,HelpMessage='Please specify if the rule is disabled by default')]
		[ValidateNotNullOrEmpty()]
		[Boolean]$Disabled = $false,

		[Parameter(Mandatory=$false,HelpMessage='Please specify if the rule remotable')]
		[ValidateNotNullOrEmpty()]
		[Boolean]$Remotable = $true,

        [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')]
		[ValidateNotNullOrEmpty()]
		[Boolean]$IncreaseMPVersion
    )
    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the unsealed MP
	Write-Verbose "Getting managemnet pack '$MPName'..."
    $strMPquery = "Name = '$MPName'"
    $mpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strMPquery)
    $MP = $MG.GetManagementPacks($mpCriteria)[0]

    If ($MP)
    {
        #MP found, now check if it is sealed
        If ($MP.sealed)
        {
            Write-Error 'Unable to save to the management pack specified. It is sealed. Please specify an unsealed MP.'
            return $false
        }
    } else {
        Write-Error 'The management pack specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

    #Get the monitoring Class
	Write-Verbose "getting the target monitoring class"
    $strMCQuery = "Name = '$ClassName'"
    $mcCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria($strMCQuery)
    $MonitoringClass = $MG.GetMonitoringClasses($mcCriteria)[0]
    if (!$MonitoringClass)
    {
        Write-Error 'The monitoring class specified cannot be found. please make sure the correct name is specified.'
        return $false
    }

    #Create new rule
	If ($Disabled -eq $true)
	{
		Write-Verbose "the Rule will be disabled by default"
		$EnabledProperty = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::false
	} else {
		Write-Verbose "the Rule will be enabled by default"
		$EnabledProperty = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
	}
	Write-Verbose "Craeting the rule '$RuleName'"
    $newRule = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackRule($mp, $RuleName)
    $newRule.DisplayName = $RuleDisplayName
	$newRule.Enabled = $EnabledProperty
	$newRule.Remotable = $Remotable
    $newRule.Target = $MonitoringClass
    $newRule.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::$Category

    #Configure Data Source modules
	Write-Verbose "Adding data source modules"
    Foreach ($DS in $DataSourceModules)
    {
        $DSModuleTypeName = $DS.ModuleTypeName
		Write-Verbose "Processing Data Source module $DSModuleTypeName"
        $DSModuleConfiguration = $DS.Configuration
		Write-Verbose "Module configuration for '$DSModuleTypeName':"
		Write-Verbose $DSModuleConfiguration
        $DSMemberModuleName = $DS.MemberModuleName
        $DSModuleType = $MG.GetMonitoringModuleTypes($DSModuleTypeName)[0]
		if (!$DSModuleType)
		{
			Write-Error 'Unable to find the data source module $($DS.ModuleTypeName). please make sure the correct name is specified and the management pack containing the data source module is loaded in your management group.'
			return $false
		}
        $DSModule = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDataSourceModule($newRule, $DSMemberModuleName)
        $DSModule.TypeID = $DSModuleType
        if ($DSModuleConfiguration -ne $null)
        {
            $DSModule.Configuration = $DSModuleConfiguration
        }
		if($DS.RunAsMPName -ne "" -and $DS.RunAsName -ne "")
		{
			Write-Verbose "Data Source module '$DSModuleTypeName' requires alternative RunAs profile."
			$DSRunAsMP = $MG.GetManagementPacks($DS.RunAsMPName)[0]
			$DSRunAsProfile = $DSRunAsMP.GetSecureReference($DS.RunAsName)
			if (!$DSRunAsProfile)
			{
				Write-Error "Unable to find the RunAs profile '$($DS.RunAsName)' from MP '$($DS.RunAsMPName)'."
				return $false
			}
			Write-Verbose "Data Source module '$DSModuleTypeName' is going to use Secure Reference '$($DSRunAsProfile.DisplayName)'."
			$DSModule.RunAs = $DSRunAsProfile
		}
        $newRule.DataSourceCollection.Add($DSModule)
    }

    #Configure Condition Detection Module
    If ($ConditionDetectionModule)
    {
        Write-Verbose "Adding Condition Detection module"
		$CDModuleTypeName = $ConditionDetectionModule.ModuleTypeName
		Write-Verbose "Processing Condition Detection module $CDModuleTypeName"
        $CDModuleConfiguration = $ConditionDetectionModule.Configuration
		Write-Verbose "Module configuration for '$CDModuleTypeName':"
		Write-Verbose $CDModuleConfiguration
        $CDMemberModuleName = $ConditionDetectionModule.MemberModuleName
        $CDModuleType = $MG.GetMonitoringModuleTypes($CDModuleTypeName)[0]
		if (!$CDModuleType)
		{
			Write-Error 'Unable to find the condition detection module $($ConditionDetectionModule.ModuleTypeName). please make sure the correct name is specified and the management pack containing the condition detection module is loaded in your management group.'
			return $false
		}
        $CDModule = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackConditionDetectionModule($newRule, $CDMemberModuleName)
        $CDModule.TypeID = $CDModuleType
        If ($CDModuleConfiguration -ne $null)
        {
            $CDModule.Configuration = $CDModuleConfiguration
        }
		if($ConditionDetectionModule.RunAsMPName -ne "" -and $ConditionDetectionModule.RunAsName -ne "")
		{
			Write-Verbose "Condition Detection module '$CDModuleTypeName' requires alternative RunAs profile."
			$CDRunAsMP = $MG.GetManagementPacks($ConditionDetectionModule.RunAsMPName)[0]
			$CDRunAsProfile = $CDRunAsMP.GetSecureReference($ConditionDetectionModule.RunAsName)
			if (!$CDRunAsProfile)
			{
				Write-Error "Unable to find the RunAs profile '$($ConditionDetectionModule.RunAsName)' from MP '$($ConditionDetectionModule.RunAsMPName)'."
				return $false
			}
			Write-Verbose "Condition Detection module '$CDModuleTypeName' is going to use Secure Reference '$($CDRunAsProfile.DisplayName)'."
			$CDModule.RunAs = $CDRunAsProfile
		}
        $newRule.ConditionDetection = $CDModule
    } else {
		Write-Verbose "No Condition Detection module to process"
	}

    #Configure Write Action modules
	Write-Verbose "Adding Write Action modules"
    Foreach ($WA in $WriteActionModules)
    {
        $WAModuleTypeName = $WA.ModuleTypeName
		Write-Verbose "Processing Write Action module '$WAModuleTypeName'"
		$WAModuleConfiguration = $WA.Configuration
		Write-Verbose "Module configuration for '$WAModuleTypeName':"
		Write-Verbose $WAModuleConfiguration
        $WAMemberModuleName = $WA.MemberModuleName
        $WAModuleType = $MG.GetMonitoringModuleTypes($WAModuleTypeName)[0]
		if (!$WAModuleType)
		{
			Write-Error 'Unable to find the write action module $($WA.ModuleTypeName). please make sure the correct name is specified and the management pack containing the write action module is loaded in your management group.'
			return $false
		}
        $WAModule = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackWriteActionModule($newRule, $WAMemberModuleName)
        $WAModule.TypeID = $WAModuleType
        if ($WAModuleConfiguration -ne $null)
        {
            $WAModule.Configuration = $WAModuleConfiguration
        }
		if($WA.RunAsMPName -ne "" -and $WA.RunAsName -ne "")
		{
			Write-Verbose "Write Action module '$WAModuleTypeName' requires alternative RunAs profile."
			$WARunAsMP = $MG.GetManagementPacks($WA.RunAsMPName)[0]
			$WARunAsProfile = $WARunAsMP.GetSecureReference($WA.RunAsName)
			if (!$WARunAsProfile)
			{
				Write-Error "Unable to find the RunAs profile '$($WA.RunAsName)' from MP '$($WA.RunAsMPName)'."
				return $false
			}
			Write-Verbose "Write Action module '$WAModuleTypeName' is going to use Secure Reference '$($WARunAsProfile.DisplayName)'."
			$WAModule.RunAs = $WARunAsProfile
		}
        $newRule.WriteActionCollection.Add($WAModule)
    }
	
	#Configure alerts
	
	If ($GenerateAlert -eq $true)
	{
		Write-Verbose "Configuring alerts settings"
		Foreach ($AlertConfig in $AlertConfigurations)
		{
			#work out the language code
			If ($AlertConfig.LanguagePackID -ne $NULl)
			{
				#If the Language Pack ID is specified in the AlertConfiguration object, use the one specified
				$LanguagePackCode = $AlertConfig.LanguagePackID
			} elseif ($mp.DefaultLanguageCode -ne $NULL) {
				#If the Language Pack ID is not specified in AlertConfiguration object, use the default language code
				$LanguagePackCode = $mp.DefaultLanguageCode
			} else {
				#If the Language Pack ID is not specified and the mp does not have a default language pack, use ENU
				$LanguagePackCode = "ENU"
			}
			Write-Verbose "Creating String Resource '$($AlertConfig.StringResourceName)'"
			$StringResource = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackStringResource($mp, $AlertConfig.StringResourceName)
			$AlertDisplayString = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDisplayString($StringResource, $LanguagePackCode)
			$AlertDisplayString.Name = $AlertConfig.AlertName
			$AlertDisplayString.Description = $AlertConfig.AlertDescription
		}
	} else {
		Write-Verbose "No need to configure alert settings."
	}

    #Increase MP version
    If ($IncreaseMPVersion)
    {
        $CurrentVersion = $MP.Version.Tostring()
        $vIncrement = $CurrentVersion.Split('.')
        $vIncrement[$vIncrement.Length - 1] = ([System.Int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
        $NewVersion = ([System.String]::Join('.', $vIncrement))
        $MP.Version = $NewVersion
    }

    #Verify and save the monitor
	Write-Verbose "Verify and save managemnet pack '$MPName'"
    Try {
        $MP.verify()
        $MP.AcceptChanges()
        $Result = $true
		Write-Verbose "Rule '$RuleName' successfully created in Management Pack '$MPName'($($MP.Version))."
    } Catch {
        Write-Error $_.Exception.InnerException
		$Result = $false
		$MP.RejectChanges()
        Write-Error "Unable to create Rule $RuleName in management pack $MPName."
    }
    $Result
}
Function New-OMWindowsServiceTemplateInstance
{
<# 
 .Synopsis
  Create a Windows Service monitoring template instance in OpsMgr.

 .Description
  Create a Windows Service monitoring template instance in OpsMgr using OpsMgr SDK. A boolean value $true will be returned if the monitoring template instance creation has been successful, otherwise, a boolean value of $false is returned if any there are any errors occurred during the creation process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -MPName
  Name for the unsealed MP of which the Windows Service monitoring template instance is going to stored.

 .Parameter -DisplayName
  The Windows Service Template instance display name

 .Parameter -Description
  The Windows Service Template instance description

 .Parameter -ServiceName
  The name of the service that the template instance should monitor

 .Parameter -TargetGroupName
  The name of the target group for the template instance

 .Parameter -LocaleId
  The Locale ID for the language pack items. This is an optional parameter, if not specifiied, the value "ENU" is used.

 .Parameter -CheckStartupType
  Specify if monitor only automatic service. This is an optional parameter, if not specifiied, the value is set to $true.

 .Parameter -PercentCPU
  Specify the threshold for CPU Usage Percentage. This is an optional parameter, if not specifiied, the CPU Usage will not be monitored or collected.

 .Parameter -MemoryUsage
  Specify the threshold for Memory Usage (MB). This is an optional parameter, if not specifiied, the Memory Usage will not be monitored or collected.

 .Parameter -ConsecutiveSampleCount
  Specify the the number of (consecutive) samples for the CPU and Memory counters, This is an optional parameter. if not specified, the value is set to 2

 .Parameter -PollingInterval
  Specify sample polling interval (in seconds). This is an optional parameter, if not specifiied, the value is set to 300

 .Parameter -IncreaseMPVersion
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a Windows Service monitor template instance with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Management Pack Name: "TYANG.Lab.Test"
   Template Instance Display Name: "Monitor Windows Time Service"
   Service Name: "w32time"
   Target Group Name: "Microsoft.Windows.Server.6.2.ComputerGroup"
   Check Service Startup Type: $false
   Do not collect performance data
  
  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  New-OMWindowsServiceTemplateInstance -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -MPName "TYANG.Lab.Test" -DisplayName "Monitor Windows Time Service" ServiceName = "w32time" -TargetGroupName "Microsoft.Windows.Server.6.2.ComputerGroup" -CheckStartupType $false

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a Windows Service monitor template instance with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Management Pack Name: "TYANG.Lab.Test"
   Template Instance Display Name: "Monitor Windows Time Service"
   Template Instance Description: "Provide Monitoring for Windows Time Service"
   Service Name: "w32time"
   Target Group Name: "Microsoft.Windows.Server.6.2.ComputerGroup"
   CPU Usage % Threshold: 40%
   Memory Usage MB: 200
   Consecutive Sample: 3
   Polling Interval (Seconds): 600
   Increase Management Pack version by 0.0.0.1

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  New-OMWindowsServiceTemplateInstance -SDKConnection $SDKConnection -MPName "TYANG.Lab.Test" -DisplayName "Monitor Windows Time Service" -Description "Provide Monitoring for Windows Time Service" -ServiceName = "w32time" -TargetGroupName "Microsoft.Windows.Server.6.2.ComputerGroup" -PercentCPU 40 -MemoryUsage 200 -ConsecutiveSampleCount 3 -PollIntervalInSeconds 600 -IncreaseMPVersion $true
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')][ValidateNotNullOrEmpty()][String]$MPName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Template Instance Display Name')][ValidateNotNullOrEmpty()][String]$DisplayName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter Template Instance description')][String]$Description,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the service name')][ValidateNotNullOrEmpty()][String]$ServiceName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the Target Group name')][ValidateNotNullOrEmpty()][String]$TargetGroupName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the Management Pack Locale ID')][ValidateNotNullOrEmpty()][String]$LocaleId="ENU",
        [Parameter(Mandatory=$false,HelpMessage='Please specify if should check service startup type. When $true is specified, service monitors only monitor services with startup type of Automatic.')][String]$CheckStartupType=$true,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the Percent Processor Time Threshold (CPU Usage in %)')][Int]$PercentCPU,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the Memory Private Bytes Threshold (Memory Usage in MB)')][Int]$MemoryUsage,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the Consecutive Sample Count (Number of samples)')][Int]$ConsecutiveSampleCount=2,
		[Parameter(Mandatory=$false,HelpMessage='Please enter the Performance Counter Sample polling interval (in seconds)')][Int]$PollIntervalInSeconds=300,
        [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')][Boolean]$IncreaseMPVersion = $false

    )

    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the unsealed MP
    Write-Verbose "Getting destination MP '$MPName'..."
    $strMPquery = "Name = '$MPName'"
    $mpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strMPquery)
    $MP = $MG.GetManagementPacks($mpCriteria)[0]

    If ($MP)
    {
        #MP found, now check if it is sealed
        If ($MP.sealed)
        {
            Write-Error 'Unable to save to the management pack specified. It is sealed. Please specify an unsealed MP.'
            return false
        }
    } else {
        Write-Error 'The management pack specified cannot be found. please make sure the correct name is specified.'
        return false
    }

    #Get the target group Id
    Write-Verbose "Getting Target group '$TargetGroupName'..."
    $GroupClassQuery = New-object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria("Name = '$TargetGroupName'")
    $TargetGroupClass = $MG.GetMonitoringClasses($GroupClassQuery)[0]
    If ($TargetGroupClass -eq $Null)
    {
        Write-Error "Unable to find the target group class with name '$TargetGroupName'."
        Return $false
    }
    $TargetGroupInstances = $MG.GetMonitoringObjects($TargetGroupClass)
    If ($TargetGroupInstances.count -eq 0)
    {
        Write-Error "No group is found with name '$TargetGroupName'. Please make sure the group discovery is properly configured."
        Return $false
    } elseif ($TargetGroupInstances.Count -gt 1) {
        Write-Error "Multiple monitoring objects found for the monitoring class '$TargetGroupName', which means this class is not an instance group because groups are singleton objects, there should only be one instance."
        Return $false
    } else {
        $TargetGroupId = $TargetGroupInstances[0].Id
    }

    #Workout the value for $IsProcessorTimeMonitored and $IsPrivateBytesMonitored
    If ($PercentCPU -gt 0)
    {
        Write-Verbose "CPU Usage (percentage): $PercentCPU"
        $IsProcessorTimeMonitored = "true"
    } else {
        Write-Verbose "CPU Usage will not be monitored."
        $IsProcessorTimeMonitored = "false"
        $PercentCPU = 40
    }
    if ($MemoryUsage -gt 0)
    {
        Write-Verbose "Memory Usage (MB): $MemoryUsage"
        $IsPrivateBytesMonitored = "true"
        #convert bytes to MB
        $MemoryUsage = $MemoryUsage * 1000000
    } else {
        Write-Verbose "Memory Usage will not be monitored."
        $IsPrivateBytesMonitored = "false"
        $MemoryUsage = 15000000
    }

    #Get the template
    Write-Verbose "Getting the Windows Service monitoring template..."
    $strTemplatequery = "Name = 'Microsoft.SystemCenter.NTService.OwnProcess.Template'"
    $TemplateCriteria = New-object Microsoft.EnterpriseManagement.Configuration.ManagementPackTemplateCriteria($strTemplatequery)
    $WinServiceTemplate = $MG.GetMonitoringTemplates($TemplateCriteria)[0]
    if (!$WinServiceTemplate)
    {
        Write-Error "The Windows Service Monitoring Template specified cannot be found. please make sure the 'Windows Service Library' management pack exists in your management group."
        return $false
    }

    #Generate template instance configuration
    $TypeID = [GUID]::NewGuid().ToString().Replace("-","")
    $TypeName = "ServiceStateProbePage_$TypeID"
    $StringBuilder = New-Object System.Text.StringBuilder
    $configurationWriter = [System.Xml.XmlWriter]::Create($StringBuilder)
    $configurationWriter.WriteStartElement("Configuration");
    $configurationWriter.WriteElementString("TypeName", $TypeName);
    $configurationWriter.WriteElementString("ServiceName", $ServiceName);
    $configurationWriter.WriteElementString("LocaleId", $LocaleId);
    $configurationWriter.WriteElementString("TypeDisplayName", $DisplayName);
    $configurationWriter.WriteElementString("TypeDescription", $Description);
    $configurationWriter.WriteElementString("TargetGroupGUID", $TargetGroupId);
    $configurationWriter.WriteElementString("CheckStartupType", $CheckStartupType.ToString().ToLower());
    $configurationWriter.WriteElementString("IsProcessorTimeMonitored", $IsProcessorTimeMonitored);
    $configurationWriter.WriteElementString("PercentProcessorTimeThreshold", $PercentCPU);
    $configurationWriter.WriteElementString("IsPrivateBytesMonitored", $IsPrivateBytesMonitored);
    $configurationWriter.WriteElementString("PrivateBytesThreshold", $MemoryUsage);
    $configurationWriter.WriteElementString("ConsecutiveSampleCount", $ConsecutiveSampleCount);
    $configurationWriter.WriteElementString("PollIntervalInSeconds", $PollIntervalInSeconds);
    $configurationWriter.WriteEndElement();
    $configurationWriter.Flush();
    $XmlWriter = New-Object Microsoft.EnterpriseManagement.Configuration.IO.ManagementPackXmlWriter([System.Xml.XmlWriter]::Create($StringBuilder))
    $strConfiguration = $StringBuilder.ToString()
    Write-Verbose "Template Instance Configuration:"
    Write-Verbose $strConfiguration
    #Create the template instance
    Write-Verbose "Creating the Windows Service template instance on management pack '$MPName'..."
    Try {
        [Void]$MP.ProcessMonitoringTemplate($WinServiceTemplate, $strConfiguration, "NTServiceTemplate_$TypeID", $DisplayName,$Description)
    } Catch {
        Write-Error $_.Exception.InnerException
        Return $False
    }
    #Increase MP version
    If ($IncreaseMPVersion)
    {
        Write-Verbose "the version of managemnet pack '$MPVersion' will be increased by 0.0.0.1"
        $CurrentVersion = $MP.Version.Tostring()
        $vIncrement = $CurrentVersion.Split('.')
        $vIncrement[$vIncrement.Length - 1] = ([System.Int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
        $NewVersion = ([System.String]::Join('.', $vIncrement))
        $MP.Version = $NewVersion
    }

    #Verify and save the monitor
    Try {
        $MP.verify()
        $MP.AcceptChanges()
        $Result = $true
		Write-Verbose "Windows Service template instance '$DisplayName' successfully created in Management Pack '$MPName'($($MP.Version))."
    } Catch {
        $Result = $false
		$MP.RejectChanges()
        Write-Error "Unable to create Windows Service template instance '$DisplayName' in management pack $MPName."
    }
    $Result
}
Function New-OMComputerGroupExplicitMember
{
<# 
 .Synopsis
  Add a computer to a computer group in OpsMgr.

 .Description
  Add a computer to a computer group in OpsMgr using OpsMgr SDK. The group discovery must be defined in an unsealed management pack in order for this function to work. A boolean value $true will be returned if the computer has been successfully added, otherwise, a boolean value of $false is returned if any there are any errors occurred during the process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -GroupName
  Computer Group name

 .Parameter -ComputerPrincipalName
  Computer Principal Name for the computer to be added to the computer group.

 .Parameter -IncreaseMPVersion (boolean)
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then add a Windows computer to a computer group by specifying individual parameters:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Computer Group Name: Test.Computer.Group
   Computer Principal Name: Computer01.yourcompany.com

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  New-OMComputerGroupExplicitMember -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -GroupName "Test.Computer.Group" -ComputerPrincipalName "Computer01.yourcompany.com"

 .Example
   # Connect to OpsMgr management group via management server "OpsMgrMS01" and then add a Windows computer to a computer group by using a SMA Connection Object:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Computer Group Name: Test.Computer.Group
   Computer Principal Name: Computer01.yourcompany.com
   Increase Management Pack version by 0.0.0.1
  
  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  New-OMComputerGroupExplicitMember -SDKConnection $SDKConnection -GroupName "Test.Computer.Group" -ComputerPrincipalName "Computer01.yourcompany.com" -IncreaseMPVersion $true
#>
	PARAM (
    [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][System.Object]$SDKConnection,
	[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][System.String]$SDK,
    [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][System.String]$Username = $null,
    [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
    [Parameter(Mandatory=$true,HelpMessage='Please enter Computer Group name')][Alias('Group')][System.String]$GroupName,
	[Parameter(Mandatory=$true,HelpMessage='Please enter Computer Principal Name')][Alias('Computer')][System.String]$ComputerPrincipalName,
    [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')][System.Boolean]$IncreaseMPVersion=$false
    )

	#Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.UserName
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}
        
	#Get the windows computer object
	Write-Verbose "Getting the Windows computer monitoring object for '$ComputerPrincipalName'"
	$WinComputerObjectCriteria = New-Object Microsoft.EnterpriseManagement.Monitoring.MonitoringObjectGenericCriteria("FullName = 'Microsoft.Windows.Computer:$ComputerPrincipalName'")
	$WinComputer = $MG.GetMonitoringObjects($WinComputerObjectCriteria)[0]
	If ($WinComputer -eq $null)
	{
		Write-Error "Unable to find the Microsoft.Windows.Computer object for '$ComputerPrincipalName'."
		Return $false
	}
	$WinComputerID = $WinComputer.Id.ToString()
	Write-Verbose "Monitoring Object ID for '$ComputerPrincipalName': '$WinComputerID'"

	#Get the group
	Write-Verbose "Getting the computer group '$GroupName'."
	$ComputerGroupClassCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria("Name='$GroupName'")
	$ComputerGroupClass = $MG.GetMonitoringClasses($ComputerGroupClassCriteria)[0]
	If ($ComputerGroupClass -eq $null)
	{
		Write-Error "$GroupName is not found."
		Return $false
	}
	#Check if this monitoring class is actually a computer group
	Write-Verbose "Check if the group '$GroupName' is a computer group"
	$ComputerGroupBaseTypes = $ComputerGroupClass.GetBaseTypes()
	$bIsComputerGroup = $false
	Foreach ($item in $ComputerGroupBaseTypes)
	{
		If ($item.Id.Tostring() -eq '0c363342-717b-5471-3aa5-9de3df073f2a')
		{
			$bIsComputerGroup = $true
		}
	}
	If ($bIsComputerGroup -eq $false)
	{
		Write-Error "$GroupName is not a computer group"
		Return $false
	}

	#Get Group object
	$ComputerGroupObject = $MG.GetMonitoringObjects($ComputerGroupClass)[0]

	#Check if the monitoring object is already member of the group
	Write-Verbose "Checking if the computer '$ComputerPrincipalName' is already a member of the group."
	$ExistingMembers = $ComputerGroupObject.GetRelatedMonitoringObjects($WinComputerObjectCriteria, [Microsoft.EnterpriseManagement.Common.TraversalDepth]::OneLevel)
	if ($ExistingMembers.count -gt 0)
	{
		Write-Warning "The Computer '$ComputerPrincipalName' is already a member of the computer group $GroupName. No need to add it again. Aborting."
		Return $true
	}

	#Get Group population discovrey
	Write-Verbose "Getting the group discovery rule"
	$ComputerGroupDiscoveries = $ComputerGroupObject.GetMonitoringDiscoveries()
	$iGroupPopDiscoveryCount = 0
	$GroupPopDiscovery = $null
	Foreach ($Discovery in $ComputerGroupDiscoveries)
	{
		$DiscoveryDS = $Discovery.DataSource
		#Microsft.SystemCenter.GroupPopulator ID is 488000ef-e20b-1ac4-d3b1-9d679435e1d7
		If ($DiscoveryDS.TypeID.Id.ToString() -eq '488000ef-e20b-1ac4-d3b1-9d679435e1d7')
		{
			#This data source module is using Microsft.SystemCenter.GroupPopulator
			$iGroupPopDiscoveryCount = $iGroupPopDiscoveryCount + 1
			$GroupPopDiscovery = $Discovery
			Write-Verbose "Group Populator discovery found: '$($GroupPopDiscovery.Name)'"
		}
	}
	If ($iGroupPopDiscoveryCount.count -eq 0)
	{
		Write-Error "No group populator discovery found for $GroupName."
		Return $false
	}

	If ($iGroupPopDiscoveryCount.count -gt 1)
	{
		Write-Error "$GroupName has multiple discoveries using Microsft.SystemCenter.GroupPopulator Module type."
		Return $false
	}

	#Get the MP of where the group populator discovery is defined
	$GroupPopDiscoveryMP = $GroupPopDiscovery.GetManagementPack()
	Write-Verbose "The group populator discovery '$($GroupPopDiscovery.Name)' is defined in management pack '$($GroupPopDiscoveryMP.Name)'."

	#Write Error and exit if the MP is sealed
	If ($GroupPopDiscoveryMP.sealed -eq $true)
	{
		Write-Error "Unable to update the group discovery because it is defined in a sealed MP: '$($GroupPopDiscoveryMP.DisplayName)'."
		Return $false
	}
    
    #Updating the group discovery
	Write-Verbose "Updating the discovery data source configuration"
	$GroupDSConfig = $GroupPopDiscovery.Datasource.Configuration
	$GroupDSConfigXML = [XML]"<Configuration>$GroupDSConfig</Configuration>"

	#Detect if any MembershipRule segments contain existing static members
	$bComputerAdded = $false
	Foreach ($MembershipRule in $GroupDSConfigXML.Configuration.MembershipRules.MembershipRule)
	{
		If ($MembershipRule.IncludeList -ne $Null -and $bComputerAdded -eq $false)
		{
			#Add the monitoroing object ID of the Windows computer to the <IncludeList> node
			Write-Verbose "Adding '$ComputerPrincipalName' monitoring Object ID '$WinComputerID' to the <IncludeList> node in the group populator configuration"
			$NewMOId = $MembershipRule.IncludeList.AppendChild($GroupDSConfigXML.CreateElement("MonitoringObjectId"))
			$NewMOId.InnerText = $WinComputerID
			$bComputerAdded = $true
		}
	}

	#If none of the MembershipRule has <IncludeList segment>, create it in the first MembershipRule
	If ($bComputerAdded -eq $false)
	{
		If ($GroupDSConfigXML.Configuration.MembershipRules.MembershipRule -Is [System.Array])
        {
            Write-Verbose "Multiple Membership rules. creating <IncludeList> within the first <MembershipRule>"
            $IncludeListNode = $GroupDSConfigXML.Configuration.MembershipRules.MembershipRule[0].AppendChild($GroupDSConfigXML.CreateElement("IncludeList"))
        } else {
            Write-Verbose "There is only one Membership rule. creating <IncludeList> in it."
            $IncludeListNode = $GroupDSConfigXML.Configuration.MembershipRules.MembershipRule.AppendChild($GroupDSConfigXML.CreateElement("IncludeList"))
        }
		$NewMOId = $IncludeListNode.AppendChild($GroupDSConfigXML.CreateElement("MonitoringObjectId"))
		$NewMOId.InnerText = $WinComputerID
	}
	$UpdatedGroupPopConfig = $GroupDSConfigXML.Configuration.InnerXML

	#Increase MP version
	If ($IncreaseMPVersion)
	{
		$CurrentVersion = $GroupPopDiscoveryMP.Version.Tostring()
		$vIncrement = $CurrentVersion.Split('.')
		$vIncrement[$vIncrement.Length - 1] = ([System.Int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
		$NewVersion = ([System.String]::Join('.', $vIncrement))
		Write-Verbose "Increasing the group discovery MP version to $NewVersion"
		$GroupPopDiscoveryMP.Version = $NewVersion
	}

	#Updating the discovery
	Write-Verbose "Updating the group discovery"
	Try {
		$GroupPopDiscovery.Datasource.Configuration = $UpdatedGroupPopConfig
		$GroupPopDiscovery.Status = [Microsoft.EnterpriseManagement.Configuration.ManagementPackElementStatus]::PendingUpdate
		$GroupPopDiscoveryMP.AcceptChanges()
		$bComputerAdded = $true
		Write-Verbose "Done."
	} Catch {
        Write-Error $_.Exception.InnerException.Message
		$bComputerAdded = $false
	}
	$bComputerAdded
}
Function New-OMInstanceGroupExplicitMember
{
<# 
 .Synopsis
  Add a monitoring object to an instance group in OpsMgr.

 .Description
  Add a monitoring object to an instance group in OpsMgr using OpsMgr SDK. The group discovery must be defined in an unsealed management pack in order for this function to work. A boolean value $true will be returned if the monitoring object has been successfully added, otherwise, a boolean value of $false is returned if any there are any errors occurred during the process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -GroupName
  Computer Group name

 .Parameter -MonitoringObjectID
  Computer Principal Name for the unsealed MP of which the override is going to stored.

 .Parameter -IncreaseMPVersion (boolean)
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then add a monitoring object to an instance group by specifying individual parameters:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Instance Group Name: Test.Instance.Group
   Monitoring Object ID: fabfe649-921c-cf17-d198-0fba29cee9ff

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  New-OMInstanceGroupExplicitMember -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -GroupName "Test.Instance.Group" -MonitoringObjectID "fabfe649-921c-cf17-d198-0fba29cee9ff"

 .Example
   # Connect to OpsMgr management group via management server "OpsMgrMS01" and then add a monitoring object to an instance group by using a SMA Connection Object:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Instance Group Name: Test.Instance.Group
   Monitoring Object ID: fabfe649-921c-cf17-d198-0fba29cee9ff
   Increase Management Pack version by 0.0.0.1
  
  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  New-OMInstanceGroupExplicitMember -SDKConnection $SDKConnection -GroupName "Test.Instance.Group" -MonitoringObjectID "fabfe649-921c-cf17-d198-0fba29cee9ff" -IncreaseMPVersion $true
#>
	PARAM (
    [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][System.Object]$SDKConnection,
	[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][System.String]$SDK,
    [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][System.String]$Username = $null,
    [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
    [Parameter(Mandatory=$true,HelpMessage='Please enter Instance Group name')][Alias('Group')][System.String]$GroupName,
	[Parameter(Mandatory=$true,HelpMessage='Please enter Computer Principal Name')][Alias('Object')][System.String]$MonitoringObjectID,
    [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')][System.Boolean]$IncreaseMPVersion=$false
    )

	#Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.UserName
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the Monitoring Object
    Write-Verbose "Validating specified monitoring object ID '$MonitoringObjectID'"
    $MonitoringObject = $MG.GetMonitoringObject($MonitoringObjectID)
    If ($MonitoringObject -eq $null)
    {
	    Write-Error "Unable to find the monitoring object with ID '$MonitoringObjectID'."
	    Return $false
    }
    $MonitoringObjectFullName = $MonitoringObject.FullName
    Write-Verbose "Monitoring Object ID '$MonitoringObjectID' found. Monitoring Object Full Name: '$MonitoringObjectFullName'."

    #Get the monitoring class and the MP of where it's defined
    $MonitoringClass = $MonitoringObject.GetLeastDerivedNonAbstractMonitoringClass()
    $MonitoringClassName = $MonitoringClass.Name
    $MonitoringClassMP = $MonitoringClass.GetManagementPack()
    $MonitoringClassMPName = $MonitoringClassMP.Name

    #Get the group class
    Write-Verbose "Getting the instance group '$GroupName'."
    $InstanceGroupClassCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria("Name='$GroupName'")
    $InstanceGroupClass = $MG.GetMonitoringClasses($InstanceGroupClassCriteria)[0]
    If ($InstanceGroupClass -eq $null)
    {
	    Write-Error "$GroupName is not found."
	    Return $false
    }

    #Check if this monitoring class is actually an instance group
    Write-Verbose "Check if the group '$GroupName' is an instance group."
    $InstanceGroupBaseTypes = $InstanceGroupClass.GetBaseTypes()
    $bIsInstanceGroup = $false
    Foreach ($item in $InstanceGroupBaseTypes)
    {
	    If ($item.Id.Tostring() -eq '4ce499f1-0298-83fe-7740-7a0fbc8e2449')
	    {
		    $bIsInstanceGroup = $true
	    }
    }
    If ($bIsInstanceGroup -eq $false)
    {
	    Write-Error "$GroupName is not an instance group"
	    Return $false
    }

    #Get Group object
    $InstanceGroupObject = $MG.GetMonitoringObjects($InstanceGroupClass)[0]

    #Check if the monitoring object is already member of the group
    Write-Verbose "Checking if the monitoring object '$MonitoringObjectID' is already a member of the group."
    $MonitoringObjectCriteria = New-Object Microsoft.EnterpriseManagement.Monitoring.MonitoringObjectCriteria("Id='$MonitoringObjectID'",$MonitoringClass)
    $ExistingMembers = $InstanceGroupObject.GetRelatedMonitoringObjects($MonitoringObjectCriteria, [Microsoft.EnterpriseManagement.Common.TraversalDepth]::OneLevel)
    if ($ExistingMembers.count -gt 0)
    {
	    Write-Warning "The Monitoring Object '$MonitoringObjectFullName' (ID:'$MonitoringObjectID') is already a member of the instance group $GroupName. No need to add it again. Aborting."
	    Return $true
    }

    #Get Group population discovrey
    Write-Verbose "Getting the group discovery rule"
    $InstanceGroupDiscoveries = $InstanceGroupObject.GetMonitoringDiscoveries()
    $iGroupPopDiscoveryCount = 0
    $GroupPopDiscovery = $null
    Foreach ($Discovery in $InstanceGroupDiscoveries)
    {
	    $DiscoveryDS = $Discovery.DataSource
	    #Microsft.SystemCenter.GroupPopulator ID is 488000ef-e20b-1ac4-d3b1-9d679435e1d7
	    If ($DiscoveryDS.TypeID.Id.ToString() -eq '488000ef-e20b-1ac4-d3b1-9d679435e1d7')
	    {
		    #This data source module is using Microsft.SystemCenter.GroupPopulator
		    $iGroupPopDiscoveryCount = $iGroupPopDiscoveryCount + 1
		    $GroupPopDiscovery = $Discovery
		    Write-Verbose "Group Populator discovery found: '$($GroupPopDiscovery.Name)'"
	    }
    }
    If ($iGroupPopDiscoveryCount.count -eq 0)
    {
	    Write-Error "No group populator discovery found for $GroupName."
	    Return $false
    }

    If ($iGroupPopDiscoveryCount.count -gt 1)
    {
	    Write-Error "$GroupName has multiple discoveries using Microsft.SystemCenter.GroupPopulator Module type. Unable to continue."
	    Return $false
    }

    #Get the MP of where the group populator discovery is defined
    $GroupPopDiscoveryMP = $GroupPopDiscovery.GetManagementPack()
    $GroupPopDiscoveryMPName = $GroupPopDiscoveryMP.Name
    Write-Verbose "The group populator discovery '$($GroupPopDiscovery.Name)' is defined in management pack '$GroupPopDiscoveryMPName'."

    #Write Error and exit if the group discovery MP is sealed
    Write-Verbose "Checking if '$GroupPopDiscoveryMPName' MP is sealed."
    If ($GroupPopDiscoveryMP.sealed -eq $true)
    {
	    Write-Error "Unable to update the group discovery because it is defined in a sealed MP: '$($GroupPopDiscoveryMP.DisplayName)'."
	    Return $false
    } else {
	    Write-Verbose "'$GroupPopDiscoveryMPName' MP is unsealed. OK to continue."
    }

    #Get the MP Alias for 'Microsoft.SystemCenter.InstanceGroup.Library' from the Group Discovery MP
    Write-Verbose "Getting the MP reference alias for 'Microsoft.SystemCenter.InstanceGroup.Library' from the group discovery MP '$GroupPopDiscoveryMPName'."
    $InstanceGroupMPAlias = ($GroupPopDiscoveryMP.References | Where-Object {$_.Value -LIKE 'ManagementPack`:`[Name`=Microsoft.SystemCenter.InstanceGroup.Library`,*'}).key
    If ($InstancegroupMPAlias -eq $null)
    {
	    Write-Error "The group discovery MP '$GroupPopDiscoveryMPName' is not referencing the 'Microsoft.SystemCenter.InstanceGroup.Library' MP. Unable to continue."
	    #Exit. We are not going to create the reference now because the instance group library MP should have already been referenced.
	    Return $false
    } else {
	    Write-Verbose "The MP Reference Alias for 'Microsoft.SystemCenter.InstanceGroup.Library' is '$InstanceGroupMPAlias'."
    }

    If ($MonitoringClassMPName -ne $GroupPopDiscoveryMPName)
    {
	    #Monitoring Class and group discovery are defined in different MPs. Make sure the Monitoring Class MP is referenced in the group discovery MP
	    Write-Verbose "The Monitoring Class '$MonitoringClassName' and the group discovery are defined in different MPs."
	    $MonitoringClassMPAlias = ($GroupPopDiscoveryMP.References | Where-Object {$_.Value -LIKE "*$MonitoringClassMPName,*"}).key
	    If (!$MonitoringClassMPAlias)
	    {
		    Write-Verbose "The Group Discovery MP '$GroupPopDiscoveryMPName' is not referencing the monitoring class MP '$MonitoringClassMPName'. Creating the reference now."
		    Foreach ($item in $MonitoringClassMPName.split(".")){$MonitoringClassMPAlias = $MonitoringClassMPAlias + $item.Substring(0,1)}
		    #Make sure the MP alias is valid
		    $bValidAliasName = $true
		    Foreach ($item in $GroupPopDiscoveryMP.Reference)
		    {
			    if ($item.key -ieq $MonitoringClassMPAlias)
			    {
				    $bValidAliasName = $false
			    }
		    }
		    #Regenerate MP Alias name if it's not valid (already been taken)
		    If ($bValidAliasName -eq $false)
		    {
			    Do
			    {
				    #Append a number at the end of alias name
				    $i = 1
				    $NewMonitoringClassMPAlias = $MonitoringClassMPAlias+$($i.ToString())
				    if (($GroupPopDiscoveryMP.References | Where-Object {$_.Value -LIKE "*$MonitoringClassMPName,*"}) -eq $null)
				    {
					    $MonitoringClassMPAlias = $NewMonitoringClassMPAlias
					    $bValidAliasName = $true
				    } else {
					    $i = $i + 1
				    }
			    } Until ($bValidAliasName -eq $true)
		    }
            #Add the reference for the group definition MP
		    $AddAlias = New-OMManagementPackReference -SDK $SDK -Username $Username -Password $Password -ReferenceMPName $MonitoringClassMPName -Alias $MonitoringClassMPAlias -UnsealedMPName $GroupPopDiscoveryMPName 
		    $bNewReference = $true
	    } else {
		    #The reference to the monitoring class MP already existed.
		    $bNewReference = $false
	    }
	    Write-Verbose "The '$MonitoringClassMPName' reference alias in '$GroupPopDiscoveryMPName' is '$MonitoringClassMPAlias'."
	    #determine the <Monitoringclass> element in the Membership Rule
	    $MemberShipRuleMonitoroingClass = "`$MPElement[Name=`"$MonitoringClassMPAlias!$MonitoringClassName`"]`$"
    } else {
	    #reference not required becaues the monitoring class and the group discovery is in the same MP
	    Write-Verbose "The monitoring class '$MonitoringClassName' and the group discovery is defined in the same MP. No need to create MP reference alias for monitoring class MP."
	    $bNewReference = $null
	    $MemberShipRuleMonitoroingClass = "`$MPElement[Name=`"$MonitoringClassName`"]`$"
    }
    Write-Verbose "The <MonitoringClass> value in <MembershipRule> is '$MemberShipRuleMonitoroingClass'."
    Write-Verbose "Updating the discovery data source configuration"
    $GroupDSConfig = $GroupPopDiscovery.Datasource.Configuration
    $GroupDSConfigXML = [XML]"<Configuration>$GroupDSConfig</Configuration>"
    $MembershipRuleRelationshipClass = "`$MPElement[Name=`"$InstanceGroupMPAlias!Microsoft.SystemCenter.InstanceGroupContainsEntities`"]`$"
    $bInstanceAdded = $false
    If ($bNewReference -ne $true)
    {
	    #Either the monitoring class MP was already referenced in the group discovery MP, or the monitoring class and group discovery are defined in the same MP.
	    #Detect if any MembershipRule segment is defined for the monitoring class
	    Foreach ($MembershipRule in $GroupDSConfigXML.Configuration.MembershipRules.MembershipRule)
	    {
		    If ($MembershipRule.MonitoringClass -ieq $MemberShipRuleMonitoroingClass -and $MembershipRule.RelationshipClass -ieq $MembershipRuleRelationshipClass -and $bInstanceAdded -eq $false)
		    {
			    #Add the monitoroing object ID to the <IncludeList> node
			    if ($MembershipRule.IncludeList -eq $Null)
			    {
				    #Create the <IncludeList> node
				    $IncludeListNode = $MembershipRule.AppendChild($GroupDSConfigXML.CreateElement("IncludeList"))
			    } else {
				    $IncludeListNode = $MemberShipRule.IncludeList
			    }
			    $NewMOId = $MembershipRule.IncludeList.AppendChild($GroupDSConfigXML.CreateElement("MonitoringObjectId"))
			    $NewMOId.InnerText = $MonitoringObjectID
			    $bInstanceAdded = $true
		    }
	    }
    }
    If ($bInstanceAdded -eq $false)
    {
	    If ($bNewReference -eq $true)
	    {
	    #No need to check existing membership rules because the group discovery MP wasn't referencing the monitoring class MP, so no membership rules would have included any monitoring objects from the monitoring class
	    Write-Verbose "Since the group discovery MP '$GroupPopDiscoveryMPName' wasn't referencing the monitoring class MP '$MonitoringClassMPName', no need to check existing membership rules. Creating a brand new <MembershipRule>."
	    } Else {
		    #The Monitoring Class MP was already referenced in the group discovery MP, but there are no <MembershipRule> defined for the monitoring class
		    Write-Verbose "The Monitoring Class MP '$MonitoringClassMPName' was already referenced in the group discovery MP '$GroupPopDiscoveryMPName', but there are no <MembershipRule> defined for the monitoring class '$MonitoringClassName'. Creating a new <MembershipRule> element in the group discovery."
	    }
	    #New <MembershipRule>
	    $XMLMemberShipRule = $GroupDSConfigXML.Configuration.MembershipRules.AppendChild($GroupDSConfigXML.CreateElement("MembershipRule"))
	    #<MonitoringClass>
	    $XMLMonitoringClass = $XMLMemberShipRule.AppendChild($GroupDSConfigXML.CreateElement("MonitoringClass"))
	    $XMLMonitoringClass.InnerText = $MemberShipRuleMonitoroingClass
	    #<RelationshipClass>
	    $XMLRelationshipClass = $XMLMemberShipRule.AppendChild($GroupDSConfigXML.CreateElement("RelationshipClass"))
	    $XMLRelationshipClass.InnerText = $MembershipRuleRelationshipClass
	    #<IncludeList>
	    $IncludeListNode = $XMLMemberShipRule.AppendChild($GroupDSConfigXML.CreateElement("IncludeList"))
	    #<MonitoringObjectId>
	    $NewMOId = $IncludeListNode.AppendChild($GroupDSConfigXML.CreateElement("MonitoringObjectId"))
	    $NewMOId.InnerText = $MonitoringObjectID
	    $bInstanceAdded = $true
    }

    $UpdatedGroupPopConfig = $GroupDSConfigXML.Configuration.InnerXML

    #Increase MP version
	If ($IncreaseMPVersion)
	{
		$CurrentVersion = $GroupPopDiscoveryMP.Version.Tostring()
		$vIncrement = $CurrentVersion.Split('.')
		$vIncrement[$vIncrement.Length - 1] = ([System.Int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
		$NewVersion = ([System.String]::Join('.', $vIncrement))
		Write-Verbose "Increasing the group discovery MP version to $NewVersion"
		$GroupPopDiscoveryMP.Version = $NewVersion
	}

    #Updating the discovery
    Write-Verbose "Updating the group discovery"
    Try {
	    $GroupPopDiscovery.Datasource.Configuration = $UpdatedGroupPopConfig
	    $GroupPopDiscovery.Status = [Microsoft.EnterpriseManagement.Configuration.ManagementPackElementStatus]::PendingUpdate
	    $GroupPopDiscoveryMP.AcceptChanges()
	    $bInstanceAdded = $true
    } Catch {
	    Write-Error $_.Exception.InnerException.Message
	    $bInstanceAdded = $false
    }
    $bInstanceAdded
}
Function Update-OMGroupDiscovery
{
<# 
 .Synopsis
  Update the group discovery for a computer group or instance group in OpsMgr.

 .Description
  Update the group discovery for a computer group or instance group in OpsMgr using OpsMgr SDK. The group discovery must be defined in an unsealed management pack in order for this function to work. A boolean value $true will be returned if the monitoring object has been successfully added, otherwise, a boolean value of $false is returned if any there are any errors occurred during the process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -GroupName
  The Group name for computer group or instance group

 .Parameter -NewConfiguration
  Computer Principal Name for the unsealed MP of which the override is going to stored.

 .Parameter -IncreaseMPVersion (boolean)
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and update an instance group by specifying individual parameters:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Group Name: Test.Instance.Group
   New Configuration: @"
<RuleId>$MPElement$</RuleId>
<GroupInstanceId>$MPElement[Name="Group.Creation.Demo.Demo.Instance.Group"]$</GroupInstanceId>
<MembershipRules>
<MembershipRule>
  <MonitoringClass>$MPElement[Name="MSV2D!Microsoft.SystemCenter.VirtualMachineManager.2012.HyperVHost"]$</MonitoringClass>
  <RelationshipClass>$MPElement[Name="SCIG!Microsoft.SystemCenter.InstanceGroupContainsEntities"]$</RelationshipClass>
</MembershipRule>
</MembershipRules>
   "@

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  $NewConfiguration = @'
<RuleId>$MPElement$</RuleId>
<GroupInstanceId>$MPElement[Name="Test.Instance.Group"]$</GroupInstanceId>
<MembershipRules>
<MembershipRule>
  <MonitoringClass>$MPElement[Name="MSV2D!Microsoft.SystemCenter.VirtualMachineManager.2012.HyperVHost"]$</MonitoringClass>
  <RelationshipClass>$MPElement[Name="SCIG!Microsoft.SystemCenter.InstanceGroupContainsEntities"]$</RelationshipClass>
</MembershipRule>
</MembershipRules>
'@
  Update-OMGroupDiscovery -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -GroupName "Test.Instance.Group" -NewConfiguration $NewConfiguration

 .Example
   # Connect to OpsMgr management group via management server "OpsMgrMS01" and update an computer group by using a SMA Connection Object:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Instance Group Name: Test.Computer.Group
   New Configuration: @'
    <RuleId>$MPElement$</RuleId>
    <GroupInstanceId>$MPElement[Name="Test.Computer.Group"]$</GroupInstanceId>
    <MembershipRules>
    <MembershipRule Comment="Empty Rule">
        <MonitoringClass>$MPElement[Name="Windows!Microsoft.Windows.Computer"]$</MonitoringClass>
        <RelationshipClass>$MPElement[Name="SystemCenter!Microsoft.SystemCenter.ComputerGroupContainsComputer"]$</RelationshipClass>
        <IncludeList>
        <MonitoringObjectId>8d8e7e81-fa51-5248-6f52-3dd8761238ee</MonitoringObjectId>
        <MonitoringObjectId>1153fce1-9a23-ceee-55c2-bc06bb44aa6b</MonitoringObjectId>
        </IncludeList>
    </MembershipRule>
    </MembershipRules>
   '@
   Increase Management Pack version by 0.0.0.1
  
  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  $NewConfiguration = @'
<RuleId>$MPElement$</RuleId>
<GroupInstanceId>$MPElement[Name="Test.Computer.Group"]$</GroupInstanceId>
<MembershipRules>
<MembershipRule Comment="Empty Rule">
    <MonitoringClass>$MPElement[Name="Windows!Microsoft.Windows.Computer"]$</MonitoringClass>
    <RelationshipClass>$MPElement[Name="SystemCenter!Microsoft.SystemCenter.ComputerGroupContainsComputer"]$</RelationshipClass>
    <IncludeList>
    <MonitoringObjectId>8d8e7e81-fa51-5248-6f52-3dd8761238ee</MonitoringObjectId>
    <MonitoringObjectId>1153fce1-9a23-ceee-55c2-bc06bb44aa6b</MonitoringObjectId>
    </IncludeList>
</MembershipRule>
</MembershipRules>
'@
  Update-OMGroupDiscovery -SDKConnection $SDKConnection -GroupName "Test.Instance.Group" -NewConfiguration $NewConfiguration -IncreaseMPVersion $true
#>
	PARAM (
    [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][System.Object]$SDKConnection,
	[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][System.String]$SDK,
    [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][System.String]$Username = $null,
    [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the group name')][Alias('Group')][System.String]$GroupName,
	[Parameter(Mandatory=$true,HelpMessage='Please enter the new configuration for the group discovery')][Alias('config','Configuration')][System.String]$NewConfiguration,
    [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')][System.Boolean]$IncreaseMPVersion=$false
    )

	#Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.UserName
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Get the group class
    Write-Verbose "Getting the group '$GroupName'."
    $GroupClassCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria("Name='$GroupName'")
    $GroupClass = $MG.GetMonitoringClasses($GroupClassCriteria)[0]
    If ($GroupClass -eq $null)
    {
	    Write-Error "$GroupName is not found."
	    Return $false
    }

    #Check if this monitoring class is actually an instance group or computer group
    Write-Verbose "Check if the group '$GroupName' is an instance group or a computer group."
    $GroupBaseTypes = $GroupClass.GetBaseTypes()
    $bIsGroup = $false
    Foreach ($item in $GroupBaseTypes)
    {
	    If ($item.Id.Tostring() -eq '4ce499f1-0298-83fe-7740-7a0fbc8e2449')
	    {
		    Write-Verbose "'$GroupName' is an instance group."
            $bIsGroup = $true
	    }
	    If ($item.Id.Tostring() -eq '0c363342-717b-5471-3aa5-9de3df073f2a')
	    {
		    Write-Verbose "'$GroupName' is a computer group."
            $bIsGroup = $true
	    }
    }
    If ($bIsGroup -eq $false)
    {
	    Write-Error "$GroupName is not an instance group or a computer group."
	    Return $false
    }

    #Get Group object
    $GroupObject = $MG.GetMonitoringObjects($GroupClass)[0]

    $GroupDiscoveries = $GroupObject.GetMonitoringDiscoveries()
    $iGroupPopDiscoveryCount = 0
    $GroupPopDiscovery = $null
    Foreach ($Discovery in $GroupDiscoveries)
    {
	    $DiscoveryDS = $Discovery.DataSource
	    #Microsft.SystemCenter.GroupPopulator ID is 488000ef-e20b-1ac4-d3b1-9d679435e1d7
	    If ($DiscoveryDS.TypeID.Id.ToString() -eq '488000ef-e20b-1ac4-d3b1-9d679435e1d7')
	    {
		    #This data source module is using Microsft.SystemCenter.GroupPopulator
		    $iGroupPopDiscoveryCount = $iGroupPopDiscoveryCount + 1
		    $GroupPopDiscovery = $Discovery
		    Write-Verbose "Group Populator discovery found: '$($GroupPopDiscovery.Name)'"
	    }
    }
    If ($iGroupPopDiscoveryCount.count -eq 0)
    {
	    Write-Error "No group populator discovery found for $GroupName."
	    Return $false
    }

    If ($iGroupPopDiscoveryCount.count -gt 1)
    {
	    Write-Error "$GroupName has multiple discoveries using Microsft.SystemCenter.GroupPopulator Module type. Unable to continue."
	    Return $false
    }

    #Get the MP of where the group populator discovery is defined
    $GroupPopDiscoveryMP = $GroupPopDiscovery.GetManagementPack()
    $GroupPopDiscoveryMPName = $GroupPopDiscoveryMP.Name
    Write-Verbose "The group populator discovery '$($GroupPopDiscovery.Name)' is defined in management pack '$GroupPopDiscoveryMPName'."

    #Write Error and exit if the group discovery MP is sealed
    Write-Verbose "Checking if '$GroupPopDiscoveryMPName' MP is sealed."
    If ($GroupPopDiscoveryMP.sealed -eq $true)
    {
	    Write-Error "Unable to update the group discovery because it is defined in a sealed MP: '$($GroupPopDiscoveryMP.DisplayName)'."
	    Return $false
    } else {
	    Write-Verbose "'$GroupPopDiscoveryMPName' MP is unsealed. OK to continue."
    }

	#Increase MP version
	If ($IncreaseMPVersion)
	{
		$CurrentVersion = $GroupPopDiscoveryMP.Version.Tostring()
		$vIncrement = $CurrentVersion.Split('.')
		$vIncrement[$vIncrement.Length - 1] = ([System.Int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
		$NewVersion = ([System.String]::Join('.', $vIncrement))
		Write-Verbose "Increasing the group discovery MP version to $NewVersion"
		$GroupPopDiscoveryMP.Version = $NewVersion
	}

    #Update the Group Discovery Data Source configuration
    Write-verbose "Updating the data source configuration for the group discovery '$($GroupPopDiscovery.Name)'."
    Try {
        $GroupPopDiscovery.Datasource.Configuration = $NewConfiguration
	    $GroupPopDiscovery.Status = [Microsoft.EnterpriseManagement.Configuration.ManagementPackElementStatus]::PendingUpdate
	    $GroupPopDiscoveryMP.AcceptChanges()
	    $bGroupUpdated = $true
    } Catch {
        Write-Error $_.Exception.InnerException.Message
	    $bGroupUpdated = $false
    }
    $bGroupUpdated
}