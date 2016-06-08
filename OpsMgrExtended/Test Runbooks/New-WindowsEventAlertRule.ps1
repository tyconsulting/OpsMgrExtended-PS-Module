Workflow New-WindowsEventAlertRule
{
    Param(
    [Parameter(Mandatory=$true)][String]$RuleName,
    [Parameter(Mandatory=$true)][String]$RuleDisplayName,
    [Parameter(Mandatory=$true)][String]$ClassName,
	[Parameter(Mandatory=$true)][String]$EventLog,
    [Parameter(Mandatory=$true)][Int]$EventID,
	[Parameter(Mandatory=$true)][String]$EventSource,
	[Parameter(Mandatory=$true)][ValidateSet('Success', 'Error', 'Warning', 'Information', 'Audit Failure', 'Audit Success')][String]$EventLevel,
	[Parameter(Mandatory=$true)][String]$AlertName,
    [Parameter(Mandatory=$true)][ValidateSet('Critical', 'Warning', 'Information')][String]$AlertSeverity,
    [Parameter(Mandatory=$true)][ValidateSet('Low', 'Medium', 'High')][String]$AlertPriority
    )
    
    #Get OpsMgrSDK connection object
    $SDK = "OpsMgrMS01"

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
    
    #Get Alert Priority
    $iAlertPriority = InlineScript
    {
 	    Switch ($USING:AlertPriority)
	    {
		    'Low' {$iAlertPriority = 0}
		    'Medium' {$iAlertPriority = 1}
		    'High' {$iAlertPriority = 2}
	    }
        $iAlertPriority   
    }
    
    #Get Alert Severity
        $iAlertSeverity = InlineScript
    {
 	    Switch ($USING:AlertSeverity)
	    {
		    'Information' {$iAlertSeverity = 0}
		    'Warning' {$iAlertSeverity = 1}
		    'Critical' {$iAlertSeverity = 2}
	    }
        $iAlertSeverity   
    }
    #Data Source Module Configuration:
    [OpsMgrExtended.ModuleConfiguration[]]$arrDataSourceModules = @()
    $DAModuleTypeName = "Microsoft.Windows.EventProvider"
    $DAConfiguration = @"
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
        <RegExExpression>
        <ValueExpression>
            <XPathQuery Type="String">PublisherName</XPathQuery>
        </ValueExpression>
        <Operator>ContainsSubstring</Operator>
        <Pattern>$EventSource</Pattern>
        </RegExExpression>
    </Expression>
    <Expression>
        <SimpleExpression>
        <ValueExpression>
            <XPathQuery Type="Integer">EventLevel</XPathQuery>
        </ValueExpression>
        <Operator>Equal</Operator>
        <ValueExpression>
            <Value Type="Integer">$iEventLevel</Value>
        </ValueExpression>
        </SimpleExpression>
    </Expression>
    </And>
</Expression>
"@
    $DAMemberModuleName = "DS"
    $DataSourceConfiguration = New-OMModuleConfiguration -ModuleTypeName $DAModuleTypeName -Configuration $DAConfiguration -MemberModuleName $DAMemberModuleName
    $arrDataSourceModules += $DataSourceConfiguration

    #Write Action modules
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

	#Alert configuration
    $arrAlertConfigurations = @()
	$AlertDescription = @"
Computer: {0}
Event Description: {1}
"@
	$StringResource = "$RuleName`.AlertMessage"
	$AlertConfiguration = New-OMAlertConfiguration -AlertName $AlertName -AlertDescription $AlertDescription -StringResource $StringResource
    $arrAlertConfigurations += $AlertConfiguration
    #Create Windows Event alert Rule, MP Version will be increased by 0.0.0.1
    $MPName = "Test.WindowsEventAlerts"
    $RuleCreated = InlineScript
    {

        
        #Validate rule Name
        If ($USING:RuleName -notmatch "([a-zA-Z0-9]+\.)+[a-zA-Z0-9]+")
        {
            #Invalid rule name entered
            $ErrMsg = "Invalid rule name specified. Please make sure it only contains alphanumeric charaters and only use '.' to separate words. i.e. 'Your.Company.XYZ.Event.Alert.Rule'."
            Write-Error $ErrMsg 
        } else {
            #Name is valid, creating the rule
            #Write-Verbose "$($USING:arrAlertConfigurations.count)"
			New-OMRule -SDK $USING:SDK -MPName $USING:MPName -RuleName $USING:RuleName -RuleDisplayName $USING:RuleDisplayName -Category "Alert" -ClassName $USING:ClassName -DataSourceModules $USING:arrDataSourceModules -WriteActionModules $USING:arrWriteActionModules -Remotable $false -GenerateAlert $true -AlertConfigurations $USING:arrAlertConfigurations
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
New-OMManagementPack -Name "Test.WindowsEventAlerting" -DisplayName "Test Windows Event Alerting" -Version 0.0.0.1 -SDK OpsMgrMS01
New-WindowsEventAlertRule -RuleName "Test.Disk.Controller.Event.Alert.Rule" -RuleDisplayName "Disk Controller Error Event Alert Rule" -ClassName "Microsoft.Windows.OperatingSystem" -EventLog "System" -EventID 11 -EventSource "Disk" -EventLevel Error -AlertName "Windows Disk Controller Error" -AlertSeverity Critical -AlertPriority High -verbose

#>
