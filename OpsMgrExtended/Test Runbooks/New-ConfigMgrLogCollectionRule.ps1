Workflow New-ConfigMgrLogCollectionRule
{
    Param(
    [Parameter(Mandatory=$true)][String]$RuleName,
    [Parameter(Mandatory=$true)][String]$RuleDisplayName,
	[Parameter(Mandatory=$true)][String]$ManagementPackName,
    [Parameter(Mandatory=$true)][ValidateSet("Microsoft.SystemCenter2012.ConfigurationManager.DistributionPoint","Microsoft.SystemCenter2012.ConfigurationManager.ManagementPoint","Microsoft.SystemCenter2012.ConfigurationManager.SiteServer","Microsoft.SystemCenter2012.ConfigurationManager.Client")][String]$ClassName,
    [Parameter(Mandatory=$true)][String]$LogDirectory,
    [Parameter(Mandatory=$true)][String]$LogFileName,
	[Parameter(Mandatory=$true)][String]$EventID,
	[Parameter(Mandatory=$true)][ValidateSet('Success', 'Error', 'Warning', 'Information', 'Audit Failure', 'Audit Success')][String]$EventLevel,
    [Parameter(Mandatory=$false)][Int]$IntervalSeconds=120
    )
    
    #Get OpsMgrSDK connection object
    $SDK = "OpsMgrMS01"

	#Get the destination MP
	Write-Verbose "Getting managemnet pack '$ManagementPackName'..."
    $MP = Get-OMManagementPack -SDK $SDK -Name $ManagementPackName

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

	#Make sure the destination MP is referencing the Microsoft.Windows.Library MP
	$MPReferences = $MP.References
	Foreach ($item in $MPReferences)
	{
		If ($item.value.Name -eq "Microsoft.Windows.Library")
		{
			$WinLibRef = $item.key
		}
	}
	If ($WinLibRef -eq $NULL)
	{
		#Create the reference
		$NewMPRef = New-OMManagementPackReference -SDK $SDK -ReferenceMPName "Microsoft.Windows.Library" -Alias "Windows" -UnsealedMPName $ManagementPackName
		If ($NewMPRef -eq $true)
		{
			$WinLibRef = "Windows"
		} else {
			Write-Error "Unable to create a reference for 'Microsoft.Windows.Library' MP in the destination management pack '$ManagementPackName'. Unable to continue."
			Return $false
		}
	}
	#Get Event Level
    $iEventLevel = Inlinescript
    {
	    Switch ($USING:EventLevel)
	    {
		    'Success' {$iEventLevel = 0}
		    'Error' {$iEventLevel = 1}
		    'Warning' {$iEventLevel = 2}
		    'Information' {$iEventLevel = 4}
		    'Audit Failure' {$iEventLevel = 16}
		    'Audit Success' {$iEventLevel = 8}
	    }
        $iEventLevel
    }

    #Data Source Module Configuration:
    [OpsMgrExtended.ModuleConfiguration[]]$arrDataSourceModules = @()
	#Determine which Data Source module to use (client vs server)
	If ($ClassName -ieq 'Microsoft.SystemCenter2012.ConfigurationManager.Client')
	{
		$DAModuleTypeName = "ConfigMgr.Log.Collection.Library.ConfigMgr.Client.Log.DS"
	} else {
		$DAModuleTypeName = "ConfigMgr.Log.Collection.Library.ConfigMgr.Server.Log.DS"
	}

    Write-Verbose "WMI Query: `"$WMIQuery`""
    $DAConfiguration = @"
<IntervalSeconds>$IntervalSeconds</IntervalSeconds>
<ComputerName>`$Target/Host/Property[Type="$WinLibRef!Microsoft.Windows.Computer"]/NetworkName$</ComputerName>
<EventID>$EventID</EventID>
<EventCategory>0</EventCategory>
<EventLevel>$iEventLevel</EventLevel>
<LogDirectory>$LogDirectory</LogDirectory>
<FileName>$LogFileName</FileName>
"@
    $DAMemberModuleName = "DS"
    $DataSourceConfiguration = New-OMModuleConfiguration -ModuleTypeName $DAModuleTypeName -Configuration $DAConfiguration -MemberModuleName $DAMemberModuleName
    $arrDataSourceModules += $DataSourceConfiguration

    #Write Action modules
    [OpsMgrExtended.ModuleConfiguration[]]$arrWriteActionModules = @()
    $WAWriteToDBConfiguration = New-OMModuleConfiguration -ModuleTypeName "Microsoft.SystemCenter.CollectEvent" -MemberModuleName "WriteToDB"
    $WAWriteToDWConfiguration = New-OMModuleConfiguration -ModuleTypeName "Microsoft.SystemCenter.DataWarehouse.PublishEventData" -MemberModuleName "WriteToDW"
    $WAWriteToOMSConfiguration = New-OMModuleConfiguration -ModuleTypeName "Microsoft.SystemCenter.CollectCloudGenericEvent" -MemberModuleName "WriteToOMS"
    $arrWriteActionModules += $WAWriteToDBConfiguration
    $arrWriteActionModules += $WAWriteToDWConfiguration
    $arrWriteActionModules += $WAWriteToOMSConfiguration

    #Create WMI Event Collection Rule, MP Version will be increased by 0.0.0.1
    $RuleCreated = InlineScript
    {

        
        #Validate rule Name
        If ($USING:RuleName -notmatch "([a-zA-Z0-9]+\.)+[a-zA-Z0-9]+")
        {
            #Invalid rule name entered
            $ErrMsg = "Invalid rule name specified. Please make sure it only contains alphanumeric charaters and only use '.' to separate words. i.e. 'Your.Company.Application.Log.EventID.1234.Collection.Rule'."
            Write-Error $ErrMsg 
        } else {
            #Name is valid, creating the rule
			New-OMRule -SDK $USING:SDK -MPName $USING:ManagementPackName -RuleName $USING:RuleName -RuleDisplayName $USING:RuleDisplayName -Category "EventCollection" -ClassName $USING:ClassName -DataSourceModules $USING:arrDataSourceModules -WriteActionModules $USING:arrWriteActionModules -Remotable $false
        }
    }

    If ($RuleCreated)
	{
		Write-Output "Rule `"$RuleName`" created."
	} else {
		Write-Error "Unable to create Rule `"$RuleName`"."
	}
}

#Example:
<#
$ManagementPackName = "Test.Collect.ConfigMgr.Logs"
New-OMManagementPack -Name $ManagementPackName -DisplayName "Test Collect ConfigMgr Logs" -Version 0.0.0.1 -SDK OpsMgrMS01

New-ConfigMgrLogCollectionRule -RuleName "ConfigMgr.Client.DataTransferService.Log.Collection.Rule" -RuleDisplayName "Collect ConfigMgr DataTransferService Log" -ManagementPackName $ManagementPackName -ClassName "Microsoft.SystemCenter2012.ConfigurationManager.Client" -LogDirectory "C:\Windows\CCM\Logs" -LogFileName "DataTransferService.log" -EventID 30000 -EventLevel "Information" -verbose
#>