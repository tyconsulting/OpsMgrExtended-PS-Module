Workflow Create-EventMonitor
{
    Param(
    [Parameter(Mandatory=$true)][String]$MonitorName,
    [Parameter(Mandatory=$true)][String]$MonitorDisplayName,
    [Parameter(Mandatory=$true)][String]$ClassDisplayName,
    [Parameter(Mandatory=$true)][String]$ParentMonitor,
    [Parameter(Mandatory=$true)][String]$EventLog,
    [Parameter(Mandatory=$true)][String]$Publisher,
    [Parameter(Mandatory=$true)][Int]$UnhealthyEventID,
    [Parameter(Mandatory=$true)][Int]$HealthyEventID,
    [Parameter(Mandatory=$true)][String]$UnhealthyState,
	[Parameter(Mandatory=$false)][String]$MonitorDisabled,
    [Parameter(Mandatory=$false)][String]$SharePointListItemID
    )
    
    #Get OpsMgrSDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_TYANG"

	#Get SharePointSDK connection object (Defined in the SharePointSDK SMA module: http://blog.tyang.org/2014/12/23/sma-integration-module-sharepoint-list-operations/)
	$SPConn = Get-AutomationConnection "RequestsSPSite"

	#SharePoint List Name
	$SharePointListName = "New SCOM Event Monitors"

    #Hard code which MP to use
    $MPName = "TYANG.Test.Windows.Monitoring"

    #Determine monitoring class
    Switch -CaseSensitive ($ClassDisplayName)
    {
        "Windows Server OS" {$ClassName="Microsoft.Windows.Server.OperatingSystem"}
        "Windows Server 2012 OS" {$ClassName="Microsoft.Windows.Server.6.2.OperatingSystem"}
        "Windows Client OS" {$ClassName="Microsoft.Windows.Client.OperatingSystem"}
    }

	#Determine if monitor should be disabled
	if ($MonitorDisabled -ieq 'true')
	{
		$bMonitorDisabled = $true
	} else {
		$bMonitorDisabled = $false
	}

    #Create Event Monitor, MP Version will be increased by 0.0.0.1
    $MonitorCreated = InlineScript
    {

        #Validate Monitor Name
        If ($USING:MonitorName -notmatch "([a-zA-Z0-9]+\.)+[a-zA-Z0-9]+")
        {
            #Invalid Monitor name entered
            $ErrMsg = "Invalid monitor name specified. Please make sure it only contains alphanumeric charaters and only use '.' to separate words. i.e. 'Your.Company.Event.1234.Monitor'."
            Write-Error $ErrMsg 
        } else {
            #Name is valid, creating the monitor
            New-OM2StateEventMonitor -SDKConnection $USING:OpsMgrSDKConn -MPName $USING:MPName -MonitorName $USING:MonitorName -MonitorDisplayName $USING:MonitorDisplayName -ClassName $USING:ClassName -ParentMonitor $USING:ParentMonitor -EventLog $USING:EventLog -Publisher $USING:Publisher -UnhealthyEventID $USING:UnhealthyEventID -HealthyEventID $USING:HealthyEventID -UnhealthyState $USING:UnhealthyState -Disabled $USING:bMonitorDisabled -IncreaseMPVersion $true
        }
    }
	If ($MonitorCreated)
	{
		Write-Output "Monitor `"$MonitorName`" created."
	} else {
		Write-Error "Unable to create monitor `"$Monitorname`"."
	}

    #Update SharePoint List Item if this runbook is initiated from SharePoint using the SharePointSDK SMA Module (http://blog.tyang.org/2014/12/23/sma-integration-module-sharepoint-list-operations/)
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
			$ReturnMessageField = "Monitor created."
		}
		$UpdateListItem = InlineScript
		{
			Import-Module SharePointSDK -Verbose:$false
			Update-SPListItem -ListFieldsValues $USING:UpdatedFields -ListItemID $USING:SharePointListItemID -ListName $USING:SharePointListName -SPConnection $USING:SPConn
		}
    }
}