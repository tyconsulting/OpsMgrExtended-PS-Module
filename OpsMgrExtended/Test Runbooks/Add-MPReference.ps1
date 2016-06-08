Workflow Add-MPReference
{
	Param(
    [Parameter(Mandatory=$true)][String]$ManagementPackName,
    [Parameter(Mandatory=$true)][String]$ReferenceMPAlias,
	[Parameter(Mandatory=$true)][String]$ReferenceMPName
	)

	#Get OpsMgrSDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_TYANG"
	
    #Add MP reference in InlineScript
    $AddMPRef = InlineScript {
		#Add the MP reference
		$AddResult = New-OMManagementPackReference -SDKConnection $USING:OpsMgrSDKConn -ReferenceMPName $USING:ReferenceMPName -Alias $USING:ReferenceMPAlias -UnsealedMPName $USING:ManagementPackName
		Write-Verbose "Add Result: $AddResult"
        $AddResult
    }
    $AddMPRef
}

$ManagementPackName = "Test.Computer.Groups"
$ReferenceMPAlias = "Log"
$ReferenceMPName = "OpsMgr.Health.Sync.Library"
$AddMPRef = Add-MPReference -ManagementPackName $ManagementPackName -ReferenceMPAlias $ReferenceMPAlias -ReferenceMPName $ReferenceMPName -Verbose
$AddMPRef