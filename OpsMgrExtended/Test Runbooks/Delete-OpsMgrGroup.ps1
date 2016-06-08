Workflow Delete-OpsMgrGroup
{
	Param(
	[Parameter(Mandatory=$true)][String]$GroupName,
	[Parameter(Mandatory=$true)][Boolean]$IncreaseMPVersion
	)
 
	#Get OpsMgrSDK connection object
	$OpsMgrSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_HOME"

	#Firstly, make sure the monitors targeting this group is deleted (i.e dependency monitors for health rollup)
	Write-Verbose "Checking dependency monitors targeting the group '$GroupName'."
	$bDeleteMonitors = InlineScript {
		#Connect to MG
		$MG = Connect-OMManagementGroup -SDKConnection $USING:OpsMgrSDKConn
		$Group = $MG.GetMonitoringClasses($USING:GroupName)
		$GroupMP = $Group.GetManagementPack()
		If ($GroupMP.Sealed  -eq $true)
		{
			Write-Error "The group is defined in a sealed MP, unable to continue."
			Return $false
		}
		$GroupID = $Group.Id.ToString()
		$MonitorCriteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorCriteria("Target='$GroupID'")
		$Monitors = $MG.GetMonitors($MonitorCriteria)
		Foreach ($Monitor in $Monitors)
		{
			Write-Verbose "Deleting '$($Monitor.Name)'..."
			$MonitorMP = $Monitor.GetManagementPack()
			$Monitor.Status = "PendingDelete"
			Try {
				$MonitorMP.Verify()
				$MonitorMP.AcceptChanges()
			} Catch {
				Write-Error $_.Exception.InnerException.Message
				Return $false
			}
		}
		Return $true
	}
	If ($bDeleteMonitors -eq $true)
	{
		$bGroupDeleted =Remove-OMGroup -SDKConnection $OpsMgrSDKConn -GroupName $GroupName -IncreaseMPVersion $IncreaseMPVersion
	}
	If ($bGroupDeleted -eq $true)
	{
	Write-Output "Done."
	} else {
	throw "Unable to delete group '$GroupName'."
	exit
	}
}