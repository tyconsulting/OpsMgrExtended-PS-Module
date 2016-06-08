Workflow Create-TCPPortMonitoring
{
    PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter management pack name')][String]$MPName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the monitoring name')][String]$Name,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the monitoring title')][Alias('DisplayName')][String]$Title,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the target device name')][Alias('t')][String]$Target,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the port number')][Int]$Port,
        [Parameter(Mandatory=$true,HelpMessage='Please specify the watcher nodes (separated by ;)')][String]$WatcherNodes,
        [Parameter(Mandatory=$true,HelpMessage='Please specify the interval seconds for the monitoring workflows')][Int]$IntervalSeconds,
		[Parameter(Mandatory=$false)][String]$SharePointListItemID
    )
	$SDKConnection = Get-AutomationConnection -Name "OpsMgrSDK_TYANG"
	Write-Verbose "Checking for existing management pack with name `"$MPName`"."
	$NewMP = InlineScript
	{
		$ExistingMP = Get-OMManagementPack -SDKConnection $USING:SDKConnection -Name $USING:MPName
		if ($ExistingMP)
		{
			Write-Verbose "Management Pack `"$USING:MPName`" already exists."
			$NewMP = $false
		} else {
			Write-Verbose "Management Pack `"$USING:MPName`" does not exists. Creating the MP first."
			$MPDisplayName = $($USING:MPName).Replace(".", " ")
			$NewMP = New-OMManagementPack -SDKConnection $USING:SDKConnection -Name $USING:MPName -DisplayName $MPDisplayName -Version 1.0.0.0
		}
		$NewMP
	}
	If ($NewMP)
	{
		Write-Verbose "MP `"$MPName`" didn't exist and it is newly created. Since it is a new MP, the MP version will not be increased."
		$IncreaseMPVersion = $false
	} else {
		$IncreaseMPVersion = $true
	}
	Write-Verbose "Creating TCP Port Monitoring now."
	$CreateTCPPortMonitoring = InlineScript
	{
		New-OMTCPPortMonitoring -SDKConnection $USING:SDKConnection -MPName $USING:MPName -Name $USING:Name -Title $USING:Title -Target $USING:Target -Port $USING:Port -WatcherNodes $USING:WatcherNodes -IntervalSeconds $USING:IntervalSeconds -IncreaseMPVersion $USING:IncreaseMPVersion
	}
	Write-Verbose "TCP Port Monitoring solution created: $CreateTCPPortMonitoring"

	If ($CreateTCPPortMonitoring)
	{
		$ReturnMessage = "TCP Port Monitoring `"$Title`" successfully created in Management Pack `"$MPName`"."
		Write-Output $ReturnMessage
	} else {
		$ReturnMessage = "Failed to create TCP Port Monitoring `"$Title`" in Management Pack `"$MPName`"."
		Write-Error $ReturnMessage
	}
	

	#Update SharePoint List Item if this runbook is initiated from SharePoint using the 'Update-SharePointListItem' runbook published at: http://blog.tyang.org/2014/08/30/sma-runbook-update-sharepoint-2013-list-item/.
    If ($SharePointListItemID)
    {
        Write-Output "Updating SharePoint List Item"
        Update-SharePointListItem -SharepointSiteURL "http://sharepoint01/sites/requests" -SavedCredentialName "SharePointCred" -ListName "New TCP Port Monitoring" -ListItemID $SharePointListItemID -PropertyName "Return message" -PropertyValue $ReturnMessage
    }
}