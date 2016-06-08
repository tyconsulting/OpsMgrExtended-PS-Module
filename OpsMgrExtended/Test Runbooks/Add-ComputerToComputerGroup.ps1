Workflow Add-ComputerToComputerGroup
{
	Param(
    [Parameter(Mandatory=$true)][String]$GroupName,
    [Parameter(Mandatory=$true)][String]$ComputerPrincipalName,
	[Parameter(Mandatory=$true)][Boolean]$IncreaseMPVersion
    )

	#Get OpsMgrSDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_TYANG"
	$bComputerAdded =New-OMComputerGroupExplicitMember -SDKConnection $OpsMgrSDKConn -GroupName $GroupName -ComputerPrincipalName $ComputerPrincipalName -IncreaseMPVersion $IncreaseMPVersion
	If ($bComputerAdded -eq $true)
	{
		Write-Output "Done."
	} else {
		throw "Unable to add '$ComputerPrincipalName' to group '$GroupName'."
		exit
	}
}