Function New-OMTCPPortCheckDataSourceModuleType
{
<# 
 .Synopsis
  Create the TCP Port Check Data Source module type used for TCP Port monitoring.

 .Description
   Create the TCP Port Check Data Source module type used for TCP Port monitoring in OpsMgr. This is equivalent to the TCP Check Data Source module created by the TCP Port monitoring template in OpsMgr console. If the data source module type has been successfully created, the module type ID will be returned, otherwise, a NULL value is returned if the module type creation has been unsuccessful.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -MPName
  Name for the unsealed MP of which the module type is going to stored.

 .Parameter -ModuleTypeName
  Module Type name

 .Parameter -ModuleTypeDisplayName
  Module Type Display Name

 .Parameter -IncreaseMPVersion
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a service monitor with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Management Pack Name: "TYANG.Lab.Test"
   Module Type Name: "Test.TCP.Port.Check.DataSource"
   Module Type Display Name: "Test TCP Port Check Data Source Module"

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  New-OMTCPPortCheckDataSourceModuleType -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -MPName "TYANG.Lab.Test" -ModuleTypeName "Test.TCP.Port.Check.DataSource" -ModuleTypeDisplayname "Test TCP Port Check Data Source Module"

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a service monitor with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Management Pack Name: "TYANG.Lab.Test"
   Module Type Name: "Test.TCP.Port.Check.DataSource"
   Module Type Display Name: "Test TCP Port Check Data Source Module"
   Increase Management Pack version by 0.0.0.1

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  New-OMServiceMonitor -SDKConnection $SDKConnection -MPName "TYANG.Lab.Test" -ModuleTypeName "Test.TCP.Port.Check.DataSource" -ModuleTypeDisplayname "Test TCP Port Check Data Source Module" -IncreaseMPVersion $true

#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')][Alias('MP')][String]$MPName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the data source module type name')][Alias('Name')][String]$ModuleTypeName,
		[Parameter(Mandatory=$true,HelpMessage='Please enter the data source module type display name')][Alias('title')][String]$ModuleTypeDisplayName,
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
            return $NULL
        }
    } else {
        Write-Error 'The management pack specified cannot be found. please make sure the correct name is specified.'
        return $NULL
    }

	#Get relevant MPs
	Write-Verbose "Retrieving relevant MPs."
	#System.Library
	$SystemMPCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name = 'System.Library'")
	$SystemMP = $MG.GetManagementPacks($SystemMPCriteria)[0]
	$SystemMPId = $SystemMP.Id.tostring()
	Write-Verbose "System.Library MP ID: $SystemMPId"

	#Microsoft.SystemCenter.Library
	$SystemCenterMPCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name = 'Microsoft.SystemCenter.Library'")
	$SystemCenterMP = $MG.GetManagementPacks($SystemCenterMPCriteria)[0]
	$SystemCenterMPId = $SystemCenterMP.Id.tostring()
	Write-Verbose "Microsoft.SystemCenter.Library MP ID: $SystemCenterMPId"

	#Microsoft.SystemCenter.SyntheticTransactions.Library
	$SyntheticTransactionMPCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name = 'Microsoft.SystemCenter.SyntheticTransactions.Library'")
	$SyntheticTransactionMP = $MG.GetManagementPacks($SyntheticTransactionMPCriteria)[0]
	$SyntheticTransactionMPId = $SyntheticTransactionMP.Id.tostring()
	Write-Verbose "Microsoft.SystemCenter.SyntheticTransactions.Library MP ID: $SyntheticTransactionMPId"

    #Construct monitoring prefix
	$MPPrefix = "$MPName`."
	If (!($ModuleTypeName.StartsWith($MPPrefix)))
	{
		$OldModuleTypeName = $ModuleTypeName
		$ModuleTypeName = "$MPPrefix" + "$ModuleTypeName"
		Write-Verbose "Changing the Data Source Module Type name to include MP name as prefix. It will be changed from `"$OldModuleTypeName`" to `"$ModuleTypeName`"."
	}

	#Module Accessibility
	Write-Verbose "Module type accessibility will be set as Public."
	$Access = [Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Public

	#Create DS module type
	Write-Verbose "Creating the Data Source Module Type. Name: `"$ModuleTypeName`"."
	$DSModuleType = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDataSourceModuleType($MP, $ModuleTypeName, $Access)
	$DSModuleType.DisplayName = $ModuleTypeDisplayName
	$DSModuleType.LanguageCode = "ENU"

	#Module Configuration
	Write-Verbose "Creating module configuration for `"$ModuleTypeName`"."
	$DSSChemaType = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackConfigurationSchemaType
	$DSSChemaType.Schema =  '<xsd:element minOccurs="1" name="IntervalSeconds" type="xsd:integer" xmlns:xsd="http://www.w3.org/2001/XMLSchema" /><xsd:element minOccurs="1" name="ServerName" type="xsd:string" xmlns:xsd="http://www.w3.org/2001/XMLSchema" /><xsd:element minOccurs="1" name="Port" type="xsd:integer" xmlns:xsd="http://www.w3.org/2001/XMLSchema" />'
	$DSModuleType.Configuration = $DSSChemaType

	#Override parameters
	Write-Verbose "Creating overrideable parameters for `"$ModuleTypeName`"."
	$PortOverride = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackOverrideableParameter($DSModuleType, "Port")
	$PortOverride.ParameterType = "int"
	$PortOverride.Selector = "`$Config/Port`$"
	$PortOverride.DisplayName = "Port"
	$PortOverride.LanguageCode = "ENU"
	$IntervalSecondsOverride = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackOverrideableParameter($DSModuleType, "IntervalSeconds")
	$IntervalSecondsOverride.ParameterType = "int"
	$IntervalSecondsOverride.Selector = "`$Config/IntervalSeconds`$"
	$IntervalSecondsOverride.DisplayName = "Interval Seconds"
	$IntervalSecondsOverride.LanguageCode = "ENU"
	$DSModuleType.OverrideableParameterCollection.Add($PortOverride)
	$DSModuleType.OverrideableParameterCollection.Add($IntervalSecondsOverride)

	#Member Module - Scheduler Data Source
	Write-Verbose "Creating Data Source member module 'System.Scheduler' for `"$ModuleTypeName`"."
	$dsRef = New-object Microsoft.EnterpriseManagement.Configuration.ManagementPackModuleTypeReference($DSModuleType, "Scheduler")
	$dsRef.TypeID = $SystemMP.GetModuleType("System.Scheduler")
	$dsRef.Configuration = '<Scheduler><SimpleReccuringSchedule><Interval Unit="Seconds">$Config/IntervalSeconds$</Interval></SimpleReccuringSchedule><ExcludeDates /></Scheduler>'
	$DSModuleType.DataSourceCollection.Add($dsRef)

	#Member Module - Microsoft.SystemCenter.SyntheticTransactions.TCPPortCheckProbe
	Write-Verbose "Creating Probe Action member module 'Microsoft.SystemCenter.SyntheticTransactions.TCPPortCheckProbe' for `"$ModuleTypeName`"."
	$paRef = New-object Microsoft.EnterpriseManagement.Configuration.ManagementPackModuleTypeReference($DSModuleType, "Probe")
	$paRef.TypeID = $SyntheticTransactionMP.GetModuleType("Microsoft.SystemCenter.SyntheticTransactions.TCPPortCheckProbe")
	$paRef.Configuration = '<ServerName>$Config/ServerName$</ServerName><Port>$Config/Port$</Port>'
	$DSModuleType.ProbeActionCollection.Add($paRef)

	#Module Composition
	Write-Verbose "Configuring module composition for `"$ModuleTypeName`"."
	$paNodeType = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackModuleCompositionNodeType
	$paNodeType.ID = "Probe"
	$dsNodeType = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackModuleCompositionNodeType
	$dsNodeType.ID = "Scheduler"
	$DSModuleType.Node.ID = "Probe"
	$DSModuleType.Node.NodeCollection.Add($dsNodeType)

	#Output type
	Write-Verbose "Configuring Output type for `"$ModuleTypeName`"."
	$OutputType = $SyntheticTransactionMP.GetDataType("Microsoft.SystemCenter.SyntheticTransactions.TCPPortCheckData")
	$outputRef = [Microsoft.EnterpriseManagement.Configuration.ManagementPackElementReference`1[Microsoft.EnterpriseManagement.Configuration.ManagementPackDataType]]::op_implicit($OutputType)
	$DSModuleType.OutputType = $outputRef

    #Increase MP version
    If ($IncreaseMPVersion)
    {
        Write-Verbose "Increasing version for management pack `"$MPName`"."
		$CurrentVersion = $MP.Version.Tostring()
        $vIncrement = $CurrentVersion.Split('.')
        $vIncrement[$vIncrement.Length - 1] = ([system.int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
        $NewVersion = ([string]::Join('.', $vIncrement))
        $MP.Version = $NewVersion
    }

    #Verify and save the module type
    Try {
        $MP.verify()
        $MP.AcceptChanges()
		#Return the DS Module Type Name
        $Result = $ModuleTypeName
		Write-Verbose "Data Source Module Type '$ModuleTypeName' successfully created in Management Pack '$MPName'($($MP.Version))."
    } Catch {
        #Set the return value to NULL
		$Result = $null
		$MP.RejectChanges()
		$InnException = $_.Exception.InnerException
		Write-Error $InnException
        Write-Error "Unable to create Data Source Module Type `"$ModuleTypeName`" in management pack `"$MPName`"."
    }
    $Result
}

