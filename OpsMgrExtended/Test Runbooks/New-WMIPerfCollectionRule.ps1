Workflow New-WMIPerfCollectionRule
{
    Param(
    [Parameter(Mandatory=$true)][String]$RuleName,
    [Parameter(Mandatory=$true)][String]$RuleDisplayName,
    [Parameter(Mandatory=$true)][String]$ClassName,
    [Parameter(Mandatory=$false)][String]$WMINamespace="Root\CIMV2",
	[Parameter(Mandatory=$true)][String]$WMIQuery,
	[Parameter(Mandatory=$false)][Int]$IntervalSeconds=900,
	[Parameter(Mandatory=$true)][String]$ObjectName,
	[Parameter(Mandatory=$true)][String]$CounterName,
	[Parameter(Mandatory=$false)][String]$InstanceNameWMIProperty,
	[Parameter(Mandatory=$true)][String]$ValueWMIProperty
    )
    
    #Get OpsMgrSDK connection object
    $SDK = "OpsMgrMS01"

    #Data Source Module Configuration:
    [OpsMgrExtended.ModuleConfiguration[]]$arrDataSourceModules = @()
    $DAModuleTypeName = "Microsoft.Windows.WmiProvider"
    $DAConfiguration = @"
<NameSpace>$WMINamespace</NameSpace>
<Query>$WMIQuery</Query>
<Frequency>$IntervalSeconds</Frequency>
"@
    $DAMemberModuleName = "DS"
    $DataSourceConfiguration = New-OMModuleConfiguration -ModuleTypeName $DAModuleTypeName -Configuration $DAConfiguration -MemberModuleName $DAMemberModuleName
    $arrDataSourceModules += $DataSourceConfiguration

	#Condition Detection Module
	If ($InstanceNameWMIProperty -ne $null)
	{
		$InstanceName = "`$Data/Property[@Name='$InstanceNameWMIProperty']$"
	} else {
		$InstanceName = "_Total"
	}
	$CDModuleTypeName = "System.Performance.DataGenericMapper"
	$CDConfig = @"
<ObjectName>Logical Disk</ObjectName>
<CounterName>$CounterName</CounterName>
<InstanceName>$InstanceName</InstanceName>
<Value>`$Data/Property[@Name='$ValueWMIProperty']$</Value>	
"@
	$ConditionDetectionConfiguration = New-OMModuleConfiguration -ModuleTypeName $CDModuleTypeName -Configuration $CDConfig -MemberModuleName "MapToPerf"

    #Write Action modules
    [OpsMgrExtended.ModuleConfiguration[]]$arrWriteActionModules = @()
    $WAWriteToDBConfiguration = New-OMModuleConfiguration -ModuleTypeName "Microsoft.SystemCenter.CollectPerformanceData" -MemberModuleName "WriteToDB"
    $WAWriteToDWConfiguration = New-OMModuleConfiguration -ModuleTypeName "Microsoft.SystemCenter.DataWarehouse.PublishPerformanceData" -MemberModuleName "WriteToDW"
    $WAWriteToOMSConfiguration = New-OMModuleConfiguration -ModuleTypeName "Microsoft.SystemCenter.CollectCloudPerformanceData" -MemberModuleName "WriteToOMS"
    $arrWriteActionModules += $WAWriteToDBConfiguration
    $arrWriteActionModules += $WAWriteToDWConfiguration
    $arrWriteActionModules += $WAWriteToOMSConfiguration

    #Create WMI Event Collection Rule, MP Version will be increased by 0.0.0.1
    $MPName = "Test.WMIPerfCollection"
    $RuleCreated = InlineScript
    {

        
        #Validate rule Name
        If ($USING:RuleName -notmatch "([a-zA-Z0-9]+\.)+[a-zA-Z0-9]+")
        {
            #Invalid rule name entered
            $ErrMsg = "Invalid rule name specified. Please make sure it only contains alphanumeric charaters and only use '.' to separate words. i.e. 'Your.Company.XYZ.WMI.Performance.Collection.Rule'."
            Write-Error $ErrMsg 
        } else {
            #Name is valid, creating the rule
			New-OMRule -SDK $USING:SDK -MPName $USING:MPName -RuleName $USING:RuleName -RuleDisplayName $USING:RuleDisplayName -Category "PerformanceCollection" -ClassName $USING:ClassName -DataSourceModules $USING:arrDataSourceModules -ConditionDetectionModule $USING:ConditionDetectionConfiguration -WriteActionModules $USING:arrWriteActionModules -Remotable $false
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
New-OMManagementPack -Name "Test.WMIPerfCollection" -DisplayName "Test WMI Performance Collection" -Version 0.0.0.1 -SDK OpsMgrMS01

New-WMIPerfCollectionRule -RuleName "Test.WMIPerfCollection.Process.Count.WMI.Performance.Collection.Rule" -RuleDisplayName "Windows Server Process Count Performance Collection Rule" -ClassName "Microsoft.Windows.OperatingSystem" -WMIQuery "select Processes from Win32_PerfRawData_PerfOS_Objects" -ObjectName "Process" -CounterName "ProcessCount"  -ValueWMIProperty "Processes" -verbose
#>