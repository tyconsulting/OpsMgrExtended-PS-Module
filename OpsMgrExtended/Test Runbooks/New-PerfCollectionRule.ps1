Workflow New-PerfCollectionRule
{
    Param(
    [Parameter(Mandatory=$true)][String]$RuleName,
    [Parameter(Mandatory=$true)][String]$RuleDisplayName,
    [Parameter(Mandatory=$true)][String]$CounterName,
    [Parameter(Mandatory=$true)][String]$ObjectName,
    [Parameter(Mandatory=$false)][String]$InstanceName,
	[Parameter(Mandatory=$true)][String]$ClassName,
	[Parameter(Mandatory=$false)][Boolean]$RuleDisabled
    )
    
    #Get OpsMgrSDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_HOME"

    #Hard code which MP to use
    $MPName = "TYANG.Test.Windows.Monitoring"

    #Hard code frequency (900 seconds)
    $Frequency = 900

    #Create Performance Collection Rule, MP Version will be increased by 0.0.0.1
    $RuleCreated = InlineScript
    {

        #Validate rule Name
        If ($USING:RuleName -notmatch "([a-zA-Z0-9]+\.)+[a-zA-Z0-9]+")
        {
            #Invalid rule name entered
            $ErrMsg = "Invalid rule name specified. Please make sure it only contains alphanumeric charaters and only use '.' to separate words. i.e. 'Your.Company.Percentage.Processor.Time.Performance.Collection.Rule'."
            Write-Error $ErrMsg 
        } else {
            #Name is valid, creating the rule           
            New-OMPerformanceCollectionRule -SDKConnection $USING:OpsMgrSDKConn -MPName $USING:MPName -RuleName $USING:RuleName -RuleDisplayName $USING:RuleDisplayName -ClassName $USING:ClassName -CounterName $USING:CounterName -ObjectName $USING:ObjectName -InstanceName $USING:InstanceName -Frequency $USING:Frequency -Disabled $USING:RuleDisabled -IncreaseMPVersion $true
        }
    }

    If ($RuleCreated)
	{
		Write-Output "Rule `"$RuleName`" created."
	} else {
		Throw "Unable to create rule `"$RuleName`"."
	}
}