Function New-OMTCPPortCheckMonitorType
{
<# 
 .Synopsis
  Create the TCP Port Check monitor type used for TCP Port monitoring (template).

 .Description
   Create the TCP Port Check monitor type used for TCP Port monitoring (template). in OpsMgr. This is equivalent to the various TCP Check monitor types created by the TCP Port monitoring template in OpsMgr console. If the monitor type has been successfully created, the monitor type ID will be returned, otherwise, a NULL value is returned if the monitor type creation has been unsuccessful.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -MPName
  Name for the unsealed MP of which the module type is going to stored.

 .Parameter -MonitorTypeName
  Module Type name

 .Parameter -MonitorTypeDisplayName
  Module Type Display Name

 .Parameter -DataSourceModuleName
  Name for the TCP Port Check data source module type. This data source module type can be created by using the New-OMTCPPortCheckDataSourceModuleType function in this PowerShell module.

 .Parameter -$DataSourceModuleMPName
  Name of the management pack of which the TCP Port Check data source module type is defined. This is an optional parameter, it is only required if the TCP Port Check Data Source module type is defined in a separate sealed management pack.

 .Parameter -IncreaseMPVersion
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a service monitor with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Management Pack Name: "TYANG.Lab.Test"
   Module Type Name: "Test.TCP.Port.Check.DataSource"
   Monitor Display Name: "Test TCP Port Check Data Source Module"

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  New-OMTCPPortCheckDataSourceModuleType -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -MPName "TYANG.Lab.Test" -ModuleTypeName "Test.TCP.Port.Check.DataSource" -ModuleTypeDisplayname "Test TCP Port Check Data Source Module"

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a service monitor with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Management Pack Name: "TYANG.Lab.Test"
   Module Type Name: "Test.TCP.Port.Check.DataSource"
   Monitor Display Name: "Test TCP Port Check Data Source Module"
   Increase Management Pack version by 0.0.0.1

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  New-OMServiceMonitor -SDKConnection $SDKConnection -MPName "TYANG.Lab.Test" -ModuleTypeName "Test.TCP.Port.Check.DataSource" -ModuleTypeDisplayname "Test TCP Port Check Data Source Module" -IncreaseMPVersion $true

#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')][Alias('MP')][String]$MPName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the data source module type name')][Alias('Name')][String]$MonitorTypeName,
		[Parameter(Mandatory=$true,HelpMessage='Please enter the data source module type display name')][Alias('title')][String]$MonitorTypeDisplayName,
		[Parameter(Mandatory=$true,HelpMessage='Please enter the TCP Port Check data source member module name.')][Alias('DS', 'DataSource')][String]$DataSourceModuleName,
		[Parameter(Mandatory=$false,HelpMessage='If the TCP Port Check data source member module is stored in a separate sealed MP, please specify the name of the sealed management pack.')][Alias('DSMP', 'DataSourceMP')][String]$DataSourceModuleMPName,
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
            return $NULL
        }
    } else {
        Write-Error 'The management pack specified cannot be found. please make sure the correct name is specified.'
        return $NULL
    }

	#Get the data source member module
	Write-Verbose "Getting the Data Source Member Module `"$DataSourceModuleName`"."
	If (!$DataSourceModuleMPName)
	{
		#Check the same unsealed MP where the monitor type will be stored
		Write-Verbose "Getting the Data Source Member Module `"$DataSourceModuleName`" from Management Pack `"$MPName`"."
		$DSModuleType = $MP.GetModuleType($DataSourceModuleName)
	} else {
		Write-Verbose "Getting the Management Pack `"$DataSourceModuleMPName`"."
		$DSModuleTypeMPCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name = '$DataSourceModuleMPName'")
		$DSModuleTypeMP = $MG.GetManagementPacks($DSModuleTypeMPCriteria)[0]
		If ($DSModuleTypeMP.Sealed)
		{
			Write-Verbose "Getting the Data Source Member Module `"$DataSourceModuleName`" from Management Pack `"$DataSourceModuleMPName`"."
			$DSModuleType = $DSModuleTypeMP.GetModuleType($DataSourceModuleName)
		} else {
			Write-Error "the Data Source Module Type MP specified is not a sealed MP. Unable to continue."
			Return $NULL
		}
	}
	#Validate Module Type configuration
	Write-Verbose "Validating the data source member module `"$DataSourceModuleName`"."
	If ($DSModuleType)
	{
		$bValidDSModule = $true
		#Check DS module configuration (input)
		Write-Verbose "Checking module configuration for `"$DataSourceModuleName`"."
		$DSModuleTypeConfig = $DSModuleType.Configuration.Schema
		If ($DSModuleTypeConfig -icontains 'name="IntervalSeconds" type="xsd:integer"' -and $DSModuleTypeConfig -icontains 'name="ServerName" type="xsd:string"' -and $DSModuleTypeConfig -icontains 'name="Port" type="xsd:integer')
		{
			$bValidDSModule = $false
			Write-Verbose "`"$DataSourceModuleName`" configuration: `"$DSModuleTypeConfig`"."
			Write-Error "The configuration for the Data Source Module Type `"$DataSourceModuleName`" is incorrect!"
			Return $NULL
		}
		
		#Check override parameters
		Write-Verbose "Checking module overrideable parameters for `"$DataSourceModuleName`"."
		if ($DSModuleType.OverrideableParameterCollection.Count -ne 2)
		{
			$bValidDSModule = $false
			Write-Error "Incorrect number of overrideable parameters configured in the data source member type module `"$DataSourceModuleName`". It should have 2 overrideable parameters: IntervalSeconds and Port."
			Return $NULL
		}
		Foreach ($override in $DSModuleType.OverrideableParameterCollection)
		{
			if ($override.Selector -ieq '$Config/IntervalSeconds$')
			{
				$bIntervalSecondsOverride = $true
				Write-Verbose "The overrideable parameter `$Config/IntervalSeconds`$ in Data Source Module Type `"$DataSourceModuleName`" is configured."
			} elseif ($override.Selector -ieq '$Config/Port$')
			{
				$bPortOverride = $true
				Write-Verbose "The overrideable parameter `$Config/Port`$ in Data Source Module Type `"$DataSourceModuleName`" is configured."
			}
		}
		if ($bIntervalSecondsOverride -and $bPortOverride)
		{
			Write-Verbose "the Data Source Module Type `"$DataSourceModuleName`" has the correct overrideable parameters configured."
		} else {
			$bValidDSModule = $false
			Write-Error "Incorrect overrideable parameters are configured for the data source module type `"$DataSourceModuleName`"."
			Return $NULL
		}

		#Check data source member module - must be system.scheduler
		Write-Verbose "Checking the data source member module for `"$DataSourceModuleName`". There should be only one and it must be 'system.scheduler'."
		if ($DSModuleType.DataSourceCollection.count -eq 1)
		{
			if ($DSModuleType.DataSourceCollection[0].TypeID.Name -ine 'System.Scheduler')
			{
				$bValidDSModule = $false
				Write-Error "The Data Source Module type has incorrect member data source module. The data source member module should be 'System.Scheduler'."
				Return $NULL
			} else {
				Write-Verbose "The Data Source Module type`"$DataSourceModuleName`" has the correct data source member module."
			}
		} else {
			Write-Error "The Data Source Module type '$DataSourceModuleName' contains multiple data source member modules."	
			$bValidDSModule = $false
			Return $NULL
		}
		
		#Check proble action member module - must be Microsoft.SystemCenter.SyntheticTransactions.TCPPortCheckProbe
		Write-Verbose "Checking the proble action member module for `"$DataSourceModuleName`". There should be only one and it must be 'Microsoft.SystemCenter.SyntheticTransactions.TCPPortCheckProbe'."
		if ($DSModuleType.ProbeActionCollection.count -eq 1)
		{
			if ($DSModuleType.ProbeActionCollection[0].TypeID.Name -ine 'Microsoft.SystemCenter.SyntheticTransactions.TCPPortCheckProbe')
			{
				$bValidDSModule = $false
				Write-Error "The Data Source Module type has incorrect member probe action module. The data source member module should be 'Microsoft.SystemCenter.SyntheticTransactions.TCPPortCheckProbe'."
				Return $NULL
			} else {
				Write-Verbose "The Data Source Module type`"$DataSourceModuleName`" has the correct probe action member module."
			}
		} else {
			Write-Error "The Data Source Module type '$DataSourceModuleName' contains multiple probe action member modules."	
			$bValidDSModule = $false
			Return $NULL
		}

		#Check output data type
		Write-Verbose "Checking the output type for `"$DataSourceModuleName`". It must be 'Microsoft.SystemCenter.SyntheticTransactions.TCPPortCheckData'."
		if ($DSMOduleType.OutputType[0].Identifier.path[0] -ine "Microsoft.SystemCenter.SyntheticTransactions.TCPPortCheckData")
		{
			Write-Error "The Data Source Module Type '$DataSourceModuleName' has the incorrect output type. It must be 'Microsoft.SystemCenter.SyntheticTransactions.TCPPortCheckData'."
			$bValidDSModule = $false
			Return $NULL
		}
	} else {
		Write-Error "Unable to retrieve the Data Source Module Type `"$DataSourceModuleName`"."
	}

	#Get relevant MPs
	Write-Verbose "Retrieving relevant MPs."
	#System.Library
	$SystemMPCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name = 'System.Library'")
	$SystemMP = $MG.GetManagementPacks($SystemMPCriteria)[0]
	$SystemMPId = $SystemMP.Id.tostring()
	Write-Verbose "System.Library MP ID: $SystemMPId"

	#Microsoft.SystemCenter.Library
	$SystemCenterMPCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name = 'Microsoft.SystemCenter.Library'")
	$SystemCenterMP = $MG.GetManagementPacks($SystemCenterMPCriteria)[0]
	$SystemCenterMPId = $SystemCenterMP.Id.tostring()
	Write-Verbose "Microsoft.SystemCenter.Library MP ID: $SystemCenterMPId"

	#Microsoft.SystemCenter.SyntheticTransactions.Library
	$SyntheticTransactionMPCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name = 'Microsoft.SystemCenter.SyntheticTransactions.Library'")
	$SyntheticTransactionMP = $MG.GetManagementPacks($SyntheticTransactionMPCriteria)[0]
	$SyntheticTransactionMPId = $SyntheticTransactionMP.Id.tostring()
	Write-Verbose "Microsoft.SystemCenter.SyntheticTransactions.Library MP ID: $SyntheticTransactionMPId"

    #Construct monitoring prefix
	$MPPrefix = "$MPName`."
	If (!($MonitorTypeName.StartsWith($MPPrefix)))
	{
		$OldMonitorTypeName = $MonitorTypeName
		$MonitorTypeName = "$MPPrefix" + "$MonitorTypeName"
		Write-Verbose "Changing the Data Source Module Type name to include MP name as prefix. It will be changed from `"$OldMonitorTypeName`" to `"$MonitorTypeName`"."
	}

	#Module Accessibility
	Write-Verbose "Module type accessibility will be set as Public."
	$Access = [Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Public

	#Create Monitor Type
	Write-Verbose "Creating monitor type `"$MonitorTypeName`"."
	$MonitorType = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorType($MP, $MonitorTypeName, $Access)

	#Monitor Type Configuration
	Write-Verbose "Creating configuration for the monitor type `"$MonitorTypeName`"."
	$MTSChemaType = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackConfigurationSchemaType
	$MTSChemaType.Schema =  '<xsd:element minOccurs="1" name="IntervalSeconds" type="xsd:integer" xmlns:xsd="http://www.w3.org/2001/XMLSchema" /><xsd:element minOccurs="1" name="ServerName" type="xsd:string" xmlns:xsd="http://www.w3.org/2001/XMLSchema" /><xsd:element minOccurs="1" name="Port" type="xsd:integer" xmlns:xsd="http://www.w3.org/2001/XMLSchema" /><xsd:element minOccurs="1" name="ReturnCode" type="xsd:integer" xmlns:xsd="http://www.w3.org/2001/XMLSchema" />'
	$MonitorType.Configuration = $MTSChemaType

	#Override parameters
	Write-Verbose "Creating overrideable parameters for the monitor type `"$MonitorTypeName`"."
	$PortOverride = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackOverrideableParameter($MonitorType, "Port")
	$PortOverride.ParameterType = "int"
	$PortOverride.Selector = "`$Config/Port`$"
	$PortOverride.DisplayName = "Port"
	$PortOverride.LanguageCode = "ENU"
	$IntervalSecondsOverride = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackOverrideableParameter($MonitorType, "IntervalSeconds")
	$IntervalSecondsOverride.ParameterType = "int"
	$IntervalSecondsOverride.Selector = "`$Config/IntervalSeconds`$"
	$IntervalSecondsOverride.DisplayName = "Interval Seconds"
	$IntervalSecondsOverride.LanguageCode = "ENU"
	$MonitorType.OverrideableParameterCollection.Add($PortOverride)
	$MonitorType.OverrideableParameterCollection.Add($IntervalSecondsOverride)

	#Monitor Implementation
	#Member Module - Data Source
	Write-Verbose "Configuring the data source member module for the monitor type `"$MonitorTypeName`"."
	$dsRef = New-object Microsoft.EnterpriseManagement.Configuration.ManagementPackModuleTypeReference($MonitorType, "DS")
	$dsRef.TypeID = $DSModuleType
	$dsRef.Configuration = '<IntervalSeconds>$Config/IntervalSeconds$</IntervalSeconds><ServerName>$Config/ServerName$</ServerName><Port>$Config/Port$</Port>'
	$MonitorType.DataSourceCollection.Add($dsRef)

	#Member Module - Probe Action
	Write-Verbose "Configuring the probe action member module for the monitor type `"$MonitorTypeName`"."
	$ProbeModuleType = $SyntheticTransactionMP.GetModuleType('Microsoft.SystemCenter.SyntheticTransactions.TCPPortCheckProbe')
	$ProbeRef = New-object Microsoft.EnterpriseManagement.Configuration.ManagementPackModuleTypeReference($MonitorType, "Probe")
	$ProbeRef.TypeID = $ProbeModuleType
	$ProbeRef.Configuration = '<ServerName>$Config/ServerName$</ServerName><Port>$Config/Port$</Port>'
	$MonitorType.ProbeActionCollection.Add($ProbeRef)

	#Condition detection member modules
	Write-Verbose "Configuring condition detection member modules for the monitor type `"$MonitorTypeName`"."
	#Member Module - Condition Detection Failure
	$cdFailureRef = New-object Microsoft.EnterpriseManagement.Configuration.ManagementPackModuleTypeReference($MonitorType, "CDFailure")
	$cdFailureRef.TypeID = $SystemMP.GetModuleType("System.ExpressionFilter")
	$cdFailureRef.Configuration = "<Expression><SimpleExpression><ValueExpression><XPathQuery Type=`"UnsignedInteger`">StatusCode</XPathQuery></ValueExpression><Operator>Equal</Operator><ValueExpression><Value Type=`"UnsignedInteger`">`$Config/ReturnCode`$</Value></ValueExpression></SimpleExpression></Expression>"
	$MonitorType.ConditionDetectionCollection.Add($cdFailureRef)
	#Member Module - Condition Detection NOFailure
	$cdNoFailureRef = New-object Microsoft.EnterpriseManagement.Configuration.ManagementPackModuleTypeReference($MonitorType, "CDNoFailure")
	$cdNoFailureRef.TypeID = $SystemMP.GetModuleType("System.ExpressionFilter")
	$cdNoFailureRef.Configuration = "<Expression><SimpleExpression><ValueExpression><XPathQuery Type=`"UnsignedInteger`">StatusCode</XPathQuery></ValueExpression><Operator>NotEqual</Operator><ValueExpression><Value Type=`"UnsignedInteger`">`$Config/ReturnCode`$</Value></ValueExpression></SimpleExpression></Expression>"
	$MonitorType.ConditionDetectionCollection.Add($cdNoFailureRef)
	
	#Monitor Type States
	Write-Verbose "Configuring monitor type states for the monitor type `"$MonitorTypeName`"."
	$FailureState = New-object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorTypeState($MonitorType, "Failure")
	$NoFailureState = New-object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorTypeState($MonitorType, "NoFailure")
	$MonitorType.MonitorTypeStateCollection.Add($FailureState)
	$MonitorType.MonitorTypeStateCollection.Add($NoFailureState)
	
	#Regular Detections
	Write-Verbose "Configuring the regular detections for the monitor type `"$MonitorTypeName`"."
	$RegularFailureDetection = New-object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorTypeDetection
	$RegularFailureDetection.MonitorTypeStateID = "Failure"
	$RegularNoFailureDetection = New-object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorTypeDetection
	$RegularNoFailureDetection.MonitorTypeStateID = "NoFailure"
	$DSNodeType = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackModuleCompositionNodeType
	$DSNodeType.ID = "DS"
	$RegularFailureDetection.Node.ID="CDFailure"
	$RegularFailureDetection.Node.NodeCollection.Add($DSNodeType)
	$RegularNoFailureDetection.Node.ID="CDNoFailure"
	$RegularNoFailureDetection.Node.NodeCollection.Add($DSNodeType)
	$MonitorType.RegularDetectionCollection.Add($RegularFailureDetection)
	$MonitorType.RegularDetectionCollection.Add($RegularNOFailureDetection)

	#On-Demand Detections
	Write-Verbose "Configuring the On-Demand detections for the monitor type `"$MonitorTypeName`"."
	$OnDemandFailureDetection = New-object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorTypeDetection
	$OnDemandFailureDetection.MonitorTypeStateID = "Failure"
	$OnDemandNoFailureDetection = New-object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorTypeDetection
	$OnDemandNoFailureDetection.MonitorTypeStateID = "NoFailure"
	$PANodeType = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackModuleCompositionNodeType
	$PANodeType.ID = "Probe"
	$OnDemandFailureDetection.Node.ID="CDFailure"
	$OnDemandFailureDetection.Node.NodeCollection.Add($PANodeType)
	$OnDemandNoFailureDetection.Node.ID="CDNoFailure"
	$OnDemandNoFailureDetection.Node.NodeCollection.Add($PANodeType)
	$MonitorType.OnDemandDetectionCollection.Add($OnDemandFailureDetection)
	$MonitorType.OnDemandDetectionCollection.Add($OnDemandNOFailureDetection)
    #Increase MP version
    If ($IncreaseMPVersion)
    {
        Write-Verbose "Increasing version for management pack `"$MPName`"."
		$CurrentVersion = $MP.Version.Tostring()
        $vIncrement = $CurrentVersion.Split('.')
        $vIncrement[$vIncrement.Length - 1] = ([system.int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
        $NewVersion = ([string]::Join('.', $vIncrement))
        $MP.Version = $NewVersion
    }

    #Verify and save the module type
    Try {
        $MP.verify()
        $MP.AcceptChanges()
		# Return the monitor type name
        $Result = $MonitorTypeName
		Write-Verbose "Monitor Type '$MonitorTypeName' successfully created in Management Pack '$MPName'($($MP.Version))."
    } Catch {
		#Set the return value to NULL
        $Result = $null
		$MP.RejectChanges()
		$InnException = $_.Exception.InnerException
		Write-Error $InnException
        Write-Error "Unable to create the Monitor Type $MonitorTypeName in management pack $MPName."
    }
    $Result
}

Function New-OMTCPPortMonitoring
{
<# 
 .Synopsis
  Create a set of monitors and rules for monitoring a TCP Port in OpsMgr.

 .Description
  Create a set of monitors and rules for monitoring a TCP Port in OpsMgr. This is equivalent to the TCP Port monitoring template in OpsMgr console.
  The following elements will be created:
  01. Class definitions for the TCP Port watcher, watcher instance group and watcher computer group.
  02. Containment relationship for the instance group containing watcher objects.
  03. discoveries for the watcher class, watcher instance group and watcher computer group.
  04. An override to enable watcher discovery for the watcher computer group.
  05. A Data Source Module Type for checking TCP Port. This module type will be used by the monitor type and the performance collection rule created by this function.
  06. A single monitor type used by all TCP Port unit monitors. On-Demand Detection is also enabled in this monitor type.
  07. A performance collection rule collecting the Connection Time. The performance data collected by this rule will be saved to both Operations DB and the Data Warehouse DB.
  08. Four (4) Unit Monitors for detecting different return code (Connection Refused; Time Out; DNS Resolution failed; Host Unreachable).
  09. A Dependency Monitor targeting the instance group for health rollup.
  If all the management pack elements have been successfully created, a boolean value $true will be returned, otherwise, a boolean value of $false is returned if any MP element creation has been unsuccessful.

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

 .Parameter -Name
  Name for this set of monitoring solution.

 .Parameter -Title
  Title (Display name) for this set of monitoring solution.

 .Parameter -Target
  The target device name of which the TCP Port monitoring is going to check against.

 .Parameter -Port
  The port number of which the TCP Port monitoring is going to check against.

 .Parameter -WatcherNodes
  The names of the watcher nodes. When specifying multiple watcher nodes, please use ";" (without quotation marks) to separate them.

 .Parameter -IntervalSeconds
  Interval seconds for the TCP Port monitroing workflows (rules and monitors)

 .Parameter -IncreaseMPVersion
  Increase MP version by 0.0.0.1 (Increase revision by 1).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a service monitor with the following properties:
   Management Server: "OpsMgrMS01"
   Username: "domain\SCOM.Admin"
   Password "password1234"
   Management Pack Name: "TYANG.Lab.Test"
   Monitoring Name: "SQLDB01.SQL.TCP.Port.Monitoring"
   Title (Display Name): "SQL Server Port 1433 Port Monitoring for SQLDB01"
   Target: "SQLDB01.yourcompany.com"
   Port: 1433
   Watcher Nodes: "Server01; Server02" 
   IntervalSeconds 120

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  New-OMTCPPortMonitoring -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -MPName "TYANG.Lab.Test" -Name "SQLDB01.SQL.TCP.Port.Monitoring" -Title "SQL Server Port 1433 Port Monitoring for SQLDB01" -Target "SQLDB01.yourcompany.com" -Port 1433 -WatcherNodes "Server01;Server02" -IntervalSeconds 120

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" and then create a service monitor with the following properties:
   OpsMgrSDK Connection (Used in SMA): "OpsMgrSDK_TYANG"
   Management Pack Name: "TYANG.Lab.Test"
   Monitoring Name: "SQLDB01.SQL.TCP.Port.Monitoring"
   Title (Display Name): "SQL Server Port 1433 Port Monitoring for SQLDB01"
   Target: "SQLDB01.yourcompany.com"
   Port: 1433
   Watcher Nodes: "Server01; Server02" 
   IntervalSeconds 120
   Increase Management Pack version by 0.0.0.1

   $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
   New-OMTCPPortMonitoring -SDKConnection $SDKConnection -MPName "TYANG.Lab.Test" -Name "SQLDB01.SQL.TCP.Port.Monitoring" -Title "SQL Server Port 1433 Port Monitoring for SQLDB01" -Target "SQLDB01.yourcompany.com" -Port 1433 -WatcherNodes "Server01;Server02" -IntervalSeconds 120 -IncreaseMPVersion $true
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')][String]$MPName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the monitoring name')][String]$Name,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the monitoring title')][Alias('DisplayName')][String]$Title,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the target device name')][Alias('t')][String]$Target,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the port number')][Int]$Port,
        [Parameter(Mandatory=$true,HelpMessage='Please specify the watcher nodes (separated by ;)')][String]$WatcherNodes,
        [Parameter(Mandatory=$true,HelpMessage='Please specify the interval seconds for the monitoring workflows')][Int]$IntervalSeconds,
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

	#Make sure this MP is referencing the "Microsoft.SystemCenter.Library" MP
	Write-Verbose "Getting the alias for 'Microsoft.SystemCenter.Library' MP"
	$SystemCenterLibAlias = ($MP.References | where {$_.Value -like '*Microsoft.SystemCenter.Library*'}).key
	If (!$SystemCenterLibAlias)
	{
		Write-Verbose "$MPName is not referencing 'Microsoft.SystemCenter.Library'. Creating the reference now."
		$SystemCenterLibAlias = "SystemCenter"
		$AddAlias = New-OMManagementPackReference -SDK $SDK -Username $Username -Password $Password -ReferenceMPName 'Microsoft.SystemCenter.Library' -Alias $SystemCenterLibAlias -UnsealedMPName $MPName 
		
	}
	Write-Verbose "Alias for 'Microsoft.SystemCenter.Library' reference is '$SystemCenterLibAlias'"
	
	#Make sure this MP is referencing the "Microsoft.Windows.Library" MP
	Write-Verbose "Getting the alias for 'Microsoft.Windows.Library' MP"
	$WindowsLibAlias = ($MP.References | where {$_.Value -like '*Microsoft.Windows.Library*'}).key
	If (!$WindowsLibAlias)
	{
		Write-Verbose "$MPName is not referencing 'Microsoft.Windows.Library'. Creating the reference now."
		$WindowsLibAlias = "Windows"
		$AddAlias = New-OMManagementPackReference -SDK $SDK -Username $Username -Password $Password -ReferenceMPName 'Microsoft.Windows.Library' -Alias $WindowsLibAlias -UnsealedMPName $MPName 
	}
	Write-Verbose "Alias for 'Microsoft.Windows.Library' reference is '$WindowsLibAlias'"
	#Get relevant MPs
	Write-Verbose "Retrieving relevant MPs."
	#System.Library
	$SystemMPCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name = 'System.Library'")
	$SystemMP = $MG.GetManagementPacks($SystemMPCriteria)[0]
	$SystemMPId = $SystemMP.Id.tostring()
	Write-Verbose "System.Library MP ID: $SystemMPId"

	#Microsoft.SystemCenter.Library
	$SystemCenterMPCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name = 'Microsoft.SystemCenter.Library'")
	$SystemCenterMP = $MG.GetManagementPacks($SystemCenterMPCriteria)[0]
	$SystemCenterMPId = $SystemCenterMP.Id.tostring()
	Write-Verbose "Microsoft.SystemCenter.Library MP ID: $SystemCenterMPId"

	#Microsoft.SystemCenter.SyntheticTransactions.Library
	$SyntheticTransactionMPCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name = 'Microsoft.SystemCenter.SyntheticTransactions.Library'")
	$SyntheticTransactionMP = $MG.GetManagementPacks($SyntheticTransactionMPCriteria)[0]
	$SyntheticTransactionMPId = $SyntheticTransactionMP.Id.tostring()
	Write-Verbose "Microsoft.SystemCenter.SyntheticTransactions.Library MP ID: $SyntheticTransactionMPId"

	#Microsoft.Windows.Library
	$WindowsLibMPCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name = 'Microsoft.Windows.Library'")
	$WindowsLibMP = $MG.GetManagementPacks($WindowsLibMPCriteria)[0]
	$WindowsLibMPId = $WindowsLibMP.Id.tostring()
	Write-Verbose "Microsoft.Windows.Library ID: $WindowsLibMPId"

	#System.Performance.Library
	$PefLibMPCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name = 'System.Performance.Library'")
	$PerfLibMP = $MG.GetManagementPacks($PefLibMPCriteria)[0]
	$PerfLibMPId = $PerfLibMP.Id.tostring()
	Write-Verbose "System.Performance.Library ID: $PerfLibMPId"

	#MP element accessibility
	$Access = [Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Public

	#Construct monitoring prefix
	$MPPrefix = "$MPName`."
	If (!($Name.StartsWith($MPPrefix)))
	{
		$OldName = $Name
		$Name = "$MPPrefix" + "$Name"
		Write-Verbose "Changing the monitoring name to include MP name as prefix. It will be changed from `"$OldName`" to `"$Name`"."
	}

    #Create monitoring classes
	#Create Watcher Class
	$WatcherClassName = "$Name`.Watcher"
	Write-Verbose "Creating Watcher class `"$WatcherClassName`"."
	$WatcherBaseClassCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria("Name = 'Microsoft.SystemCenter.SyntheticTransactions.TCPPortCheckPerspective' AND ManagementPackId = '$SyntheticTransactionMPId'")
	$WatcherBaseClass = $MG.GetMonitoringClasses($WatcherBaseClassCriteria)[0]
	$WatcherClass = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackClass($MP, $WatcherClassName, $Access)
	$WatcherClass.Base = $WatcherBaseClass
	$WatcherClass.Hosted = $true
	$WatcherClass.LanguageCode="ENU"
	$WatcherClass.DisplayName = "$Title Watcher"

	#Create Instance Group
	$InstanceGroupClassName = "$Name`.Watcher.Group"
	Write-Verbose "Creating Watcher Instance Group `"$InstanceGroupClassName`"."
	$InstanceGroupBaseClassCriteria	 = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria("Name = 'Microsoft.SystemCenter.SyntheticTransactions.TCPPortCheckPerspectiveGroup' AND ManagementPackId = '$SyntheticTransactionMPId'")
	$InstanceGroupBaseClass= $MG.GetMonitoringClasses($InstanceGroupBaseClassCriteria)[0]
	$InstanceGroupClass = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackClass($MP, $InstanceGroupClassName, $Access)
	$InstanceGroupClass.Base = $InstanceGroupBaseClass
	$InstanceGroupClass.Hosted = $false
	$InstanceGroupClass.Singleton = $true
	$InstanceGroupClass.LanguageCode="ENU"
	$InstanceGroupClass.DisplayName = "$Title Watcher Group"

	#Create Computer Group
	$ComputerGroupClassName = "$Name`.Watcher.Computer.Group"
	Write-Verbose "Creating Watcher Computer Group `"$ComputerGroupClassName`"."
	$ComputerGroupBaseClassCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria("Name = 'Microsoft.SystemCenter.ComputerGroup' AND ManagementPackId = '$SystemCenterMPId'")
	$ComputerGroupBaseClass= $MG.GetMonitoringClasses($ComputerGroupBaseClassCriteria)[0]
	$ComputerGroupClass = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackClass($MP, $ComputerGroupClassName, $Access)
	$ComputerGroupClass.Base = $ComputerGroupBaseClass
	$ComputerGroupClass.Hosted = $false
	$ComputerGroupClass.Singleton = $true
	$ComputerGroupClass.LanguageCode="ENU"
	$ComputerGroupClass.DisplayName = "$Title watcher computers group"

	#Create containment relationship
	$ContainmentRelationshipName = "$Name`.InstanceGroupContainsWatchers.Relationship"
	Write-Verbose "Creating containment relationship `"$ContainmentRelationshipName`"."
	$GroupContainWatcherRelationship = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackRelationship($MP, $ContainmentRelationshipName, $Access)
	$ContainmentRelationshipTypeCriteria =New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringRelationshipClassCriteria("Name = 'System.Containment' AND ManagementPackId = '$SystemMPId'")
	$ContainmentRelationshipType = $MG.GetMonitoringRelationshipClasses($ContainmentRelationshipTypeCriteria)[0]
	$SourceEndPoint = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackRelationshipEndpoint($GroupContainWatcherRelationship,"Source")
	$SourceEndPoint.Type = [Microsoft.EnterpriseManagement.Configuration.ManagementPackElementReference`1[Microsoft.EnterpriseManagement.Configuration.ManagementPackClass]]::op_implicit($InstanceGroupClass)
	$TargetEndPoint = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackRelationshipEndpoint($GroupContainWatcherRelationship,"Target")
	$TargetEndPoint.Type = [Microsoft.EnterpriseManagement.Configuration.ManagementPackElementReference`1[Microsoft.EnterpriseManagement.Configuration.ManagementPackClass]]::op_implicit($WatcherClass)
	$GroupContainWatcherRelationship.Base = $ContainmentRelationshipType
	$GroupContainWatcherRelationship.Source = $SourceEndPoint
	$GroupContainWatcherRelationship.Target = $TargetEndPoint
	$GroupContainWatcherRelationship.DisplayName = "Group of $Title contains $Title Watchers"
	$GroupContainWatcherRelationship.LanguageCode="ENU"
	
	#Create discoveries
	Write-Verbose "Creating discoveries for the classes defined."
	$WindowsComputerClass = $WindowsLibMP.GetClass("Microsoft.Windows.Computer")
	#Watcher Discovery
	Write-Verbose "Creating discovery for `"$WatcherClassName`"."
	$arrWatcherNodes = @()
	Foreach ($item in $WatcherNodes.split(";"))
	{
		$arrWatcherNodes += $item.Trim()
	}
	if ($arrWatcherNodes.Count -eq 1)
	{
		$strWatcherNodes = $arrWatcherNodes[0]
	} else {
		$strWatcherNodes = [string]::Join("|", $arrWatcherNodes)
		$strWatcherNodes = "($strWatcherNodes)"
	}
	$UniquenessKey = ([Guid]::NewGuid()).ToString()
	$WatcherDiscoveryName = "$WatcherClassName`.Discovery"
	$WatcherDiscovery = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscovery($MP, $WatcherDiscoveryName)
	$WatcherDiscovery.Remotable = $true
	$WatcherDiscovery.Enabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::false
	$WatcherDiscovery.ConfirmDelivery = $false
	$WatcherDiscovery.DisplayName = "$Title Watcher Discovery"
	$WatcherDiscovery.LanguageCode = "ENU"
	$WatcherDiscovery.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::Discovery
	$WatcherDiscovery.Target = [Microsoft.EnterpriseManagement.Configuration.ManagementPackElementReference`1[Microsoft.EnterpriseManagement.Configuration.ManagementPackClass]]::op_implicit($WindowsComputerClass)
	$WatcherDiscoveryDiscoveredClass = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscoveryClass
	$WatcherDiscoveryDiscoveredClass.TypeID = [Microsoft.EnterpriseManagement.Configuration.ManagementPackElementReference`1[Microsoft.EnterpriseManagement.Configuration.ManagementPackClass]]::op_implicit($WatcherClass)
	$WatcherDiscovery.DiscoveryClassCollection.Add($WatcherDiscoveryDiscoveredClass)
	$WatcherDiscoveryDiscoveredRelationship = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscoveryRelationship
	$WatcherDiscoveryDiscoveredRelationship.TypeID = [Microsoft.EnterpriseManagement.Configuration.ManagementPackElementReference`1[Microsoft.EnterpriseManagement.Configuration.ManagementPackRelationship]]::op_implicit($GroupContainWatcherRelationship)
	$WatcherDiscovery.DiscoveryRelationshipCollection.Add($WatcherDiscoveryDiscoveredRelationship)
	$WatcherDiscoveryDSType = $SyntheticTransactionMP.GetModuleType("Microsoft.SystemCenter.SyntheticTransactions.PerspectiveDiscoveryDataSource")
	$WatcherDiscoveryDS = New-object Microsoft.EnterpriseManagement.Configuration.ManagementPackDataSourceModule($WatcherDiscovery, "WatcherDiscoveryDS")
	$WatcherDiscoveryDS.TypeID = $WatcherDiscoveryDSType
	$WatcherDiscoveryDSConfig = "<ClassId>`$MPElement[Name=`"$WatcherClassName`"]`$</ClassId><DisplayName>$Title</DisplayName><WatcherComputersList>$strWatcherNodes</WatcherComputersList><UniquenessKey>$UniquenessKey</UniquenessKey>"
	$WatcherDiscoveryDS.Configuration = $WatcherDiscoveryDSConfig
	$WatcherDiscovery.DataSource = $WatcherDiscoveryDS

	#Instance Group Discovery
	Write-Verbose "Creating discovery for `"$InstanceGroupClassName`"."
	$InstanceGrpDiscovery = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscovery($MP, "$InstanceGroupClassName`.Discovery")
	$InstanceGrpDiscovery.Remotable = $true
	$InstanceGrpDiscovery.Enabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
	$InstanceGrpDiscovery.ConfirmDelivery = $false
	$InstanceGrpDiscovery.DisplayName = "$Title Watcher Group Discovery" 
	$InstanceGrpDiscovery.LanguageCode = "ENU"
	$InstanceGrpDiscovery.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::Discovery
	$InstanceGrpDiscovery.Target = [Microsoft.EnterpriseManagement.Configuration.ManagementPackElementReference`1[Microsoft.EnterpriseManagement.Configuration.ManagementPackClass]]::op_implicit($InstanceGroupClass)
	$InstanceGrpDiscoveryDiscoveredClass = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscoveryClass
	$InstanceGrpDiscoveryDiscoveredClass.TypeID = [Microsoft.EnterpriseManagement.Configuration.ManagementPackElementReference`1[Microsoft.EnterpriseManagement.Configuration.ManagementPackClass]]::op_implicit($InstanceGroupClass)
	$InstanceGrpDiscovery.DiscoveryClassCollection.Add($InstanceGrpDiscoveryDiscoveredClass)
	$InstanceGrpDiscoveryDSType = $SystemCenterMP.GetModuleType("Microsoft.SystemCenter.GroupPopulator")
	$InstanceGrpDiscoveryDS = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDataSourceModule($InstanceGrpDiscovery, "GroupDiscoveryDS")
	$InstanceGrpDiscoveryDS.TypeID = $InstanceGrpDiscoveryDSType
	$InstanceGrpDiscoveryDSConfig = "<RuleId>`$MPElement`$</RuleId><GroupInstanceId>`$Target/Id`$</GroupInstanceId><MembershipRules><MembershipRule><MonitoringClass>`$MPElement[Name=`"$WatcherClassName`"]$</MonitoringClass><RelationshipClass>`$MPElement[Name=`"$ContainmentRelationshipName`"]$</RelationshipClass></MembershipRule></MembershipRules>"
	$InstanceGrpDiscoveryDS.Configuration = $InstanceGrpDiscoveryDSConfig
	$InstanceGrpDiscovery.DataSource = $InstanceGrpDiscoveryDS

	#Computer Group Discovery
	Write-Verbose "Creating discovery for `"$ComputerGroupClassName`"."
	#Get the monitoring object ID for each watcher computer
	$arrWatcherComputerIDs = @()
	Foreach ($Watcher in $arrWatcherNodes)
	{
		$MOCriteria = New-object Microsoft.EnterpriseManagement.Monitoring.MonitoringObjectCriteria("Name LIKE '$Watcher`%'", $WindowsComputerClass)
		$WatcherComputerObjects = $MG.GetMonitoringObjects($MOCriteria)
		If ($WatcherComputerObjects.count -eq 0)
		{
			Write-Error "Unable to find Windows Computer $Watcher."
		}
		Foreach ($item in $WatcherComputerObjects)
		{
			$arrWatcherComputerIDs += $item.Id.tostring()
		}
	}
	if ($arrWatcherComputerIDs.count -eq 0)
	{
		Write-Error "No Windows computers are found for the watcher nodes `"$WatcherNodes`". Please make sure the names are valid, and use `";`" to separate each node."
		Return
	}
	$ComputerGrpDiscovery = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscovery($MP, "$ComputerGroupClassName`.Discovery")
	$ComputerGrpDiscovery.Remotable = $true
	$ComputerGrpDiscovery.Enabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
	$ComputerGrpDiscovery.ConfirmDelivery = $false
	$ComputerGrpDiscovery.DisplayName = "$Title Watcher computer group discovery" 
	$ComputerGrpDiscovery.LanguageCode = "ENU"
	$ComputerGrpDiscovery.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::Discovery
	$ComputerGrpDiscovery.Target = [Microsoft.EnterpriseManagement.Configuration.ManagementPackElementReference`1[Microsoft.EnterpriseManagement.Configuration.ManagementPackClass]]::op_implicit($ComputerGroupClass)
	$ComputerGrpDiscoveryDiscoveredClass = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscoveryClass
	$ComputerGrpDiscoveryDiscoveredClass.TypeID = [Microsoft.EnterpriseManagement.Configuration.ManagementPackElementReference`1[Microsoft.EnterpriseManagement.Configuration.ManagementPackClass]]::op_implicit($ComputerGroupClass)
	$ComputerGrpDiscovery.DiscoveryClassCollection.Add($ComputerGrpDiscoveryDiscoveredClass)
	$ComputerGrpDiscoveryDSType = $SystemCenterMP.GetModuleType("Microsoft.SystemCenter.GroupPopulator")
	$ComputerGrpDiscoveryDS = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDataSourceModule($ComputerGrpDiscovery, "GroupPopulationDataSource")
	$ComputerGrpDiscoveryDS.TypeID = $ComputerGrpDiscoveryDSType
	$ComputerGrpDiscoveryDSConfig = "<RuleId>`$MPElement`$</RuleId><GroupInstanceId>`$Target/Id`$</GroupInstanceId>"
	$ComputerGrpDiscoveryDSConfig = $ComputerGrpDiscoveryDSConfig + "<MembershipRules><MembershipRule>"
	$ComputerGrpDiscoveryDSConfig = $ComputerGrpDiscoveryDSConfig + "<MonitoringClass>`$MPElement[Name=`"$WindowsLibAlias!Microsoft.Windows.Computer`"]$</MonitoringClass>"
	$ComputerGrpDiscoveryDSConfig = $ComputerGrpDiscoveryDSConfig + "<RelationshipClass>`$MPElement[Name=`"SystemCenter!Microsoft.SystemCenter.ComputerGroupContainsComputer`"]`$</RelationshipClass><IncludeList>"
	Foreach ($item in $arrWatcherComputerIDs)
	{
		$ComputerGrpDiscoveryDSConfig = $ComputerGrpDiscoveryDSConfig + "<MonitoringObjectId>$ID</MonitoringObjectId>"
	}
	$ComputerGrpDiscoveryDSConfig = $ComputerGrpDiscoveryDSConfig + "</IncludeList></MembershipRule>"
	$ComputerGrpDiscoveryDSConfig = $ComputerGrpDiscoveryDSConfig + "<MembershipRule><MonitoringClass>`$MPElement[Name=`"$WindowsLibAlias!Microsoft.Windows.Computer`"]$</MonitoringClass><RelationshipClass>`$MPElement[Name=`"$SystemCenterLibAlias!Microsoft.SystemCenter.ComputerGroupContainsComputer`"]$</RelationshipClass><Expression><Contains maxDepth=`"1`"><MonitoringClass>`$MPElement[Name=`"$WatcherClassName`"]`$</MonitoringClass></Contains></Expression></MembershipRule></MembershipRules>"
	$ComputerGrpDiscoveryDS.Configuration = $ComputerGrpDiscoveryDSConfig
	$ComputerGrpDiscovery.DataSource = $ComputerGrpDiscoveryDS

	#Enable watcher discovery via override
	$WatcherDiscoveryOverrideName = "$WatcherDiscoveryName`.Override"
	Write-Verbose "Enabling Watcher discovery `"$WatcherDiscoveryName`" for the computer group `"$ComputerGroupClassName`" via override `"$WatcherDiscoveryOverrideName`"."
	$WatcherDiscoveryOverride = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscoveryPropertyOverride($MP, $WatcherDiscoveryOverrideName)
	$WatcherDiscoveryOverride.Discovery = $WatcherDiscovery
	$WatcherDiscoveryOverride.Property = "Enabled"
	$WatcherDiscoveryOverride.DisplayName = "$Title Watcher Discovery Override"
	$WatcherDiscoveryOverride.LanguageCode = "ENU"
	$WatcherDiscoveryOverride.Value = "true"
	$WatcherDiscoveryOverride.Context = $ComputerGroupClass

	#Save MP before calling external functions to continue building the MP.
	Write-Verbose "Saving Management Pack `"$MPName`" before calling external functions to create data source module type and monitor type."
	Try {
        $MP.verify()
        $MP.AcceptChanges()
        $Result = $true
		Write-Verbose "Saving Management Pack '$MPName'($($MP.Version)) after entity types (classes) and relationship type is defined."
    } Catch {
        $Result = $false
		$MP.RejectChanges()
		Write-Error $_.Exception
        Write-Error "Unable to create entity types (classes), containment relationship type, discoveries and override in the management pack $MPName. Aborting."
		Return $Result
    }
    #Create DS module type
	Write-Verbose "Creating the Data Source Module Type for the TCP Port Monitoring."
	$DSModuleTypeName = New-OMTCPPortCheckDataSourceModuleType -SDK $SDK -Username $Username -Password $Password -MPName $MPName -ModuleTypeName "$Name`.TCP.Port.Check.Data.Source" -ModuleTypeDisplayName "$Title TCP Port Check Data Source Module"
	
	If (!$DSModuleTypeName)
	{
		Write-Error "The Data Source Module Type creation has been unsuccessful. Cannot continue. aborting."
		Return $false
	} 

	#Create Monitor Type
	Write-Verbose "Creating the Monitor Type for the TCP Port Monitoring."
	$MonitorTypeName = New-OMTCPPortCheckMonitorType -SDK $SDK -Username $Username -Password $Password -MPName $MPName -MonitorTypeName "$Name`.TCP.Port.Check.Monitor.Type" -MonitorTypeDisplayName "$Title TCP Port Check Monitor Type" -DataSourceModuleName $DSModuleTypeName
	
	If (!$MonitorTypeName)
	{
		Write-Error "The Monitor Type creation has been unsuccessful. Cannot continue. aborting."
		Return $false
	} 
    
	#Create perf collection rule for connection time
	$PerfRuleName = "$Name`.ConnectionTime.Perf.Collection.Rule"
	Write-Verbose "Creating Performance Collection Rule `"$PerfRuleName`"."
	$PerfRuleDisplayname = "$Title Connection Time Performance Collection Rule"
	$PerfRule = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackRule($MP, $PerfRuleName)
	$PerfRule.DisplayName = $PerfRuleDisplayname
	$PerfRule.Enabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
	$PerfRule.Target = $WatcherClass
	$PerfRule.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::PerformanceCollection
	#Configure Rule Data Source module
	$PerfRuleDSModuleType = $MP.GetModuleType($DSModuleTypeName)
	$PerfDSModule = New-object Microsoft.EnterpriseManagement.Configuration.ManagementPackDataSourceModule($PerfRule, 'DS')
	$PerfDSConfig = "<IntervalSeconds>$IntervalSeconds</IntervalSeconds><ServerName>$Target</ServerName><Port>$Port</Port>"
	$PerfDSModule.TypeID = $PerfRuleDSModuleType
	$PerfDSModule.Configuration = $PerfDSConfig
	$PerfRule.DataSourceCollection.Add($PerfDSModule)
	#Configure Rule condition detection module
	$PerfRuleCDModuleType = $PerfLibMP.GetModuleType("System.Performance.DataGenericMapper")
	$PerfCDModule = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackConditionDetectionModule($PerfRule, 'PerfMapper')
	$PerfCDConfig = '<ObjectName>TCP Port Check</ObjectName><CounterName>Connection Time</CounterName><InstanceName>$Data/ServerName$:$Data/Port$</InstanceName><Value>$Data/ConnectionTime$</Value>'
	$PerfCDModule.TypeID = $PerfRuleCDModuleType
	$PerfCDModule.Configuration = $PerfCDConfig
	$PerfRule.ConditionDetection = $PerfCDModule
	#Configure Write Action modules
	$DBWAModuleType = $MG.GetMonitoringModuleTypes('Microsoft.SystemCenter.CollectPerformanceData')[0]
	$DWWAModuleType = $MG.GetMonitoringModuleTypes('Microsoft.SystemCenter.DataWarehouse.PublishPerformanceData')[0]
	$DBWAModule = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackWriteActionModule($PerfRule, 'WriteToDB')
	$DBWAModule.TypeID = $DBWAModuleType
	$DWWAModule = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackWriteActionModule($PerfRule, 'WriteToDW')
	$DWWAModule.TypeID = $DWWAModuleType
	$PerfRule.WriteActionCollection.Add($DBWAModule)
	$PerfRule.WriteActionCollection.Add($DWWAModule)

	#Create unit monitors
	Write-Verbose "Start creating unit monitors."
	$MonitorType = $MP.GetUnitMonitorType($MonitorTypeName)
	$strAvailabilityStateMonitorQuery = "Name ='System.Health.AvailabilityState'"
	$AvailabilityMonitorCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitorCriteria($strAvailabilityStateMonitorQuery)
	$AvailabilityMonitor = $MG.GetMonitors($AvailabilityMonitorCriteria)[0]
	$AlertParameter1 = '$Data/Context/ServerName$'
	$AlertParameter2 = '$Data/Context/Port$'
	#DNS Resolution Monitor
	$DNSResMonitorName = "$Name.DNSResolution.Monitor"
	Write-Verbose "Creating Unit Monitor `"$DNSResMonitorName`"."
	$DNSResMonitorDisplayName = "$Title DNS Resolution Monitor"
	$DNSResMonitor = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitor($mp, $DNSResMonitorName, $Access)
	$DNSResMonitor.DisplayName = $DNSResMonitorDisplayName
	$DNSResMonitor.TypeID = $MonitorType
	$DNSResMonitor.Target = $WatcherClass
	$DNSResMonitor.ParentMonitorID = $AvailabilityMonitor
	$DNSResMonitor.Remotable = $true
	$DNSResMonitor.Enabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
	$DNSResMonitorConfig = "<IntervalSeconds>$IntervalSeconds</IntervalSeconds><ServerName>$Target</ServerName><Port>$Port</Port><ReturnCode>2147953401</ReturnCode>"
	$DNSResMonitor.Configuration = $DNSResMonitorConfig
	$DNSReSMonitorFailureState = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($DNSResMonitor, 'Failure')
	$DNSReSMonitorFailureState.MonitorTypeStateID = 'Failure'
	$DNSReSMonitorFailureState.DisplayName = 'Failure'
	$DNSReSMonitorFailureState.Description = 'Failure'
	$DNSReSMonitorFailureState.HealthState = 'Error'
	$DNSReSMonitorNoFailureState = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($DNSResMonitor, 'NoFailure')
	$DNSReSMonitorNoFailureState.MonitorTypeStateID = 'NoFailure'
	$DNSReSMonitorNoFailureState.DisplayName = 'NoFailure'
	$DNSReSMonitorNoFailureState.Description = 'NoFailure'
	$DNSReSMonitorNoFailureState.HealthState = 'Success'
	$DNSResMonitor.OperationalStateCollection.Add($DNSReSMonitorFailureState)
	$DNSResMonitor.OperationalStateCollection.Add($DNSReSMonitorNoFailureState)
	$DNSResMonitor.AlertSettings = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorAlertSettings
	$DNSResMonitor.AlertSettings.AlertOnState = 'Error'
	$DNSResMonitor.AlertSettings.AutoResolve = $true
	$DNSResMonitor.AlertSettings.AlertPriority = 'Normal'
	$DNSResMonitor.AlertSettings.AlertSeverity = 'Error'
	$DNSResMonitor.AlertSettings.AlertParameter1 = $AlertParameter1
	$DNSResMonitor.AlertSettings.AlertParameter2 = $AlertParameter2
	$DNSResAlertStringResourceID = "$DNSResMonitorName`.AlertMessage"
	$DNSResAlertMessage = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackStringResource($MP, $DNSResAlertStringResourceID)
	$DNSResAlertMessage.DisplayName = "$Target DNS Resolution Failure"
	$DNSResAlertMessage.Description = "Unable to resolve name to IP. ServerName: {0} Port: {1}"
	$DNSResMonitor.AlertSettings.AlertMessage = $DNSResAlertMessage

	#Time Out Monitor
	$TimeOutMonitorName = "$Name.TimeOut.Monitor"
	Write-Verbose "Creating Unit Monitor `"$TimeOutMonitorName`"."
	$TimeOutMonitorDisplayName = "$Title Time Out Monitor"
	$TimeOutMonitor = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitor($mp, $TimeOutMonitorName, $Access)
	$TimeOutMonitor.DisplayName = $TimeOutMonitorDisplayName
	$TimeOutMonitor.TypeID = $MonitorType
	$TimeOutMonitor.Target = $WatcherClass
	$TimeOutMonitor.ParentMonitorID = $AvailabilityMonitor
	$TimeOutMonitor.Remotable = $true
	$TimeOutMonitor.Enabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
	$TimeOutMonitorConfig = "<IntervalSeconds>$IntervalSeconds</IntervalSeconds><ServerName>$Target</ServerName><Port>$Port</Port><ReturnCode>2147952460</ReturnCode>"
	$TimeOutMonitor.Configuration = $TimeOutMonitorConfig
	$TimeOutMonitorFailureState = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($TimeOutMonitor, 'Failure')
	$TimeOutMonitorFailureState.MonitorTypeStateID = 'Failure'
	$TimeOutMonitorFailureState.DisplayName = 'Failure'
	$TimeOutMonitorFailureState.Description = 'Failure'
	$TimeOutMonitorFailureState.HealthState = 'Error'
	$TimeOutMonitorNoFailureState = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($TimeOutMonitor, 'NoFailure')
	$TimeOutMonitorNoFailureState.MonitorTypeStateID = 'NoFailure'
	$TimeOutMonitorNoFailureState.DisplayName = 'NoFailure'
	$TimeOutMonitorNoFailureState.Description = 'NoFailure'
	$TimeOutMonitorNoFailureState.HealthState = 'Success'
	$TimeOutMonitor.OperationalStateCollection.Add($TimeOutMonitorFailureState)
	$TimeOutMonitor.OperationalStateCollection.Add($TimeOutMonitorNoFailureState)
	$TimeOutMonitor.AlertSettings = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorAlertSettings
	$TimeOutMonitor.AlertSettings.AlertOnState = 'Error'
	$TimeOutMonitor.AlertSettings.AutoResolve = $true
	$TimeOutMonitor.AlertSettings.AlertPriority = 'Normal'
	$TimeOutMonitor.AlertSettings.AlertSeverity = 'Error'
	$TimeOutMonitor.AlertSettings.AlertParameter1 = $AlertParameter1
	$TimeOutMonitor.AlertSettings.AlertParameter2 = $AlertParameter2
	$TimeOutAlertStringResourceID = "$TimeOutMonitorName`.AlertMessage"
	$TimeOutAlertMessage = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackStringResource($MP, $TimeOutAlertStringResourceID)
	$TimeOutAlertMessage.DisplayName = "$Target Connection Time Out"
	$TimeOutAlertMessage.Description = "A connection attempt failed because the connected party did not properly respond after a period of time, or established connection failed because connected host has failed to respond. ServerName: {0} Port: {1}"
	$TimeOutMonitor.AlertSettings.AlertMessage = $TimeOutAlertMessage

	#Host Unreachable Monitor
	$HostUnreachableMonitorName = "$Name.HostUnreachable.Monitor"
	Write-Verbose "Creating Unit Monitor `"$HostUnreachableMonitorName`"."
	$HostUnreachableMonitorDisplayName = "$Title Host Unreachable Monitor"
	$HostUnreachableMonitor = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitor($mp, $HostUnreachableMonitorName, $Access)
	$HostUnreachableMonitor.DisplayName = $HostUnreachableMonitorDisplayName
	$HostUnreachableMonitor.TypeID = $MonitorType
	$HostUnreachableMonitor.Target = $WatcherClass
	$HostUnreachableMonitor.ParentMonitorID = $AvailabilityMonitor
	$HostUnreachableMonitor.Remotable = $true
	$HostUnreachableMonitor.Enabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
	$HostUnreachableMonitorConfig = "<IntervalSeconds>$IntervalSeconds</IntervalSeconds><ServerName>$Target</ServerName><Port>$Port</Port><ReturnCode>2147952460</ReturnCode>"
	$HostUnreachableMonitor.Configuration = $HostUnreachableMonitorConfig
	$HostUnreachableMonitorFailureState = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($HostUnreachableMonitor, 'Failure')
	$HostUnreachableMonitorFailureState.MonitorTypeStateID = 'Failure'
	$HostUnreachableMonitorFailureState.DisplayName = 'Failure'
	$HostUnreachableMonitorFailureState.Description = 'Failure'
	$HostUnreachableMonitorFailureState.HealthState = 'Error'
	$HostUnreachableMonitorNoFailureState = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($HostUnreachableMonitor, 'NoFailure')
	$HostUnreachableMonitorNoFailureState.MonitorTypeStateID = 'NoFailure'
	$HostUnreachableMonitorNoFailureState.DisplayName = 'NoFailure'
	$HostUnreachableMonitorNoFailureState.Description = 'NoFailure'
	$HostUnreachableMonitorNoFailureState.HealthState = 'Success'
	$HostUnreachableMonitor.OperationalStateCollection.Add($HostUnreachableMonitorFailureState)
	$HostUnreachableMonitor.OperationalStateCollection.Add($HostUnreachableMonitorNoFailureState)
	$HostUnreachableMonitor.AlertSettings = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorAlertSettings
	$HostUnreachableMonitor.AlertSettings.AlertOnState = 'Error'
	$HostUnreachableMonitor.AlertSettings.AutoResolve = $true
	$HostUnreachableMonitor.AlertSettings.AlertPriority = 'Normal'
	$HostUnreachableMonitor.AlertSettings.AlertSeverity = 'Error'
	$HostUnreachableMonitor.AlertSettings.AlertParameter1 = $AlertParameter1
	$HostUnreachableMonitor.AlertSettings.AlertParameter2 = $AlertParameter2
	$HostUnreachableAlertStringResourceID = "$HostUnreachableMonitorName`.AlertMessage"
	$HostUnreachableAlertMessage = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackStringResource($MP, $HostUnreachableAlertStringResourceID)
	$HostUnreachableAlertMessage.DisplayName = "$Target Host Unreachable"
	$HostUnreachableAlertMessage.Description = "A socket operation was attempted to an unreachable host. ServerName: {0} Port: {1}"
	$HostUnreachableMonitor.AlertSettings.AlertMessage = $HostUnreachableAlertMessage

	#Connection Refused Monitor
	$ConnectionRefusedMonitorName = "$Name.ConnectionRefused.Monitor"
	Write-Verbose "Creating Unit Monitor `"$ConnectionRefusedMonitorName`"."
	$ConnectionRefusedMonitorDisplayName = "$Title Connection Refused Monitor"
	$ConnectionRefusedMonitor = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitor($mp, $ConnectionRefusedMonitorName, $Access)
	$ConnectionRefusedMonitor.DisplayName = $ConnectionRefusedMonitorDisplayName
	$ConnectionRefusedMonitor.TypeID = $MonitorType
	$ConnectionRefusedMonitor.Target = $WatcherClass
	$ConnectionRefusedMonitor.ParentMonitorID = $AvailabilityMonitor
	$ConnectionRefusedMonitor.Remotable = $true
	$ConnectionRefusedMonitor.Enabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
	$ConnectionRefusedMonitorConfig = "<IntervalSeconds>$IntervalSeconds</IntervalSeconds><ServerName>$Target</ServerName><Port>$Port</Port><ReturnCode>2147952460</ReturnCode>"
	$ConnectionRefusedMonitor.Configuration = $ConnectionRefusedMonitorConfig
	$ConnectionRefusedMonitorFailureState = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($ConnectionRefusedMonitor, 'Failure')
	$ConnectionRefusedMonitorFailureState.MonitorTypeStateID = 'Failure'
	$ConnectionRefusedMonitorFailureState.DisplayName = 'Failure'
	$ConnectionRefusedMonitorFailureState.Description = 'Failure'
	$ConnectionRefusedMonitorFailureState.HealthState = 'Error'
	$ConnectionRefusedMonitorNoFailureState = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($ConnectionRefusedMonitor, 'NoFailure')
	$ConnectionRefusedMonitorNoFailureState.MonitorTypeStateID = 'NoFailure'
	$ConnectionRefusedMonitorNoFailureState.DisplayName = 'NoFailure'
	$ConnectionRefusedMonitorNoFailureState.Description = 'NoFailure'
	$ConnectionRefusedMonitorNoFailureState.HealthState = 'Success'
	$ConnectionRefusedMonitor.OperationalStateCollection.Add($ConnectionRefusedMonitorFailureState)
	$ConnectionRefusedMonitor.OperationalStateCollection.Add($ConnectionRefusedMonitorNoFailureState)
	$ConnectionRefusedMonitor.AlertSettings = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorAlertSettings
	$ConnectionRefusedMonitor.AlertSettings.AlertOnState = 'Error'
	$ConnectionRefusedMonitor.AlertSettings.AutoResolve = $true
	$ConnectionRefusedMonitor.AlertSettings.AlertPriority = 'Normal'
	$ConnectionRefusedMonitor.AlertSettings.AlertSeverity = 'Error'
	$ConnectionRefusedMonitor.AlertSettings.AlertParameter1 = $AlertParameter1
	$ConnectionRefusedMonitor.AlertSettings.AlertParameter2 = $AlertParameter2
	$ConnectionRefusedAlertStringResourceID = "$ConnectionRefusedMonitorName`.AlertMessage"
	$ConnectionRefusedAlertMessage = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackStringResource($MP, $ConnectionRefusedAlertStringResourceID)
	$ConnectionRefusedAlertMessage.DisplayName = "$Target Connection Refused"
	$ConnectionRefusedAlertMessage.Description = "No connection could be made because the target machine actively refused it. ServerName: {0} Port: {1}"
	$ConnectionRefusedMonitor.AlertSettings.AlertMessage = $ConnectionRefusedAlertMessage
	
	#Create Dependency Monitor
	$DepMonitorName = "$Name`.GroupHealth.Dependency.Monitor"
	Write-Verbose "Creating Dependency Monitor `"$DepMonitorName`"."
	$DepMonitorDisplayName = "$Title Group Roll-Up Monitor"
	$DepMonitor = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDependencyMonitor($mp, $DepMonitorName, $Access)
	$DepMonitor.DisplayName = $DepMonitorDisplayName
	$DepMonitor.Description = "$Title Dependency Monitor that rolls up health for all Watcher Nodes Monitoring Test TCP Port Monitor. This monitors $Target on port $Port."
	$DepMonitor.LanguageCode = "ENU"
	$DepMonitor.Enabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
	$DepMonitor.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::PerformanceHealth
	$DepMonitor.Remotable = $true
	$DepMonitor.Priority = "Normal"
	$DepMonitor.Target = $InstanceGroupClass
	$DepMonitor.RelationshipType = $ContainmentRelationshipType
	$DepMonitor.ParentMonitorID = $AvailabilityMonitor
	$DepMonitor.MemberMonitor = $AvailabilityMonitor
	$DepMonitor.Algorithm = "WorstOf"
	$DepMonitor.MemberUnAvailable = "Error"
	$DepMonitor.AlertSettings = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorAlertSettings
	$DepMonitor.AlertSettings.AlertOnState = 'Error'
	$DepMonitor.AlertSettings.AutoResolve = $true
	$DepMonitor.AlertSettings.AlertPriority = 'Normal'
	$DepMonitor.AlertSettings.AlertSeverity = 'Error'
	$DepMonitorAlertStringResourceID = "$DepMonitorName`.AlertMessage"
	$DepMonitorAlertMessage = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackStringResource($MP, $DepMonitorAlertStringResourceID)
	$DepMonitorAlertMessage.DisplayName = $DepMonitorDisplayName
	$DepMonitorAlertMessage.Description = "$DepMonitorDisplayName that rolls up health for all Watcher Nodes Monitoring $Target on port $Port."
	$DepMonitor.AlertSettings.AlertMessage = $DepMonitorAlertMessage

	#Increase MP version
    If ($IncreaseMPVersion)
    {
        Write-Verbose "Increasing version for management pack `"$MPName`"."
		$CurrentVersion = $MP.Version.Tostring()
        $vIncrement = $CurrentVersion.Split('.')
        $vIncrement[$vIncrement.Length - 1] = ([system.int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
        $NewVersion = ([string]::Join('.', $vIncrement))
        $MP.Version = $NewVersion
    }

    #Verify and save the monitor
    Try {
        Write-Verbose "Committing changes to management pack `"$MPName`"."
		$MP.verify()
        $MP.AcceptChanges()
        $Result = $true
		Write-Verbose "all MP elements for TCP Port Monitoring `"$Title`" have been successfully created in Management Pack '$MPName'($($MP.Version))."
    } Catch {
        $Result = $false
		$MP.RejectChanges()
		Write-Error $_.Exception
        Write-Error "Unable to create TCP Port Monitoring `"$Title`" in management pack $MPName."
    }
    $Result
}