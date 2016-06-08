Workflow Create-EventCollectionRule
{
    Param(
    [Parameter(Mandatory=$true)][String]$RuleName,
    [Parameter(Mandatory=$true)][String]$RuleDisplayName,
    [Parameter(Mandatory=$true)][String]$ClassDisplayName,
    [Parameter(Mandatory=$true)][String]$EventLog,
    [Parameter(Mandatory=$true)][String]$Publisher,
    [Parameter(Mandatory=$false)][Int]$EventID,
	[Parameter(Mandatory=$false)][String]$RuleDisabled,
    [Parameter(Mandatory=$false)][String]$SharePointListItemID
    )
    
    #Get OpsMgrSDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_TYANG"

	#Get SharePointSDK connection object (Defined in the SharePointSDK SMA module)
	$SPConn = Get-AutomationConnection "RequestsSPSite"

	#SharePoint List Name
	$SharePointListName = "New SCOM Event Collection Rules"

    #Hard code which MP to use
    $MPName = "TYANG.Test.Windows.Monitoring"

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

    #Create Event Collection Rule, MP Version will be increased by 0.0.0.1
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
			New-OMEventCollectionRule -SDKConnection $USING:OpsMgrSDKConn -MPName $USING:MPName -RuleName $USING:RuleName -RuleDisplayName $USING:RuleDisplayName -ClassName $USING:ClassName -EventLog $USING:EventLog -Publisher $USING:Publisher -EventID $USING:EventID -Disabled $USING:bRuleDisabled -IncreaseMPVersion $true
        }
    }

    If ($RuleCreated)
	{
		Write-Output "Rule `"$RuleName`" created."
	} else {
		Write-Error "Unable to create rule `"$RuleName`"."
	}

    #Update SharePoint List Item if this runbook is initiated from SharePoint using the SharePointSDK SMA module published here: http://blog.tyang.org/2014/12/23/sma-integration-module-sharepoint-list-operations/
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