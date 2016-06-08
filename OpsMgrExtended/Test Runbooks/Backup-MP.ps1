Workflow Backup-MP
{
	Param(
		[Parameter(Mandatory=$true)][String]$BackupLocation,
		[Parameter(Mandatory=$false)][Boolean]$BackupSealedMP = $false,
		[Parameter(Mandatory=$true)][String]$RetentionDays
	)
    
    #Get OpsMgrSDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_TYANG"


    #Create MP
    $BackupMP = InlineScript
    {
		Backup-OMManagementPacks -SDKConnection $USING:OpsMgrSDKConn -BackupLocation $USING:BackupLocation -BackupSealedMP $USING:BackupSealedMP -RetentionDays $USING:RetentionDays
    }

    If ($BackupMP)
	{
		Write-Output "MP Backup completed successfully."
	} else {
		Write-Error "MP Backup job did not complete successfully."
	}

    #Update SharePoint List Item using the 'Update-SharePointListItem' runbook published at: http://blog.tyang.org/2014/08/30/sma-runbook-update-sharepoint-2013-list-item/
    If ($SharePointListItemID)
    {
        Write-Output "Updating SharePoint List Item"
        Update-SharePointListItem -SharepointSiteURL "http://sharepoint01/sites/requests" -SavedCredentialName "SharePointCred" -ListName "New SCOM MPs" -ListItemID $SharePointListItemID -PropertyName "Return message" -PropertyValue "Done"
    }
}