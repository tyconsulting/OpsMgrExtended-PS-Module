Workflow Create-PerformanceMonitor
{
    Param(
    [Parameter(Mandatory=$true)][String]$MonitorName,
    [Parameter(Mandatory=$true)][String]$MonitorDisplayName,
    [Parameter(Mandatory=$true)][String]$CounterName,
    [Parameter(Mandatory=$true)][String]$ObjectName,
    [Parameter(Mandatory=$false)][String]$InstanceName,
    [Parameter(Mandatory=$true)][String]$Threshold,
    [Parameter(Mandatory=$true)][String]$UnhealthyState,
	[Parameter(Mandatory=$false)][String]$UnhealthyCondition,
	[Parameter(Mandatory=$true)][String]$Scope,
    [Parameter(Mandatory=$false)][String]$SharePointListItemID
    )
    
    #Get OpsMgrSDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_TYANG"
	
	#Get SharePointSDK connection object (Defined in the SharePointSDK SMA module: http://blog.tyang.org/2014/12/23/sma-integration-module-sharepoint-list-operations/)
	$SPConn = Get-AutomationConnection "RequestsSPSite"

	#SharePoint List Name
	$SharePointListName = "New SCOM 2-State Performance Monitor"
    #Hard code which MP to use
    $MPName = "TYANG.SMA.Automation.Perf.Monitor.Demo"

	#Work out if this monitor should only be enabled on a group
	Switch -CaseSensitive ($Scope)
	{
		"All Windows Servers"
		{
			$disabled = $false
			$Group = $null
			$IncreaseVersion = $true
		}
		"All SQL Servers"
		{
			$disabled = $true
			$Group = "TYANG.SQL.Server.Computer.And.Health.Service.Watcher.Group"
			$IncreaseVersion = $false
		}
		"All Hyper-V Servers"
		{
			$disabled = $true
			$Group = "TYANG.HyperV.Server.Computer.And.Health.Service.Watcher.Group"
			$IncreaseVersion = $false
		}
		"All Domain Controllers"
		{
			$disabled = $true
			$Group = "TYANG.Domain.Controller.Computer.And.Health.Service.Watcher.Group"
			$IncreaseVersion = $false
		}
		"All ConfigMgr Servers"
		{
			$disabled = $true
			$Group = "TYANG.ConfigMgr.Server.Computer.And.Health.Service.Watcher.Group"
			$IncreaseVersion = $false
		}
	}

	#Process Unhealthy Condition
	If ($UnhealthyCondition -ieq "Under Threshold")
	{
		$UnhealthyWhenUnder = $true
	} else {
		$UnhealthyWhenUnder = $false
	}
	#Hard code frequency (900 seconds)
    $Frequency = 900

    #Hardcode monitoring class
    $ClassName="Microsoft.Windows.Server.Computer"

    #Create Performance Monitor, MP Version will be increased by 0.0.0.1
    $MonitorCreated = InlineScript
    {

        #Validate Monitor Name
        If ($USING:MonitorName -notmatch "([a-zA-Z0-9]+\.)+[a-zA-Z0-9]+")
        {
            #Invalid Monitor name entered
            $ErrMsg = "Invalid monitor name specified. Please make sure it only contains alphanumeric charaters and only use '.' to separate words. i.e. 'Your.Company.Windows.Free.Memory.Percentage.Monitor'."
            Write-Error $ErrMsg 
        } else {
            #Name is valid, creating the monitor
			New-OM2StatePerformanceMonitor -SDKConnection $USING:OpsMgrSDKConn -MPName $USING:MPName -MonitorName $USING:MonitorName -MonitorDisplayName $USING:MonitorDisplayName -ClassName $USING:ClassName -CounterName $USING:CounterName -ObjectName $USING:ObjectName -InstanceName $USING:InstanceName -Threshold $USING:Threshold -UnhealthyWhenUnder $USING:UnhealthyWhenUnder -Frequency $USING:Frequency -UnhealthyState $USING:UnhealthyState -Disabled $USING:disabled -IncreaseMPVersion $USING:IncreaseVersion
        }
    }
	If ($MonitorCreated)
	{
		Write-Output "Monitor `"$MonitorName`" created."
	} else {
		Write-Error "Unable to create monitor `"$Monitorname`"."
	}

	#Create Override if the monitor is scoped to a group
	if ($Group -ne $null)
	{
		$OverrideCreated = InlineScript {
			New-OMOverride -SDKConnection $USING:OpsMgrSDKConn -MPName $USING:MPName -OverrideWorkflow $USING:MonitorName -WorkflowType "Monitor" -Target $USING:Group -OverrideParameter Enabled -OverrideValue $true -IncreaseMPVersion $true
		}
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
			$ReturnMessageField = "Monitor created."
		}
		$UpdateListItem = InlineScript
		{
			Import-Module SharePointSDK -Verbose:$false
			Update-SPListItem -ListFieldsValues $USING:UpdatedFields -ListItemID $USING:SharePointListItemID -ListName $USING:SharePointListName -SPConnection $USING:SPConn
		}
    }
}