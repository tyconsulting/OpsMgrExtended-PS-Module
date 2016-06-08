Workflow New-EventCollectionRule
{
    Param(
    [Parameter(Mandatory=$true)][String]$RuleName,
    [Parameter(Mandatory=$true)][String]$RuleDisplayName,
    [Parameter(Mandatory=$true)][String]$EventLog,
    [Parameter(Mandatory=$true)][String]$Publisher,
    [Parameter(Mandatory=$false)][Int]$EventID,
	[Parameter(Mandatory=$true)][String]$ClassName,
	[Parameter(Mandatory=$true)][Boolean]$RuleDisabled
    )
    
    #Get OpsMgrSDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_HOME"

	#Hard code which MP to use
    $MPName = "TYANG.Test.Windows.Monitoring"

    #Make sure MP exists
    Write-Verbose "Getting management pack '$MPName'"
    $MP = Get-OMManagementPack -SDKConnection $OpsMgrSDKConn -Name $MPName -ErrorAction SilentlyContinue
    If ($MP -eq $null)
    {
        #MP doesn't exist, create it
        Write-Verbose "management pack '$MPName' does not exist. creating now."
        $CreateMP = New-OMManagementPack -SDKConnection $OpsMgrSDKConn -Name $MPName -DisplayName "TYANG Test Windows Monitoring" -Version "1.0.0.0"
    }
    #Hard code frequency (900 seconds)
    $Frequency = 900

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
			New-OMEventCollectionRule -SDKConnection $USING:OpsMgrSDKConn -MPName $USING:MPName -RuleName $USING:RuleName -RuleDisplayName $USING:RuleDisplayName -ClassName $USING:ClassName -EventLog $USING:EventLog -Publisher $USING:Publisher -EventID $USING:EventID -Disabled $USING:RuleDisabled -IncreaseMPVersion $true
        }
    }

    If ($RuleCreated)
	{
		Write-Output "Rule `"$RuleName`" created."
	} else {
		Write-Error "Unable to create rule `"$RuleName`"."
	}
}

#Test
$RuleName = "Test.Event.Collection.Rule"
$RuleDisplayName = "Test Event Collection Rule"
$ClassName = "Microsoft.Windows.Server.6.2.OperatingSystem"
$EventLog="Application"
$EventID=100
$Publisher = "WSH"
$RuleDisabled = $true
New-EventCollectionRule -RuleName $RuleName -RuleDisplayName $RuleDisplayName -EventLog $EventLog -Publisher $Publisher -EventID $EventID -ClassName $ClassName -RuleDisabled $RuleDisabled -Verbose
