Workflow Add-ObjectToInstanceGroup
{
	Param(
    [Parameter(Mandatory=$true)][String]$GroupName,
    [Parameter(Mandatory=$true)][String]$MonitoringObjectID
    )

	#Get OpsMgrSDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_TYANG"
	$bInstanceAdded = Inlinescript {
		#Connecting to the management group
		$MG = Connect-OMManagementGroup -SDKConnection $USING:OpsMgrSDKConn
        
		#Get the Monitoring Object
		Write-Verbose "Validating specified monitoring object ID '$USING:MonitoringObjectID'"
		$MonitoringObject = $MG.GetMonitoringObject($USING:MonitoringObjectID)
		If ($MonitoringObject -eq $null)
		{
			Write-Error "Unable to find the monitoring object with ID '$USING:MonitoringObjectID'."
			Return $false
		}
		$MonitoringObjectFullName = $MonitoringObject.FullName
		Write-Verbose "Montoring Object Full Name: '$MonitoringObjectFullName'."
		#Get the monitoring class and the MP of where it's defined
		$MonitoringClass = $MonitoringObject.GetLeastDerivedNonAbstractMonitoringClass()
		$MonitoringClassName = $MonitoringClass.Name
		$MonitoringClassMP = $MonitoringClass.GetManagementPack()
		$MonitoringClassMPName = $MonitoringClassMP.Name
		Write-Verbose "Monitoring Object ID '$USING:MonitoringObjectID' found. Monitoring Object Full Name: '$MonitoringObjectFullName'."

		#Get the group
		Write-Verbose "Getting the instance group '$USING:GroupName'."
		$InstanceGroupClassCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria("Name='$USING:GroupName'")
		$InstanceGroupClass = $MG.GetMonitoringClasses($InstanceGroupClassCriteria)[0]
		If ($InstanceGroupClass -eq $null)
		{
			Write-Error "$Using:GroupName is not found."
			Return $false
		}
		#Check if this monitoring class is actually an instance group
		Write-Verbose "Check if the group '$USING:GroupName' is an instance group"
		$InstanceGroupBaseTypes = $InstanceGroupClass.GetBaseTypes()
		$bIsInstanceGroup = $false
		Foreach ($item in $InstanceGroupBaseTypes)
		{
			If ($item.Id.Tostring() -eq '4ce499f1-0298-83fe-7740-7a0fbc8e2449')
			{
				$bIsInstanceGroup = $true
			}
		}
		If ($bIsInstanceGroup -eq $false)
		{
			Write-Error "$Using:GroupName is not an instance group"
			Return $false
		}

		#Get Group object
		$InstanceGroupObject = $MG.GetMonitoringObjects($InstanceGroupClass)[0]

		#Check if the monitoring object is already member of the group
		Write-Verbose "Checking if the monitoring object '$USING:MonitoringObjectID' is already a member of the group."
		$MonitoringObjectCriteria = New-Object Microsoft.EnterpriseManagement.Monitoring.MonitoringObjectCriteria("Id='$USING:MonitoringObjectID'",$MonitoringClass)
		$ExistingMembers = $InstanceGroupObject.GetRelatedMonitoringObjects($MonitoringObjectCriteria, [Microsoft.EnterpriseManagement.Common.TraversalDepth]::OneLevel)
		if ($ExistingMembers.count -gt 0)
		{
			Write-Warning "The Monitoring Object '$MonitoringObjectFullName' (ID:'$USING:MonitoringObjectID') is already a member of the instance group $USING:GroupName. No need to add it again. Aborting."
			Return $true
		}
		#Get Group population discovrey
		Write-Verbose "Getting the group discovery rule"
		$InstanceGroupDiscoveries = $InstanceGroupObject.GetMonitoringDiscoveries()
		$iGroupPopDiscoveryCount = 0
		$GroupPopDiscovery = $null
		Foreach ($Discovery in $InstanceGroupDiscoveries)
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
		$GroupPopDiscoveryMPName = $GroupPopDiscoveryMP.Name
		Write-Verbose "The group populator discovery '$($GroupPopDiscovery.Name)' is defined in management pack '$GroupPopDiscoveryMPName'."

		#Write Error and exit if the group discovery MP is sealed
		Write-Verbose "Checking if '$GroupPopDiscoveryMPName' MP is sealed."
		If ($GroupPopDiscoveryMP.sealed -eq $true)
		{
			Write-Error "Unable to update the group discovery because it is defined in a sealed MP: '$($GroupPopDiscoveryMP.DisplayName)'."
			Return $false
		} else {
			Write-Verbose "'$GroupPopDiscoveryMPName' MP is unsealed. OK to continue."
		}

		#Get the MP Alias for 'Microsoft.SystemCenter.InstanceGroup.Library' from the Group Discovery MP
		Write-Verbose "Getting the MP reference alias for 'Microsoft.SystemCenter.InstanceGroup.Library' from the group discovery MP '$GroupPopDiscoveryMPName'."
		$InstanceGroupMPAlias = ($GroupPopDiscoveryMP.References | Where-Object {$_.Value -LIKE 'ManagementPack`:`[Name`=Microsoft.SystemCenter.InstanceGroup.Library`,*'}).key
		If ($InstancegroupMPAlias -eq $null)
		{
			Write-Error "The group discovery MP '$GroupPopDiscoveryMPName' is not referencing the 'Microsoft.SystemCenter.InstanceGroup.Library' MP. Unable to continue."
			#Exit. We are not going to create the reference now because the instance group library MP should have already been referenced.
			Return $false
		} else {
			Write-Verbose "The MP Reference Alias for 'Microsoft.SystemCenter.InstanceGroup.Library' is '$InstanceGroupMPAlias'."
		}
		#Check if monitoring class is defined in an unsealed MP and the group discovery is defined in another MP.
		If ($MonitoringClassMP.Sealed -eq $false -and $MonitoringClassMPName -ne $GroupPopDiscoveryMPName)
		{
			Write-Error "The Monitoring Class '$MonitoringClassName' is defined in an unsealed MP '$MonitoringClassMPName', but the group discovery is defined in another MP. Unable to add the monitoirng object to the group because the unsealed MP cannot be referenced in other MPs."
			Return $false
		}
		If ($MonitoringClassMPName -ne $GroupPopDiscoveryMPName)
		{
			#Monitoring Class and group discovery are defined in different MPs. Make sure the Monitoring Class MP is referenced in the group discovery MP
			Write-Verbose "The Monitoring Class '$MonitoringClassName' and the group discovery are defined in different MPs."
			$MonitoringClassMPAlias = ($GroupPopDiscoveryMP.References | Where-Object {$_.Value -LIKE "*$MonitoringClassMPName,*"}).key
			If (!$MonitoringClassMPAlias)
			{
				Write-Verbose "The Group Discovery MP '$GroupPopDiscoveryMPName' is not referencing the monitoring class MP '$MonitoringClassMPName'. Creating the reference now."
				Foreach ($item in $MonitoringClassMPName.split(".")){$MonitoringClassMPAlias = $MonitoringClassMPAlias + $item.Substring(0,1)}
				#Make sure the MP alias is valid
				$bValidAliasName = $true
				Foreach ($item in $GroupPopDiscoveryMP.Reference)
				{
					if ($item.key -ieq $MonitoringClassMPAlias)
					{
						$bValidAliasName = $false
					}
				}
				#Regenerate MP Alias name if it's not valid (already been taken)
				If ($bValidAliasName -eq $false)
				{
					Do
					{
						#Append a number at the end of alias name
						$i = 1
						$NewMonitoringClassMPAlias = $MonitoringClassMPAlias+$($i.ToString())
						if (($GroupPopDiscoveryMP.References | Where-Object {$_.Value -LIKE "*$MonitoringClassMPName,*"}) -eq $null)
						{
							$MonitoringClassMPAlias = $NewMonitoringClassMPAlias
							$bValidAliasName = $true
						} else {
							$i = $i + 1
						}
					} Until ($bValidAliasName -eq $true)
				}
				$AddAlias = New-OMManagementPackReference -SDKConnection $USING:OpsMgrSDKConn -ReferenceMPName $MonitoringClassMPName -Alias $MonitoringClassMPAlias -UnsealedMPName $GroupPopDiscoveryMPName 
				$bNewReference = $true
			} else {
				#The reference to the monitoring class MP already existed.
				$bNewReference = $false
			}
			Write-Verbose "The '$MonitoringClassMPName' reference alias in '$GroupPopDiscoveryMPName' is '$MonitoringClassMPAlias'."
			#determine the <Monitoringclass> element in the Membership Rule
			$MemberShipRuleMonitoroingClass = "`$MPElement[Name=`"$MonitoringClassMPAlias!$MonitoringClassName`"]`$"
		} else {
			#reference not required becaues the monitoring class and the group discovery is in the same MP
			Write-Verbose "The monitoring class '$MonitoringClassName' and the group discovery is defined in the same MP. No need to create MP reference alias for monitoring class MP."
			$bNewReference = $null
			$MemberShipRuleMonitoroingClass = "`$MPElement[Name=`"$MonitoringClassName`"]`$"
		}
		Write-Verbose "The <MonitoringClass> value in <MembershipRule> is '$MemberShipRuleMonitoroingClass'."
		Write-Verbose "Updating the discovery data source configuration"
		$GroupDSConfig = $GroupPopDiscovery.Datasource.Configuration
		$GroupDSConfigXML = [XML]"<Configuration>$GroupDSConfig</Configuration>"
		$MembershipRuleRelationshipClass = "`$MPElement[Name=`"$InstanceGroupMPAlias!Microsoft.SystemCenter.InstanceGroupContainsEntities`"]`$"
		$bInstanceAdded = $false
		If ($bNewReference -ne $true)
		{
			#Either the monitoring class MP was already referenced in the group discovery MP, or the monitoring class and group discovery are defined in the same MP.
			#Detect if any MembershipRule segment is defined for the monitoring class
			Foreach ($MembershipRule in $GroupDSConfigXML.Configuration.MembershipRules.MembershipRule)
			{
				If ($MembershipRule.MonitoringClass -ieq $MemberShipRuleMonitoroingClass -and $MembershipRule.RelationshipClass -ieq $MembershipRuleRelationshipClass -and $bInstanceAdded -eq $false)
				{
					#Add the monitoroing object ID to the <IncludeList> node
					if ($MembershipRule.IncludeList -eq $Null)
					{
						#Create the <IncludeList> node
						$IncludeListNode = $MembershipRule.AppendChild($GroupDSConfigXML.CreateElement("IncludeList"))
					} else {
						$IncludeListNode = $MemberShipRule.IncludeList
					}
					$NewMOId = $MembershipRule.IncludeList.AppendChild($GroupDSConfigXML.CreateElement("MonitoringObjectId"))
					$NewMOId.InnerText = $USING:MonitoringObjectID
					$bInstanceAdded = $true
				}
			}
		}
		If ($bInstanceAdded -eq $false)
		{
			If ($bNewReference -eq $true)
			{
			#No need to check existing membership rules because the group discovery MP wasn't referencing the monitoring class MP, so no membership rules would have included any monitoring objects from the monitoring class
			Write-Verbose "Since the group discovery MP '$GroupPopDiscoveryMPName' wasn't referencing the monitoring class MP '$MonitoringClassMPName', no need to check existing membership rules. Creating a brand new <MembershipRule>."
			} Else {
				#The Monitoring Class MP was already referenced in the group discovery MP, but there are no <MembershipRule> defined for the monitoring class
				Write-Verbose "The Monitoring Class MP '$MonitoringClassMPName' was already referenced in the group discovery MP '$GroupPopDiscoveryMPName', but there are no <MembershipRule> defined for the monitoring class '$MonitoringClassName'. Creating a new <MembershipRule> element in the group discovery."
			}
			#New <MembershipRule>
			$XMLMemberShipRule = $GroupDSConfigXML.Configuration.MembershipRules.AppendChild($GroupDSConfigXML.CreateElement("MembershipRule"))
			#<MonitoringClass>
			$XMLMonitoringClass = $XMLMemberShipRule.AppendChild($GroupDSConfigXML.CreateElement("MonitoringClass"))
			$XMLMonitoringClass.InnerText = $MemberShipRuleMonitoroingClass
			#<RelationshipClass>
			$XMLRelationshipClass = $XMLMemberShipRule.AppendChild($GroupDSConfigXML.CreateElement("RelationshipClass"))
			$XMLRelationshipClass.InnerText = $MembershipRuleRelationshipClass
			#<IncludeList>
			$IncludeListNode = $XMLMemberShipRule.AppendChild($GroupDSConfigXML.CreateElement("IncludeList"))
			#<MonitoringObjectId>
			$NewMOId = $IncludeListNode.AppendChild($GroupDSConfigXML.CreateElement("MonitoringObjectId"))
			$NewMOId.InnerText = $USING:MonitoringObjectID
			$bInstanceAdded = $true
		}

		$UpdatedGroupPopConfig = $GroupDSConfigXML.Configuration.InnerXML
		#Updating the discovery
		Write-Verbose "Updating the group discovery"
		Try {
			$GroupPopDiscovery.Datasource.Configuration = $UpdatedGroupPopConfig
			$GroupPopDiscovery.Status = [Microsoft.EnterpriseManagement.Configuration.ManagementPackElementStatus]::PendingUpdate
			$GroupPopDiscoveryMP.AcceptChanges()
			$bInstanceAdded = $true
		} Catch {
			Write-Error $_.Exception.InnerException.Message
			$bInstanceAdded = $false
		}
		$bInstanceAdded
	}
	If ($bInstanceAdded -eq $true)
	{
		Write-Output "Done."
	} else {
		throw "Unable to add monitoring object '$MonitoringObjectID' to group '$GroupName'."
		exit
	}
}

$GroupName = "Group.Creation.Demo.Demo.Instance.Group"
$MonitoringObjectID1 = "fabfe649-921c-cf17-d198-0fba29cee9ff"
$MonitoringObjectID2 = "a1d0c6c6-fd70-0987-2fde-368aec7a4710"
Add-ObjectToInstanceGroup -GroupName $GroupName -MonitoringObjectID $MonitoringObjectID1 -Verbose
Add-ObjectToInstanceGroup -GroupName $GroupName -MonitoringObjectID $MonitoringObjectID -Verbose