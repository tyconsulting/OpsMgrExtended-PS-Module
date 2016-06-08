Workflow New-2StateEventMonitor
{
    Param(
    [Parameter(Mandatory=$true)][String]$MonitorName,
    [Parameter(Mandatory=$true)][String]$MonitorDisplayName,
    [Parameter(Mandatory=$true)][String]$ClassName,
    [Parameter(Mandatory=$true)][String]$ParentMonitor,
    [Parameter(Mandatory=$true)][String]$EventLog,
    [Parameter(Mandatory=$true)][String]$Publisher,
    [Parameter(Mandatory=$true)][Int]$UnhealthyEventID,
    [Parameter(Mandatory=$true)][Int]$HealthyEventID,
    [Parameter(Mandatory=$true)][String]$UnhealthyState,
	[Parameter(Mandatory=$true)][Boolean]$MonitorDisabled
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
            New-OM2StateEventMonitor -SDKConnection $USING:OpsMgrSDKConn -MPName $USING:MPName -MonitorName $USING:MonitorName -MonitorDisplayName $USING:MonitorDisplayName -ClassName $USING:ClassName -ParentMonitor $USING:ParentMonitor -EventLog $USING:EventLog -Publisher $USING:Publisher -UnhealthyEventID $USING:UnhealthyEventID -HealthyEventID $USING:HealthyEventID -UnhealthyState $USING:UnhealthyState -Disabled $USING:MonitorDisabled -IncreaseMPVersion $true
        }
    }
	If ($MonitorCreated)
	{
		Write-Output "Monitor `"$MonitorName`" created."
	} else {
		Write-Error "Unable to create monitor `"$Monitorname`"."
	}
}