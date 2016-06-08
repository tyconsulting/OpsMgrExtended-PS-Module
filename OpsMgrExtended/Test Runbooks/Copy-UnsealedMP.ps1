Workflow Copy-UnsealedMP
{
	Param(
		[Parameter(Mandatory=$true)][String]$MPName,
		[Parameter(Mandatory=$true)][String]$DestinationDisplayName,
		[Parameter(Mandatory=$true)][String]$SPListItemID
    )

	Write-Verbose "Getting OpsMgrSDK connections."
	$SourceSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_TYANG"
	$DestSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_Azure"

	Write-Verbose "Getting SharePoint SDK connection"
	#This connection is defined in the SharePointSDK SMA module (http://blog.tyang.org/2014/12/23/sma-integration-module-sharepoint-list-operations/)
	$SPConn = Get-AutomationConnection "RequestsSPSite"
	$SharePointListName = "OnPrem MP List"

	#Validate the MP
	Write-Verbose "Validating MP `"$MPName`" in the source management group."
	$ValidMP = InlineScript
	{
		$MP = Get-OMManagementPack -SDKCOnnection $USING:SourceSDKConn -Name $USING:MPName
		if ($MP -ne $null)
		{
			#MP is found, now check if it's sealed
			If ($MP.Sealed -eq $false)
			{
				$true
			} else {
				Write-Error "Unable to copy the MP `"$MPName`" because it is sealed."
				$false
			}
		} else {
			#MP not found
			Write-Error "MP `"$MPName`" does not exist in the source management group."
			$false
		}
	}

	if ($ValidMP -eq $true)
	{
		Write-Verbose "MP `$MPName`" is valid. copying it to the destination management group now."
		$CopyResult = Copy-OMManagementPack -SourceSDKConnection $SourceSDKConn -DestinationSDKConnection $DestSDKConn -MPName $MPName -Overwrite $true
		if ($CopyResult -eq $true)
		{
			$ResultMessage = "Successfully copied to `"$DestinationDisplayName`" management group."
		} else {
			$ResultMessage = "Failed to copy to `"$DestinationDisplayName`" management group."
		}
	} else {
		$ResultMessage = "Unable to copy this management pack to `"$DestinationDisplayName`" management group."
	}

	#Update SharePoint List Item using the SharePointSDK SMA module published here: http://blog.tyang.org/2014/12/23/sma-integration-module-sharepoint-list-operations/
	#Get required SharePoint List fields
	Write-Verbose "Getting field names from the SharePoint list `"$SharePointListName`"."
	$ListFields = InlineScript
	{
		Import-Module SharePointSDK
		$ListFields = Get-SPListFields -SPConnection $USING:SPConn -ListName $USING:SharePointListName
		,$ListFields
	}
	$CopyToField = ($ListFields | Where-Object {$_.Title -ieq 'Copy To' -and $_.ReadOnlyField -eq $false}).InternalName
	$TaskOutcomeField = ($ListFields | Where-Object {$_.Title -ieq 'Task Outcome' -and $_.ReadOnlyField -eq $false}).InternalName

	$UpdateSPListItem = InlineScript
	{
		Import-Module SharePointSDK
		$ListItemDetails = @{
				$USING:CopyToField = ""
				$USING:TaskOutcomeField = $USING:ResultMessage
			}
		 $UpdateListItem = Update-SPListItem -ListFieldsValues $ListItemDetails -ListItemID $USING:SPListItemID -ListName $USING:SharePointListName -SPConnection $USING:SPConn 
	}
	Write-Output "Done."
}