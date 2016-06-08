Workflow New-WindowsServiceTemplateInstance
{
    Param(
    [Parameter(Mandatory=$true)][String]$InstanceDisplayName,
    [Parameter(Mandatory=$false)][String]$InstanceDescription,
    [Parameter(Mandatory=$true)][String]$TargetGroupName,
    [Parameter(Mandatory=$true)][String]$ServiceName,
    [Parameter(Mandatory=$false)][String]$LocaleId,
    [Parameter(Mandatory=$true)][Boolean]$CheckStartupType,
    [Parameter(Mandatory=$false)][Int]$CPUPercent,
    [Parameter(Mandatory=$false)][Int]$MemoryUsageMB,
	[Parameter(Mandatory=$false)][Int]$ConsecutiveSampleCount,
	[Parameter(Mandatory=$false)][Int]$PollIntervalInSeconds
    )
    
    #Get OpsMgrSDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_Home"

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
    #parameters

    #Create Service Monitor, MP Version will be increased by 0.0.0.1
    $result = InlineScript
    {
        $SDK = $USING:OpsMgrSDKConn.ComputerName
        Write-Verbose "OpsMgr management server name: $SDK"
        $UserName = $USING:OpsMgrSDKConn.Username
        $password = ConvertTo-SecureString -AsPlainText $USING:OpsMgrSDKConn.Password -force

        $parms = @{
            SDKConnection = $USING:OpsMgrSDKConn
            MPName = $USING:MPName
            DisplayName = $USING:InstanceDisplayName
            Description = $USING:InstanceDescription
            ServiceName = $USING:ServiceName
            TargetGroupName = $USING:TargetGroupName
            CheckStartupType = $USING:CheckStartupType
            IncreaseMPVersion = $true
        }
        if ($USING:LocaleId -ne $null)
        {
            $parms.Add('LocaleId', $USING:LocaleId)
        }
        if ($USING:CPUPercent -gt 0)
        {
            $parms.Add('PercentCPU', $USING:CPUPercent)
        }
        if ($USING:MemoryUsageMB -gt 0)
        {
            $parms.Add('MemoryUsage', $USING:MemoryUsageMB)
        }
        if ($USING:ConsecutiveSampleCount -gt 0)
        {
            $parms.Add('ConsecutiveSampleCount', $USING:ConsecutiveSampleCount)
        }
        if ($USING:PollIntervalInSeconds -gt 0)
        {
            $parms.Add('PollIntervalInSeconds', $USING:PollIntervalInSeconds)
        }
        
        #Return $parms
        Write-Verbose "Calling New-OMWindowsServiceTemplateInstance with the following parameters:"
        Write-Verbose ($parms | out-string)
        New-OMWindowsServiceTemplateInstance @parms
    }
    
	If ($result)
	{
		Write-Output "The Windows Service monitoring template instance `"$InstanceDisplayName`" is created."
	} else {
		Write-Error "Unable to create the Windows Service monitoring template instance `"$InstanceDisplayName`"."
	}

}