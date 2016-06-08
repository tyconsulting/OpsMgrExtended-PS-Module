Workflow New-ComputerGroup
{
    Param(
    [Parameter(Mandatory=$true)][String]$GroupName,
    [Parameter(Mandatory=$true)][String]$GroupDisplayName,
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

			New-OMComputerGroup -SDKConnection $USING:OpsMgrSDKConn -MPName $USING:MPName -ComputerGroupName $USING:GroupName -ComputerGroupDisplayName $USING:GroupDisplayName -IncreaseMPVersion $true
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

Workflow Add-ComputerToComputerGroup
{
	Param(
    [Parameter(Mandatory=$true)][String]$GroupName,
    [Parameter(Mandatory=$true)][String]$ComputerPrincipalName
    )

	#Get OpsMgrSDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_TYANG"
	$bComputerAdded = Inlinescript {
		#Connecting to the management group
		$MG = Connect-OMManagementGroup -SDKConnection $USING:OpsMgrSDKConn
        
		#Get the windows computer object
		Write-Verbose "Getting the Windows computer monitoring object for '$USING:ComputerPrincipalName'"
		$WinComputerObjectCriteria = New-Object Microsoft.EnterpriseManagement.Monitoring.MonitoringObjectGenericCriteria("FullName = 'Microsoft.Windows.Computer:$USING:ComputerPrincipalName'")
		$WinComputer = $MG.GetMonitoringObjects($WinComputerObjectCriteria)[0]
		If ($WinComputer -eq $null)
		{
			Write-Error "Unable to find the Microsoft.Windows.Computer object for '$USING:ComputerPrincipalName'."
			Return $false
		}
		$WinComputerID = $WinComputer.Id.ToString()
		Write-Verbose "Monitoring Object ID for '$USING:ComputerPrincipalName': '$WinComputerID'"

		#Get the group
		Write-Verbose "Getting the computer group '$USING:GroupName'."
		$ComputerGroupClassCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria("Name='$USING:GroupName'")
		$ComputerGroupClass = $MG.GetMonitoringClasses($ComputerGroupClassCriteria)[0]
		If ($ComputerGroupClass -eq $null)
		{
			Write-Error "$Using:GroupName is not found."
			Return $false
		}
		#Check if this monitoring class is actually a computer group
		Write-Verbose "Check if the group '$USING:GroupName' is a computer group"
		$ComputerGroupBaseTypes = $ComputerGroupClass.GetBaseTypes()
		$bIsComputerGroup = $false
		Foreach ($item in $ComputerGroupBaseTypes)
		{
			If ($item.Id.Tostring() -eq '0c363342-717b-5471-3aa5-9de3df073f2a')
			{
				$bIsComputerGroup = $true
			}
		}
		If ($bIsComputerGroup -eq $false)
		{
			Write-Error "$Using:GroupName is not a computer group"
			Return $false
		}

		#Get Group object
		$ComputerGroupObject = $MG.GetMonitoringObjects($ComputerGroupClass)[0]

		#Get Group population discovrey
		Write-Verbose "Getting the group discovery rule"
		$ComputerGroupDiscoveries = $ComputerGroupObject.GetMonitoringDiscoveries()
		$iGroupPopDiscoveryCount = 0
		$GroupPopDiscovery = $null
		Foreach ($Discovery in $ComputerGroupDiscoveries)
		{
			$DiscoveryDS = $Discovery.DataSource
			#Microsft.SystemCenter.GroupPopulator ID is 488000ef-e20b-1ac4-d3b1-9d679435e1d7
			If ($DiscoveryDS.TypeID.Id.ToString() -eq '488000ef-e20b-1ac4-d3b1-9d679435e1d7')
			{
				#This data source module is using Microsft.SystemCenter.GroupPopulator
				$iGroupPopDiscoveryCount = $iGroupPopDiscoveryCount + 1
				$GroupPopDiscovery = $Discovery
				Write-Verbose "Group Populator discovery found: '$($GroupPopDiscovery.Name)'"
			}
		}
		If ($iGroupPopDiscoveryCount.count -eq 0)
		{
			Write-Error "No group populator discovery found for $Group."
			Return $false
		}

		If ($iGroupPopDiscoveryCount.count -gt 1)
		{
			Write-Error "$Group has multiple discoveries using Microsft.SystemCenter.GroupPopulator Module type."
			Return $false
		}
		#Get the MP of where the group populator discovery is defined
		$GroupPopDiscoveryMP = $GroupPopDiscovery.GetManagementPack()
		Write-Verbose "The group populator discovery '$($GroupPopDiscovery.Name)' is defined in management pack '$($GroupPopDiscoveryMP.Name)'."

		#Write Error and exit if the MP is sealed
		If ($GroupPopDiscoveryMP.sealed -eq $true)
		{
			Write-Error "Unable to update the group discovery because it is defined in a sealed MP: '$($GroupPopDiscoveryMP.DisplayName)'."
			Return $false
		}
		Write-Verbose "Updating the discovery data source configuration"
		$GroupDSConfig = $GroupPopDiscovery.Datasource.Configuration
		$GroupDSConfigXML = [XML]"<Configuration>$GroupDSConfig</Configuration>"

		#Detect if any MembershipRule segment contains existing static members
		$bComputerAdded = $false
		Foreach ($MembershipRule in $GroupDSConfigXML.Configuration.MembershipRules.MembershipRule)
		{
			If ($MembershipRule.IncludeList -ne $Null -and $bComputerAdded -eq $false)
			{
				#Add the monitoroing object ID of the Windows computer to the <IncludeList> node
				Write-Verbose "Adding '$USING:ComputerPrincipalName' monitoring Object ID '$WinComputerID' to the <IncludeList> node in the group populator configuration"
				$NewMOId = $MembershipRule.IncludeList.AppendChild($GroupDSConfigXML.CreateElement("MonitoringObjectId"))
				$NewMOId.InnerText = $WinComputerID
				$bComputerAdded = $true
			}
		}
		#If none of the MembershipRule has <IncludeList segment>, create it in the first MembershipRule
		If ($bComputerAdded -eq $false)
		{
			If ($GroupDSConfigXML.Configuration.MembershipRules.MembershipRule -Is [System.Array])
            {
                Write-Verbose "Multiple Membership rules. creating <IncludeList> within the first <MembershipRule>"
                $IncludeListNode = $GroupDSConfigXML.Configuration.MembershipRules.MembershipRule[0].AppendChild($GroupDSConfigXML.CreateElement("IncludeList"))
            } else {
                Write-Verbose "There is only one Membership rule. creating <IncludeList> in it."
                $IncludeListNode = $GroupDSConfigXML.Configuration.MembershipRules.MembershipRule.AppendChild($GroupDSConfigXML.CreateElement("IncludeList"))
            }
			$NewMOId = $IncludeListNode.AppendChild($GroupDSConfigXML.CreateElement("MonitoringObjectId"))
			$NewMOId.InnerText = $WinComputerID
		}
		$UpdatedGroupPopConfig = $GroupDSConfigXML.Configuration.InnerXML
		#Updating the discovery
		Write-Verbose "Updating the group discovery"
		Try {
			$GroupPopDiscovery.Datasource.Configuration = $UpdatedGroupPopConfig
			$GroupPopDiscovery.Status = [Microsoft.EnterpriseManagement.Configuration.ManagementPackElementStatus]::PendingUpdate
			$GroupPopDiscoveryMP.AcceptChanges()
			$bComputerAdded = $true
		} Catch {
			$bComputerAdded = $false
		}
		$bComputerAdded
	}
	If ($bComputerAdded -eq $true)
	{
		Write-Output "Done."
	} else {
		throw "Unable to add '$ComputerPrincipalName' to group '$GroupName'."
		exit
	}
}

$GroupName = "Group.Creation.Demo.Demo.Computer.Group"
$ComputerPrincipalName = "MGMT01.corp.tyang.org"
Add-ComputerToComputerGroup -GroupName $GroupName -ComputerPrincipalName $ComputerPrincipalName -Verbose