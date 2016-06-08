Workflow New-WMIEventCollectionRule
{
    Param(
    [Parameter(Mandatory=$true)][String]$RuleName,
    [Parameter(Mandatory=$true)][String]$RuleDisplayName,
    [Parameter(Mandatory=$true)][String]$ClassName,
    [Parameter(Mandatory=$false)][String]$WMINameSpace='Root\CIMV2',
    [Parameter(Mandatory=$true)][String]$WMIQuery,
    [Parameter(Mandatory=$false)][Int]$PollingInterval=60
    )
    
    #Get OpsMgrSDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_HOME"

    #Data Source Module Configuration:
    [OpsMgrExtended.ModuleConfiguration[]]$arrDataSourceModules = @()
    $DAModuleTypeName = "Microsoft.Windows.WmiEventProvider.EventProvider"
    Write-Verbose "WMI Query: `"$WMIQuery`""
    $DAConfiguration = @"
<NameSpace>Root\CIMV2</NameSpace>
<Query>$WMIQuery</Query>
<PollInterval>$PollingInterval</PollInterval>
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
    $MPName = "Test.WMIEventCollection"
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
			New-OMRule -SDKConnection $USING:OpsMgrSDKConn -MPName $USING:MPName -RuleName $USING:RuleName -RuleDisplayName $USING:RuleDisplayName -Category "EventCollection" -ClassName $USING:ClassName -DataSourceModules $USING:arrDataSourceModules -WriteActionModules $USING:arrWriteActionModules -Remotable $false
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
New-OMManagementPack -Name "Test.WMIEventCollection" -DisplayName "Test WMI Event Collection" -Version 0.0.0.1 -SDK OpsMgrMS01

New-WMIEventCOllectionRule -RuleName "Test.WMIEventCollection.USB.Storage.Connection.Event.Collection.Rule" -RuleDisplayName "USB Storage Device Connect Event Collection Rule" -ClassName "Microsoft.Windows.OperatingSystem" -WMIQuery "select * from __InstanceCreationEvent within 1 where TargetInstance ISA 'Win32_PnPEntity' and TargetInstance.Service='WUDFRd'" -verbose
#>