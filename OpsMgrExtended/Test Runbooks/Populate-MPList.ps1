Workflow Populate-MPList
{
 Param(
    [Parameter(Mandatory=$true)][String]$OpsMgrConnName,
    [Parameter(Mandatory=$true)][String]$SharePointConnName,
    [Parameter(Mandatory=$true)][String]$SharePointListName
    )

	#Get OpsMgrSDK connection object
	Write-Verbose "Getting Operations Manager SDK connection"
    $OpsMgrSDKConn = Get-AutomationConnection -Name $OpsMgrConnName
    Write-Verbose "OpsMgr Server Name: $($OpsMgrSDKConn.ComputerName)"
    
	#Get SharePointSDK connection object (Defined in the SharePointSDK SMA module: http://blog.tyang.org/2014/12/23/sma-integration-module-sharepoint-list-operations/)
	Write-Verbose "Getting SharePoint SDK connection"
	$SPConn = Get-AutomationConnection $SharePointConnName
    Write-Verbose "SharePoint site URL: $($SPConn.SharePointSiteURL)"
	#Get SharePoint List fields
	Write-Verbose "Getting field names from the SharePoint list `"$SharePointListName`"."
	$ListFields = InlineScript
	{
		Import-Module SharePointSDK -Verbose:$false
		$ListFields = Get-SPListFields -SPConnection $USING:SPConn -ListName $USING:SharePointListName
		,$ListFields
	}
	$NameField = ($ListFields | Where-Object {$_.Title -ieq 'MP Name' -and $_.ReadOnlyField -eq $false}).InternalName
	$DisplayNameField = ($ListFields | Where-Object {$_.Title -ieq 'Display Name' -and $_.ReadOnlyField -eq $false}).InternalName
	$MPVersionField = ($ListFields | Where-Object {$_.Title -ieq 'MP Version' -and $_.ReadOnlyField -eq $false}).InternalName
	$MPTimeCreatedField = ($ListFields | Where-Object {$_.Title -ieq 'MP Time Created' -and $_.ReadOnlyField -eq $false}).InternalName
	$MPLastModifiedField = ($ListFields | Where-Object {$_.Title -ieq 'MP Last Modified' -and $_.ReadOnlyField -eq $false}).InternalName
	$SealedField = ($ListFields | Where-Object {$_.Title -ieq 'Sealed' -and $_.ReadOnlyField -eq $false}).InternalName
	$MPIDField = ($ListFields | Where-Object {$_.Title -ieq 'MP ID' -and $_.ReadOnlyField -eq $false}).InternalName
	$KeyTokenField = ($ListFields | Where-Object {$_.Title -ieq 'Key Token' -and $_.ReadOnlyField -eq $false}).InternalName
	$DefaultLanguageField = ($ListFields | Where-Object {$_.Title -ieq 'Default Language' -and $_.ReadOnlyField -eq $false}).InternalName
	
	#Get existing list items
	Write-Verbose "Getting Existing list items."
	$ExistingListItems = InlineScript
	{
		Import-Module SharePointSDk
		$ListItems = Get-SPListItem -SPConnection $USING:SPConn -ListName $USING:SharePointListName
		,$ListItems
	}
	#Populate MP List
	Write-Verbose "Retriving Management Pack information and populating the SharePoint list."
	$PopulateSPList = InlineScript
	{
		Import-Module SharePointSDK -Verbose:$false
		$MPs = Get-OMManagementPack -SDKConnection $USING:OpsMgrSDKConn
		Foreach ($MP in $MPs)
		{
			Write-Verbose "Populating a hash table that contains details of the Management Pack `"$($MP.name)`"."
			$MPDetails = @{
				$USING:NameField = $MP.Name
				$USING:DisplayNameField = $MP.DisplayName
				$USING:MPVersionField = $MP.Version
				$USING:MPTimeCreatedField = $MP.TimeCreated
				$USING:MPLastModifiedField = $MP.LastModified
				$USING:SealedField = $MP.Sealed
				$USING:MPIDField = $MP.Id
				$USING:KeyTokenField = $MP.KeyToken
				$USING:DefaultLanguageField = $MP.DefaultLanguageCode
			}
			#Check if the MP is already saved on the list
			$ExistingListItem = $USING:ExistingListItems | Where-Object {$_.$($USING:NameField) -ieq $MP.Name}
			If ($ExistingListItem)
			{
				#MP already on the list, comparing MP with the list item
				Write-Verbose "MP `"$($MP.Name)`" already exists on the SharePoint list. Now checking if the MP has been updated since last sync."
				$ListItemDetails = @{
					$USING:NameField = $ExistingListItem.($USING:NameField)
					$USING:DisplayNameField = $ExistingListItem.($USING:DisplayNameField)
					$USING:MPVersionField = $ExistingListItem.($USING:MPVersionField)
					$USING:MPTimeCreatedField = $ExistingListItem.($USING:MPTimeCreatedField)
					$USING:MPLastModifiedField = $ExistingListItem.($USING:MPLastModifiedField)
					$USING:SealedField = $ExistingListItem.($USING:SealedField)
					$USING:MPIDField = $ExistingListItem.($USING:MPIDField)
					$USING:KeyTokenField = $ExistingListItem.($USING:KeyTokenField)
					$USING:DefaultLanguageField = $ExistingListItem.($USING:DefaultLanguageField)
				}
				#Comparing the list item with the MP, see if the MP has been updated
				$MPChanged = Compare-object -ReferenceObject $ListItemDetails -DifferenceObject $MPDetails
				if ($MPChanged -eq $true)
				{
					Write-Verbose "MP `"$($MP.Name)`" already exists on the list, but it has been updated. Updating the existing list item."
					$UpdateListItem = Update-SPListItem -ListFieldsValues $MPDetails -ListItemID $ExistingListItem.ID -ListName $USING:SharePointListName -SPConnection $USING:SPConn
				}
			} else {
				Write-Verbose "Adding MP `"$($MP.Name)`" to the SharePoint list."
				$NewListItem = Add-SPListItem -ListFieldsValues $MPDetails -ListName $USING:SharePointListName -SPConnection $USING:SPConn
			}
		}
	}
	Write-Verbose "Done."
}