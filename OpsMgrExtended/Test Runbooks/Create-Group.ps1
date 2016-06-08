Workflow Create-Group
{
    Param(
    [Parameter(Mandatory=$true)][String]$GroupName,
    [Parameter(Mandatory=$true)][String]$GroupDisplayName,
	[Parameter(Mandatory=$false)][ValidateSet('InstanceGroup', 'Computergroup')][String]$GroupType,
    [Parameter(Mandatory=$false)][String]$MPName,
    [Parameter(Mandatory=$false)][Int]$SharePointListItemID
    )
    
    #Get OpsMgrSDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_TYANG"


    #Validate MP
    $ValidMP = InlineScript
    {
        $MP = Get-OMManagementPack -SDKConnection $USING:OpsMgrSDKConn -Name $USING:MPName
		if ($MP.sealed)
		{
			$bValidMP = $false
			Write-Error "Unable to create the group in a sealed management pack."
		} else {
			$bValidMP = $true
		}
		$bValidMP
    }

    If ($ValidMP)
	{
		$newGroup = InlineScript
		{
			if ($USING:GroupType -ieq "InstanceGroup")
			{
				New-OMInstanceGroup -SDKConnection $USING:OpsMgrSDKConn -MPName $USING:MPName -InstanceGroupName $USING:GroupName -InstanceGroupDisplayName $USING:GroupDisplayName -IncreaseMPVersion $true
			} elseif ($USING:GroupType -ieq "ComputerGroup") {
				New-OMComputerGroup -SDKConnection $USING:OpsMgrSDKConn -MPName $USING:MPName -ComputerGroupName $USING:GroupName -ComputerGroupDisplayName $USING:GroupDisplayName -IncreaseMPVersion $true
			}
		}
	}

    If ($newGroup)
	{
		Write-Output "Group `"$GroupName`" created."
	} else {
		Write-Error "Unable to create group `"$GroupName`"."
	}

    #Update SharePoint List Item using the Update-SharePointListItem runbook (http://blog.tyang.org/2014/08/30/sma-runbook-update-sharepoint-2013-list-item/)
    If ($SharePointListItemID)
    {
        Write-Output "Updating SharePoint List Item"
        Update-SharePointListItem -SharepointSiteURL "http://sharepoint01/sites/requests" -SavedCredentialName "SharePointCred" -ListName "New SCOM MPs" -ListItemID $SharePointListItemID -PropertyName "Return message" -PropertyValue "Done"
    }
}