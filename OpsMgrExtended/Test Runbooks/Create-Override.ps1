Workflow Create-Override
{
    Param(
    [Parameter(Mandatory=$true)][String]$GroupName,
	[Parameter(Mandatory=$false)][String]$MPName,
    [Parameter(Mandatory=$true)][String]$OverrideWorkflow,
	[Parameter(Mandatory=$true)][ValidateSet('Monitor', 'Rule', 'Discovery', 'Diagnostic', 'Recovery')][System.String]$WorkflowType,
    [Parameter(Mandatory=$true)][Alias('target')][System.String]$OverrideTarget,
	[Parameter(Mandatory=$false)][Alias('Instance')][System.String]$ContextInstance = $NULL,
    [Parameter(Mandatory=$true)][System.String]$OverrideParameter,
    [Parameter(Mandatory=$true)]$OverrideValue,
	[Parameter(Mandatory=$false)][System.Boolean]$Enforced=$false,
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
			Write-Error "Unable to create the override in a sealed management pack."
		} else {
			$bValidMP = $true
		}
		$bValidMP
    }

    If ($ValidMP)
	{
		$newOverride = InlineScript
		{
			if ($USING:ContextInstance)
			{
				New-OMOverride -SDKConnection $USING:OpsMgrSDKConn -MPName $USING:MPName -OverrideWorkflow $USING:OverrideWorkflow -WorkflowType $USING:WorkflowType -OverrideTarget $USING:OverrideTarget -ContextInstance $USING:ContextInstance -OverrideParameter $USING:OverrideParameter -OverrideValue $USING:OverrideValue -Enforced $USING:Enforced -IncreaseMPVersion $true
			}else {
				New-OMOverride -SDKConnection $USING:OpsMgrSDKConn -MPName $USING:MPName -OverrideWorkflow $USING:OverrideWorkflow -WorkflowType $USING:WorkflowType -OverrideTarget $USING:OverrideTarget -OverrideParameter $USING:OverrideParameter -OverrideValue $USING:OverrideValue -Enforced $USING:Enforced -IncreaseMPVersion $true
			}
		}
	}

    If ($newOverride)
	{
		Write-Output "Override created."
	} else {
		Write-Error "Unable to create override."
	}

    #Update SharePoint List Item using the Update-SharePointListItem runbook (http://blog.tyang.org/2014/08/30/sma-runbook-update-sharepoint-2013-list-item/)
    If ($SharePointListItemID)
    {
        Write-Output "Updating SharePoint List Item"
        Update-SharePointListItem -SharepointSiteURL "http://sharepoint01/sites/requests" -SavedCredentialName "SharePointCred" -ListName "New SCOM MPs" -ListItemID $SharePointListItemID -PropertyName "Return message" -PropertyValue "Done"
    }
}