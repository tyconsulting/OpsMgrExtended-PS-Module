Workflow Create-OpsMgrMP
{
    Param(
    [Parameter(Mandatory=$true)][String]$Name,
    [Parameter(Mandatory=$true)][String]$DisplayName,
    [Parameter(Mandatory=$false)][String]$Description,
    [Parameter(Mandatory=$true)][String]$Version,
    [Parameter(Mandatory=$false)][String]$SharePointListItemID
    )
    
	#SharePoint list name
	$SharePointListName = "New SCOM MPs"

    #Get OpsMgr SDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_TYANG"

	#Get SharePointSDK connection object (Defined in the SharePointSDK SMA module http://blog.tyang.org/2014/12/23/sma-integration-module-sharepoint-list-operations/)
	$SPConn = Get-AutomationConnection "RequestsSPSite"

    #Create MP
    $MPCreated = InlineScript
    {
        #Validate MP Name
        If ($USING:Name -notmatch "([a-zA-Z0-9]+\.)+[a-zA-Z0-9]+")
        {
            #Invalid MP name entered
            $ErrMsg = "Invalid Management Pack name specified. Please make sure it only contains alphanumeric charaters and only use '.' to separate words. i.e. Your.Company.Test1.MP."
            Write-Error $ErrMsg 
        } else {
            #Name is valid, creating the MP
            New-OMManagementPack -SDKConnection $USING:OpsMgrSDKConn -Name $USING:Name -DisplayName $USING:DisplayName -Description $USING:Description -Version $USING:Version
        }
        Return $MPCreated
    }

    If ($MPCreated)
	{
		Write-Output "Management Pack `"$Name`" created."
	} else {
		Write-Error "Unable to create Management Pack `"$Name`"."
	}

    #Update SharePoint List Item using the SharePointSDK SMA module (http://blog.tyang.org/2014/12/23/sma-integration-module-sharepoint-list-operations/)
    If ($SharePointListItemID)
    {
        Write-Output "Updating SharePoint List Item"
		$ListFields = InlineScript
		{
			Import-Module SharePointSDK -Verbose:$false
			$ListFields = Get-SPListFields -SPConnection $USING:SPConn -ListName $USING:SharePointListName
			,$ListFields
		}
		$ReturnMessageField = ($ListFields | Where-Object {$_.Title -ieq 'Return message' -and $_.ReadOnlyField -eq $false}).InternalName
		$UpdatedFields = @{
			$ReturnMessageField = "MP created."
		}
		$UpdateListItem = InlineScript
		{
			Import-Module SharePointSDK -Verbose:$false
			Update-SPListItem -ListFieldsValues $USING:UpdatedFields -ListItemID $USING:SharePointListItemID -ListName $USING:SharePointListName -SPConnection $USING:SPConn
		}
    }
	Write-Output "Done."
}