Workflow Configure-GroupHealthRollup
{
    PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter the group name')][Alias('g','group')][String]$GroupName,
        [Parameter(Mandatory=$true,HelpMessage='Please specify the algorithm to use for determining health state')][Alias('a')][ValidateSet('BestOf','WorstOf','Percentage')][String]$Algorithm,
        [Parameter(Mandatory=$false,HelpMessage='Please specify the percentage value (required when algorithm is Percentage).')][Alias('percent')][ValidateScript({if ($Algorithm -ieq 'percentage'){$_ -gt 0}})][Int]$Percentage=60,
        [Parameter(Mandatory=$false,HelpMessage='Please specify the health state when the member is unavailable.')][Alias('unavailable')][ValidateSet('Uninitialized','Success ','Warning','Error')][String]$MemberUnavailable = "Error",
        [Parameter(Mandatory=$false,HelpMessage='Please specify the health state when the member is in maintenance mode.')][Alias('maintenancemode')][ValidateSet('Uninitialized','Success ','Warning','Error')][String]$MemberInMaintenance,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the Management Pack name of which the monitors going to be saved. This is only going to be used when the group is defined in a sealed MP.')][Alias('mp','ManagementPack')][String]$ManagementPackName,
        [Parameter(Mandatory=$false,HelpMessage='Increase MP version by 0.0.0.1')][Boolean]$IncreaseMPVersion
    )

	#Get OpsMgrSDK connection object
    $OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_HOME"

	$bRollupConfigured = InlineScript {
		#Connect to MG
		$MG = Connect-OMManagementGroup -SDKConnection $USING:OpsMgrSDKConn

		#Get the group class
		Write-Verbose "Getting the group class '$USING:GroupName'."
		$GroupClassCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria("Name='$USING:GroupName'")
		$GroupClass = $MG.GetMonitoringClasses($GroupClassCriteria)[0]
		If ($GroupClass -eq $null)
		{
			Write-Error "$USING:GroupName is not found."
			Return $false
		}

		If ($GroupClass.DisplayName -ne $null)
		{
			$GroupDisplayName = $GroupClass.DisplayName
		} else {
			$GroupDisplayName = $USING:GroupName
		}
		Write-Verbose "Group Display Name: '$GroupDisplayName'"
		#Check if this monitoring class is actually an instance group, computer group or the base group system.group
		Write-Verbose "Check if the group '$USING:GroupName' is an instance group."
		$GroupBaseTypes = $GroupClass.GetBaseTypes()
		$bIsGroup = $false
		Foreach ($item in $GroupBaseTypes)
		{
			$GroupBaseTypeID = $item.Id.Tostring()
			Switch ($GroupBaseTypeID)
			{
				#Instance Group
				'4ce499f1-0298-83fe-7740-7a0fbc8e2449'
				{
					$bIsGroup = $true
					$GroupType = "InstanceGroup"
				}
				#Computer Group
				'0c363342-717b-5471-3aa5-9de3df073f2a'
				{
					Write-Warning "Computer groups already have dependency monitors created out of the box. These monitors may be redundent. Please check after the task is completed."
					$bIsGroup = $true
					$GroupType = "ComputerGroup"
				}
				#None of above, then check the base type System.Group
				'd0b32736-5344-2fcc-74b3-f72dc64ef572'
				{
					$bIsGroup = $true
					If ($GroupType -eq $null)
					{
						$GroupType = "SystemGroup"
					}
				}
			}
		If ($bIsGroup -eq $false)
		{
			Write-Error "$USING:GroupName is not a group."
			Return $false
		}

		Write-Verbose "Group Type: '$GroupType'"
    
		#Get the group MP
		$GroupMP = $GroupClass.GetManagementPack()
		$GroupMPName = $GroupMP.Name
		If ($GroupMP.Sealed -eq $true)
		{
			Write-verbose "The group '$USING:GroupName' is defined in a sealed MP. Getting the desintation MP '$USING:ManagementPackName'."
			if ($USING:ManagementPackName -eq $null)
			{
				Write-Error "Unable to continue because the `$ManagementPack parameter is not specified and the group is defined in a sealed management pack. Please specify an unsealed MP to store the dependency monitors."
				Return $false
			} else {
				#Get the destination MP
				$DestinationMPCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name='$USING:ManagementPackName'")
				$DestinationMP = $MG.GetManagementPacks($DestinationMPCriteria)[0]
            
				If ($DestinationMP -eq $null)
				{
					Write-Error "Unable to find the management pack '$USING:ManagementPackName' in the management group. Unable to continue."
					Return $false
				} else {
					If ($DestinationMP.Sealed -eq $true)
					{
						Write-Error "The specified management pack '$USING:ManagementPackName' is a sealed MP. Unable to save dependency monitors to a sealed MP. Please specify an unsealed MP."
						Return $false
					}
				}
			}
		} else {
			Write-Verbose "The group '$USING:GroupName' is defined in an unsealed MP '$GroupMPName'. the dependency monitors will be stored in the same MP."
			$DestinationMP = $GroupMP
		}

		#Destination MP Name
		$DestinationMPName = $DestinationMP.Name
		Write-Verbose "The dependency monitors will be created in management pack '$DestinationMPName'."

		#Create the dependecy monitors
		#Monitor names
		Write-Verbose "Determining depdency monitor names."
		$AvailabilityDependencyMonitorName = "$USING:GroupName`.Availability.Dependency.Monitor"
		$ConfigurationDependencyMonitorName = "$USING:GroupName`.Configuration.Dependency.Monitor"
		$PerformanceDependencyMonitorName = "$USING:GroupName`.Performance.Dependency.Monitor"
		$SecurityDependencyMonitorName = "$USING:GroupName`.Security.Dependency.Monitor"

		#Parent Monitors
		Write-Verbose "Getting parent monitors."
		$AvailabilityParentMonitorCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitorCriteria("Name ='System.Health.AvailabilityState'")
		$ConfigurationParentMonitorCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitorCriteria("Name ='System.Health.ConfigurationState'")
		$PerformanceParentMonitorCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitorCriteria("Name ='System.Health.PerformanceState'")
		$SecurityParentMonitorCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.MonitorCriteria("Name ='System.Health.SecurityState'")

		$AvailabilityParentMonitor = $MG.GetMonitors($AvailabilityParentMonitorCriteria)[0]
		$ConfigurationParentMonitor = $MG.GetMonitors($ConfigurationParentMonitorCriteria)[0]
		$PerformanceParentMonitor = $MG.GetMonitors($PerformanceParentMonitorCriteria)[0]
		$SecurityParentMonitor = $MG.GetMonitors($SecurityParentMonitorCriteria)[0]

		#Relationship Types
		Write-Verbose "Getting relationship type."
		If ($GroupType -ieq "instancegroup")
		{
			$RelationshipMPCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name='Microsoft.SystemCenter.InstanceGroup.Library'")
			$RelationshipMP = $MG.GetManagementPacks($RelationshipMPCriteria)[0]
			$RelationshipClass = $MG.GetMonitoringRelationshipClass("Microsoft.SystemCenter.InstanceGroupContainsEntities", $RelationshipMP)
		} elseif ($GroupType -ieq "computergroup") {
			$RelationshipMPCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name='Microsoft.SystemCenter.Library'")
			$RelationshipMP = $MG.GetManagementPacks($RelationshipMPCriteria)[0]
			$RelationshipClass = $MG.GetMonitoringRelationshipClass("Microsoft.SystemCenter.ComputerGroupContainsComputer", $RelationshipMP)
		} elseif ($GroupType -ieq "systemgroup") {
			$RelationshipMPCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name='System.Library'")
			$RelationshipMP = $MG.GetManagementPacks($RelationshipMPCriteria)[0]
			$RelationshipClass = $MG.GetMonitoringRelationshipClass("System.Containment", $RelationshipMP)
		}

		#Availability Dependecy Monitor
		Write-Verbose "Creating Availability Dependency monitor '$AvailabilityDependencyMonitorName'."
		$AvailabilityDependencyMonitor = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDependencyMonitor($DestinationMP,$AvailabilityDependencyMonitorName,[Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Public)
		$AvailabilityDependencyMonitor.DisplayName = "$GroupDisplayName Availability Dependency Monitor"
		$AvailabilityDependencyMonitor.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::AvailabilityHealth
		$AvailabilityDependencyMonitor.ParentMonitorID = $AvailabilityParentMonitor
		$AvailabilityDependencyMonitor.RelationshipType = $RelationshipClass
		$AvailabilityDependencyMonitor.Target = $GroupClass
		$AvailabilityDependencyMonitor.Enabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
		$AvailabilityDependencyMonitor.Remotable = $true
		$AvailabilityDependencyMonitor.Priority = [Microsoft.EnterpriseManagement.Configuration.ManagementPackWorkflowPriority]::Normal
		#Member monitor is same as parrent monitor
		$AvailabilityDependencyMonitor.MemberMonitor = $AvailabilityParentMonitor
		$AvailabilityDependencyMonitor.MemberUnAvailable = [Microsoft.EnterpriseManagement.Configuration.HealthState]::$USING:MemberUnavailable
		$AvailabilityDependencyMonitor.Algorithm = [Microsoft.EnterpriseManagement.Configuration.ManagementPackDependencyMonitorAlgorithm]::$USING:Algorithm
		If ($USING:Algorithm -ieq 'percentage')
		{
			$AvailabilityDependencyMonitor.AlgorithmParameter = $USING:Percentage
		}
		If ($USING:MemberInMaintenance)
		{
			$AvailabilityDependencyMonitor.MemberInMaintenance = [Microsoft.EnterpriseManagement.Configuration.HealthState]::$USING:MemberInMaintenance
		}

		#Configuration Dependency Monitor
			Write-Verbose "Creating Configuration Dependency monitor '$ConfigurationDependencyMonitorName'."
		$ConfigurationDependencyMonitor = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDependencyMonitor($DestinationMP,$ConfigurationDependencyMonitorName,[Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Public)
		$ConfigurationDependencyMonitor.DisplayName = "$GroupDisplayName Configuration Dependency Monitor"
		$ConfigurationDependencyMonitor.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::ConfigurationHealth
		$ConfigurationDependencyMonitor.ParentMonitorID = $ConfigurationParentMonitor
		$ConfigurationDependencyMonitor.RelationshipType = $RelationshipClass
		$ConfigurationDependencyMonitor.Target = $GroupClass
		$ConfigurationDependencyMonitor.Enabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
		$ConfigurationDependencyMonitor.Remotable = $true
		$ConfigurationDependencyMonitor.Priority = [Microsoft.EnterpriseManagement.Configuration.ManagementPackWorkflowPriority]::Normal
		#Member monitor is same as parrent monitor
		$ConfigurationDependencyMonitor.MemberMonitor = $ConfigurationParentMonitor
		$ConfigurationDependencyMonitor.MemberUnAvailable = [Microsoft.EnterpriseManagement.Configuration.HealthState]::$USING:MemberUnavailable
		$ConfigurationDependencyMonitor.Algorithm = [Microsoft.EnterpriseManagement.Configuration.ManagementPackDependencyMonitorAlgorithm]::$USING:Algorithm
		If ($USING:Algorithm -ieq 'percentage')
		{
			$ConfigurationDependencyMonitor.AlgorithmParameter = $USING:Percentage
		}
		If ($USING:MemberInMaintenance)
		{
			$ConfigurationDependencyMonitor.MemberInMaintenance = [Microsoft.EnterpriseManagement.Configuration.HealthState]::$USING:MemberInMaintenance
		}

		#Performance Dependency Monitor
		Write-Verbose "Creating Performance Dependency monitor '$PerformanceDependencyMonitorName'."
		$PerformanceDependencyMonitor = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDependencyMonitor($DestinationMP,$PerformanceDependencyMonitorName,[Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Public)
		$PerformanceDependencyMonitor.DisplayName = "$GroupDisplayName Performance Dependency Monitor"
		$PerformanceDependencyMonitor.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::PerformanceHealth
		$PerformanceDependencyMonitor.ParentMonitorID = $PerformanceParentMonitor
		$PerformanceDependencyMonitor.RelationshipType = $RelationshipClass
		$PerformanceDependencyMonitor.Target = $GroupClass
		$PerformanceDependencyMonitor.Enabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
		$PerformanceDependencyMonitor.Remotable = $true
		$PerformanceDependencyMonitor.Priority = [Microsoft.EnterpriseManagement.Configuration.ManagementPackWorkflowPriority]::Normal
		#Member monitor is same as parrent monitor
		$PerformanceDependencyMonitor.MemberMonitor = $PerformanceParentMonitor
		$PerformanceDependencyMonitor.MemberUnAvailable = [Microsoft.EnterpriseManagement.Configuration.HealthState]::$USING:MemberUnavailable
		$PerformanceDependencyMonitor.Algorithm = [Microsoft.EnterpriseManagement.Configuration.ManagementPackDependencyMonitorAlgorithm]::$USING:Algorithm
		If ($USING:Algorithm -ieq 'percentage')
		{
			$PerformanceDependencyMonitor.AlgorithmParameter = $USING:Percentage
		}
		If ($USING:MemberInMaintenance)
		{
			$PerformanceDependencyMonitor.MemberInMaintenance = [Microsoft.EnterpriseManagement.Configuration.HealthState]::$USING:MemberInMaintenance
		}

		#Security Dependency Monitor
		Write-Verbose "Creating Security Dependency monitor '$SecurityDependencyMonitorName'."
		$SecurityDependencyMonitor = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDependencyMonitor($DestinationMP,$SecurityDependencyMonitorName,[Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Public)
		$SecurityDependencyMonitor.DisplayName = "$GroupDisplayName Security Dependency Monitor"
		$SecurityDependencyMonitor.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::SecurityHealth
		$SecurityDependencyMonitor.ParentMonitorID = $SecurityParentMonitor
		$SecurityDependencyMonitor.RelationshipType = $RelationshipClass
		$SecurityDependencyMonitor.Target = $GroupClass
		$SecurityDependencyMonitor.Enabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
		$SecurityDependencyMonitor.Remotable = $true
		$SecurityDependencyMonitor.Priority = [Microsoft.EnterpriseManagement.Configuration.ManagementPackWorkflowPriority]::Normal
		#Member monitor is same as parrent monitor
		$SecurityDependencyMonitor.MemberMonitor = $SecurityParentMonitor
		$SecurityDependencyMonitor.MemberUnAvailable = [Microsoft.EnterpriseManagement.Configuration.HealthState]::$USING:MemberUnavailable
		$SecurityDependencyMonitor.Algorithm = [Microsoft.EnterpriseManagement.Configuration.ManagementPackDependencyMonitorAlgorithm]::$USING:Algorithm
		If ($USING:Algorithm -ieq 'percentage')
		{
			$SecurityDependencyMonitor.AlgorithmParameter = $USING:Percentage
		}
		If ($USING:MemberInMaintenance)
		{
			$SecurityDependencyMonitor.MemberInMaintenance = [Microsoft.EnterpriseManagement.Configuration.HealthState]::$USING:MemberInMaintenance
		}

		#Increase MP version
		If ($USING:IncreaseMPVersion)
		{
			$CurrentVersion = $DestinationMP.Version.Tostring()
			$vIncrement = $CurrentVersion.Split('.')
			$vIncrement[$vIncrement.Length - 1] = ([System.Int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
			$NewVersion = ([System.String]::Join('.', $vIncrement))
			$DestinationMP.Version = $NewVersion
		}

		#Verify and save the monitor
		Try {
			$DestinationMP.verify()
			$DestinationMP.AcceptChanges()
			$Result = $true
			Write-Verbose "Group dependency monitors created in Management Pack '$DestinationMPName'($($DestinationMP.Version))."
		} Catch {
			$Result = $false
			$DestinationMP.RejectChanges()
			Write-Error $_.Exception.InnerException
			Write-Error "Unable to dependency monitors for group '$USING:GroupName' in management pack $DestinationMPName."
		}
		$Result
	}
	}
	If ($bRollupConfigured -eq $true)
	{
		Write-Output "Done"
	} else {
		Write-Error "Unable to configure health rollup for group '$GroupName'."
	}
}

$SDK = "OpsMgrMS01"
$GroupName = "Microsoft.SQLServer.2012.InstancesGroup"
$GroupName = "Group.Creation.Demo.Demo.Instance.Group"
$ComputerGroupName = "Group.Creation.Demo.Demo.Computer.Group"
Configure-GroupHealthRollup -SDK $SDK -GroupName $InstanceGroupName -Algorithm "WorstOf" -verbose

#Configure-GroupHealthRollup -SDK $SDK -GroupName $ComputerGroupName -Algorithm "Percentage" -Percentage 90 -MemberUnavailable Warning -MemberInMaintenance Warning -IncreaseMPVersion $true -verbose

