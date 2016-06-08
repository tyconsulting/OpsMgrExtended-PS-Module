Workflow Create-PerfCollectionRule
{
    Param(
    [Parameter(Mandatory=$true)][String]$RuleName,
    [Parameter(Mandatory=$true)][String]$RuleDisplayName,
    [Parameter(Mandatory=$true)][String]$ClassDisplayName,
    [Parameter(Mandatory=$true)][String]$CounterName,
    [Parameter(Mandatory=$true)][String]$ObjectName,
    [Parameter(Mandatory=$false)][String]$InstanceName,
	[Parameter(Mandatory=$false)][String]$RuleDisabled,
    [Parameter(Mandatory=$false)][String]$SharePointListItemID
    )
    
    #Get OpsMgrSDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_TYANG"

    #Hard code which MP to use
    $MPName = "TYANG.Test.Windows.Monitoring"

	#Get SharePointSDK connection object (Defined in the SharePointSDK SMA module: http://blog.tyang.org/2014/12/23/sma-integration-module-sharepoint-list-operations/)
	$SPConn = Get-AutomationConnection "RequestsSPSite"

	#SharePoint List Name
	$SharePointListName = "New SCOM Performance Collection Rules"

    #Hard code frequency (900 seconds)
    $Frequency = 900

    #Determine monitoring class
    Switch -CaseSensitive ($ClassDisplayName)
    {
        "Windows Server OS" {$ClassName="Microsoft.Windows.Server.OperatingSystem"}
        "Windows Server 2012 OS" {$ClassName="Microsoft.Windows.Server.6.2.OperatingSystem"}
        "Windows Client OS" {$ClassName="Microsoft.Windows.Client.OperatingSystem"}
    }

	#Determine if the rule should be disabled
	if ($RuleDisabled -ieq 'true')
	{
		$bRuleDisabled = $true
	} else {
		$bRuleDisabled = $false
	}

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
            New-OMPerformanceCollectionRule -SDKConnection $USING:OpsMgrSDKConn -MPName $USING:MPName -RuleName $USING:RuleName -RuleDisplayName $USING:RuleDisplayName -ClassName $USING:ClassName -CounterName $USING:CounterName -ObjectName $USING:ObjectName -InstanceName $USING:InstanceName -Frequency $USING:Frequency -Disabled $USING:bRuleDisabled -IncreaseMPVersion $true
        }
    }

    If ($RuleCreated)
	{
		Write-Output "Rule `"$RuleName`" created."
	} else {
		Write-Error "Unable to create monitor `"$RuleName`"."
	}

	#Update SharePoint List Item if this runbook is initiated from SharePoint using the SharePointSDK SMA Module (http://blog.tyang.org/2014/12/23/sma-integration-module-sharepoint-list-operations/).
    If ($SharePointListItemID)
    {
        Write-Output "Updating SharePoint List Item"
		$ListFields = InlineScript
		{
			Import-Module SharePointSDK -Verbose:$false
			$ListFields = Get-SPListFields -SPConnection $USING:SPConn -ListName $USING:SharePointListName
			,$ListFields
		}
		$ReturnMessageField = ($ListFields | Where-Object {$_.Title -ieq 'Return message' -and $_.ReadOnlyField -eq $false}).InternalName
		$UpdatedFields = @{
			$ReturnMessageField = "Rule created."
		}
		$UpdateListItem = InlineScript
		{
			Import-Module SharePointSDK -Verbose:$false
			Update-SPListItem -ListFieldsValues $USING:UpdatedFields -ListItemID $USING:SharePointListItemID -ListName $USING:SharePointListName -SPConnection $USING:SPConn
		}
    }    
}