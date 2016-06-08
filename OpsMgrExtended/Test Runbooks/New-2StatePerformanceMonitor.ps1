Workflow New-2StatePerformanceMonitor
{
    Param(
    [Parameter(Mandatory=$true)][String]$MonitorName,
    [Parameter(Mandatory=$true)][String]$MonitorDisplayName,
    [Parameter(Mandatory=$true)][String]$CounterName,
    [Parameter(Mandatory=$true)][String]$ObjectName,
    [Parameter(Mandatory=$false)][String]$InstanceName,
	[Parameter(Mandatory=$true)][String]$ClassName,
    [Parameter(Mandatory=$true)][String]$Threshold,
    [Parameter(Mandatory=$true)][String]$UnhealthyState,
	[Parameter(Mandatory=$true)][Boolean]$UnhealthyWhenUnder
    )
    
    #Get OpsMgrSDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_HOME"

    #Hard code which MP to use
    $MPName = "TYANG.SMA.Automation.Perf.Monitor.Demo"
	
	#Hard code frequency (900 seconds)
    $Frequency = 900

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
			New-OM2StatePerformanceMonitor -SDKConnection $USING:OpsMgrSDKConn -MPName $USING:MPName -MonitorName $USING:MonitorName -MonitorDisplayName $USING:MonitorDisplayName -ClassName $USING:ClassName -CounterName $USING:CounterName -ObjectName $USING:ObjectName -InstanceName $USING:InstanceName -Threshold $USING:Threshold -UnhealthyWhenUnder $USING:UnhealthyWhenUnder -Frequency $USING:Frequency -UnhealthyState $USING:UnhealthyState -IncreaseMPVersion $true
        }
    }
	If ($MonitorCreated)
	{
		Write-Output "Monitor `"$MonitorName`" created."
	} else {
		Write-Error "Unable to create monitor `"$Monitorname`"."
	}

}