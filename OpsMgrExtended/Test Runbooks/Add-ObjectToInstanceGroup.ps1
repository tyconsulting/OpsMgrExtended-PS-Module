Workflow Add-ObjectToInstanceGroup
{
	Param(
    [Parameter(Mandatory=$true)][String]$GroupName,
    [Parameter(Mandatory=$true)][String]$MonitoringObjectID,
	[Parameter(Mandatory=$true)][Boolean]$IncreaseMPVersion
    )

	#Get OpsMgrSDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_TYANG"
	$bInstanceAdded = New-OMInstanceGroupExplicitMember -SDKConnection $OpsMgrSDKConn -MonitoringObjectID $MonitoringObjectID -GroupName $GroupName -IncreaseMPVersion $IncreaseMPVersion
	If ($bInstanceAdded -eq $true)
	{
		Write-Output "Done."
	} else {
		throw "Unable to add monitoring object '$MonitoringObjectID' to group '$GroupName'."
		exit
	}
}