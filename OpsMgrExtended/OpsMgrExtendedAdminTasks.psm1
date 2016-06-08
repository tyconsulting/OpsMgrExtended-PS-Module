Function Backup-OMManagementPacks
{
<# 
 .Synopsis
  Backup OpsMgr management packs using OpsMgr SDK

 .Description
  Backup OpsMgr sealed and unsealed management packs using OpsMgr SDK. A boolean value $true will be returned if the backup has been successful, otherwise, a boolean value of $false is returned if any there are any errors occurred during the backup process.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -BackupLocation
  MP Backup Location.

 .Parameter -BackupSealedMP
  Set this parameter true to backup sealed management packs as well (exported into unsealed XMLs).

 .Parameter -RetentionDays
  Number of retention days for the management pack backup.

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" using current user's credentials and then backup both sealed and unsealed management packs to \\server\backup, with 3 retention days:
  Backup-OMManagementPacks -SDK "OpsMgrMS01" -BackupLocation "\\server\backup" -BackupSealedMP -RetentionDays 3

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" using alternative credentials and then backup both sealed and unsealed management packs to \\server\backup, with 3 retention days:
  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  Backup-OMManagementPacks -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -BackupLocation "\\server\backup" -BackupSealedMP $true -RetentionDays 3

 .Example
  # Connect to OpsMgr management group the SMA connection "OpsMgrSDK_TYANG" and then backup both sealed and unsealed management packs to \\server\backup, with 3 retention days:
  $SDKCOnnection = Get-AutomationConnection "OpsMgrSDK_TYANG"
  Backup-OMManagementPacks -SDKConnection $SDKConnection -BackupLocation "\\server\backup" -BackupSealedMP $true -RetentionDays 3
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter backup location')][String]$BackupLocation,
        [Parameter(Mandatory=$false,HelpMessage='Also backup sealed management packs')][Boolean]$BackupSealedMP = $false,
        [Parameter(Mandatory=$true,HelpMessage='Please enter retention days')][String]$RetentionDays
    )

    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    #Management Group Name
    $MGName = $MG.Name

    #Check Backup Location
    If ((Test-Path $BackupLocation))
    {
	    #backup should be located in a sub folder with the name of the management group
	    $BackupLocation = Join-Path $BackupLocation $MGName
	    If (!(Test-Path $BackupLocation))
	    {
		    New-Item -type directory -Path $BackupLocation | Out-Null
	    }

	    $date = Get-Date
	    $BackupSubDir = "$($date.day)-$($date.month)-$($date.year) $($date.hour)`.$($date.minute)`.$($date.second)"
	    $BackupDir = Join-Path $BackupLocation $BackupSubDir
	    $UnsealedBackupDir = Join-Path $BackupDir 'Unsealed'
	    $SealedBackupDir = Join-Path $BackupDir 'Sealed'
	    #Create Backup Directory structure
	    New-Item -type directory -Path $BackupDir | Out-Null
	    New-Item -type directory -Path $UnsealedBackupDir | Out-Null
	    New-Item -type directory -Path $SealedBackupDir | Out-Null
	
	    #Get MPs
	    If ($BackupSealedMP){
            Write-Verbose 'INFO: Backing up both sealed and unsealed management packs'
		    #Get all sealed and unsealed MPs
		    $arrMPs = $MG.GetManagementPacks()
		
		    #Create a MPXMLWriter for sealed MPs
            Write-Verbose 'Creating ManagementPackXmlWriter object for backing up sealed management packs.'
		    Try {
			    $SealedmpWriter = new-object Microsoft.EnterpriseManagement.Configuration.IO.ManagementPackXmlWriter($SealedBackupDir)
		    } Catch {
			    $BackupMPErrors += "Unable to create a ManagementPackXmlWriter object for location: $SealedBackupDir`."
		    }
	    } else {
            Write-Verbose 'Backing up only unsealed management packs'
		    $strMPquery = "Sealed = 'false'"
		    $mpCriteria = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria($strMPquery)
		    $arrMPs = $MG.GetManagementPacks($mpCriteria)
	    }

	    #Create a MPXMLWriter for unsealed MPs
        Write-Verbose 'Creating ManagementPackXmlWriter object for backing up unsealed management packs.'
	    Try {
		    $UnsealedmpWriter = new-object Microsoft.EnterpriseManagement.Configuration.IO.ManagementPackXmlWriter($UnsealedBackupDir)
	    } Catch {
		    Write-Error "Unable to create a ManagementPackXmlWriter object for location: $UnsealedBackupDir`."
	    }

	    if ($arrMPs.count -lt 1)
	    {
		    Write-Error "No management packs are found in the management group $MGName."
	    } else {
            Write-Verbose "$($arrMPs.count) management packs found in the management group $MGName."
        }

	    Foreach ($MP in $arrMPs)
	    {

		    If ($MP.Sealed)
		    {
                Write-Verbose "Backing up sealed MP: $($MP.Name)"
                $mpWriter = $SealedmpWriter
		    } else {
			    Write-Verbose "Backing up unsealed MP: $($MP.Name)"
                $mpWriter = $UnsealedmpWriter
		    }
		    Try {
			    If ($mpWriter)
			    {
                    $mpWriter.WriteManagementPack($MP) | Out-Null
			    }
		    } Catch {
			    Write-Error "Unable to export managment pack $($MP.Name)"
		    }
	    }
    } else {
	    Write-Error "Invalid Backup Location specified`: $BackupLocation"
    }

    #Delete old backup only if this backup is considered successful.
    if ($error.count -eq 0)
    {
        Write-Verbose 'MP backup considered successful, deleting old backups now'
		$Result = $true
        $ChildItems += Get-ChildItem $BackupLocation | Where-Object {$_.PSIsContainer -eq $true}
		Foreach ($item in $ChildItems)
		{
			$fullPath = $item.FullName
			if ($item.CreationTime -le $date.adddays(-$RetentionDays))
			{
                Write-Verbose "Deleting $item"
                Remove-Item -Path $fullPath -Recurse -Force -Confirm:$false
			}
		}
    } else {
		Write-Error 'Error occurred during backup process.'
		$Result= $false
	}
    $Result
}

Function Approve-OMManualAgents
{
<# 
 .Synopsis
  Approve manually installed OpsMgr agents that meet the naming convention

 .Description
  Approve manually installed OpsMgr agents that meet the naming convention using OpsMgr SDK

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -AgentNameRegex
  Agent Name regular expression.

 .Parameter -AgentDomainRegex
  Agent Domain name regular expression.

 .Parameter -MaxToApprove
  Maximum number of manually installed agent to approve. the default value is 1 if it's not specified

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" using alternative credentials and then approve manually installed agents with the following parameters:
  Agent Name Regular Expression: "^server\d{3}$"
  Agent Domain Regular Expression: "YourCompany.com"
  Maximum number of agents to approve: 50
  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  Approve-OMManualAgents -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -AgentNameRegex "^server\d{3}$" -AgentDomainRegex "YourCompany.com" -MaxToApprove 50

  .Example
  # Connect to OpsMgr management group using the SMA connection "OpsMgrSDK_TYANG" and then approve manually installed agent "SERVER01":
  $SDKCOnnection = Get-AutomationConnection "OpsMgrSDK_TYANG"
  Approve-OMManualAgents -SDKConnection $SDKConnection -AgentNameRegex "^server01$"
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter agent name regular expression')][String]$AgentNameRegex,
        [Parameter(Mandatory=$false,HelpMessage='Please ente agent domain regular expression')][String]$AgentDomainRegex = $NULL,
        [Parameter(Mandatory=$false,HelpMessage='Please enter maxinum number of agents to be approved')][Int]$MaxToApprove = 1
    )

    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    $Admin = $MG.Administration
    $ApprovalList = New-object 'system.collections.generic.List[Microsoft.EnterpriseManagement.Administration.AgentPendingAction]'
    $arrApprovedComputers = @()
    $allPendingActions = $Admin.GetAgentPendingActions()
    Foreach ($item in $allPendingActions)
    {
	    If ($item.AgentPendingActionType -eq 'ManualApproval')
	    {
		    $PreCount = $PreCount +1
		    $AgentFQDN = $item.AgentName
		    $AgentName = $($AgentFQDN.Split('.'))[0]
		    $AgentDomain = $AgentFQDN.substring($AgentName.length+1, $($AgentFQDN.length-$agentName.length-1))
		    if ($AgentName -imatch $AgentNameRegex -and $AgentDomain -imatch $AgentDomainRegex -and $ApprovalList.Count -lt $MaxToApprove)
		    {
			    #Add the agent to the approval list
                Write-Verbose "$AgentFQDN will be approved."
			    $ApprovalList.Add($item)
			    $arrApprovedComputers += $AgentFQDN
		    }
	    }
    }
    $ApprovedCount = $ApprovalList.count
    Write-Verbose "Total number of agents to be approved: $ApprovedCount"
    If ($ApprovedCount -gt 0)
    {
        Write-Verbose 'Approving manually installed agents'	    
        $Admin.ApproveAgentPendingActions($ApprovalList)
    }
    Write-Output 'Done'
}

Function Add-OMManagementGroupToAgent
{
<# 
 .Synopsis
  Configure an OpsMgr agent to report to a specific management group

 .Description
  Configure an OpsMgr agent to report to a specific management group using WinRM. If the management group have been successfully added, a boolean value $true will be returned, otherwise, a boolean value of $false is returned if any there are any errors occurred during the add process.

 .Parameter -AgentComputer
  Name of the agent computer

 .Parameter -UserName
  Alternative user name to connect to the agent computer (optional).

 .Parameter -Password
  Alternative password to connect to the agent computer (optional).

 .Parameter -WinRMPort
 The WinRM TCP port for configured on the agent computer. The default port of 5985 is used when not specified.

 .Parameter -ManagementServer
  The primary management server the agent computer is reporting to.

 .Parameter -ManagementGroupName
  Name of the management group the agent computer is reporting to.

 .Parameter -OpsMgrPort
  The TCP port that the agent computer is using to connect to the management group. The default port of 5723 is used when not specified.

  .Parameter -RemoveExistingMG
  Set this parameter to true to remove any existing management groups that have been configured on the agent computer

 .Example
  # Configure the agent computer "SERVER01" to report to the management serer "OPSMGR01" in management group "TYANG" and remove any existing management groups configured on the agent computer

  Add-OMManagementGroupToAgent -AgentComputer "SERVER01" -ManagementServer "OPSMGR01" -ManagementGroupName "TYANG" -RemoveExistingMG

  .Example
  # Connect to the agent computer "SERVER01" using alternative credentials and configure it to report to the management serer "OPSMGR01" in management group "TYANG" using WinRM port 1234
  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  Add-OMManagementGroupToAgent -AgentComputer "SERVER01" -UserName "Domain\Admin" -Password $Password -ManagementServer "OPSMGR01" -ManagementGroupName "TYANG" -WinRMPort 1234
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter the agent computer name')][Alias('Agent')][String]$AgentComputer,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the user name to connect to the agent computer')][Alias('u')][String]$Username = $null,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the password to connect to the agent computer')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the WinRM port number configured on the agent computer')][Int]$WinRMPort = 5985,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('MS')][String]$ManagementServer,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management group name')][Alias('MG')][String]$ManagementGroupName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the port number for the OpsMgr agent communication')][Int]$OpsMgrPort = 5723,
        [Parameter(Mandatory=$false,HelpMessage='Remove existing management groups that are configured on the agent comptuer')][Boolean]$RemoveExistingMG = $false
    )
    #Create WinRM connection to the agent comptuer
    Write-Verbose "Trying to connect to $AgentComputer using WinRM"
    If ($Username -and $Password)
    {
        Write-Verbose "Alternative credential specified for the WinRM connection to $AgentComputer"
        $AgentCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $Password
    }
    Try {
        Write-Verbose "Creating WinRM session to $AgentComputer"
        if ($AgentCred)
        {
            $AgentSession = New-PSSession -ComputerName $AgentComputer -Credential $AgentCred -Port $WinRMPort -ErrorAction Stop
        } else {
            $AgentSession = New-PSSession -ComputerName $AgentComputer -Port $WinRMPort -ErrorAction Stop
        }
    } Catch {
        Write-Error "Unable to establish WinRM session to $AgentComputer"
    }
    Write-Verbose "Configuring $AgentComputer via WinRM"
    $AddResult = Invoke-Command -Session $AgentSession -ScriptBlock {
        Param([String]$ManagementServer, [String]$ManagementGroupName, [int]$OpsMgrPort, [Boolean]$RemoveExistingMG)
        Try {
            $objAgent = New-object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        } Catch {
            Write-Error "Unable to create AgentConfigManager.MgmtSvcCfg object. Please make sure the appropriate version of OpsMgr 2012 agent is installed on $env:COMPUTERNAME"
        }

        #Get current configured management groups
        $arrCurrentMGs = $objAgent.GetManagementGroups()

        #Check if the agent is already configured to the management group
        $bAlreadyConfigured = $FALSE
        Write-Verbose "Checking if $env:ComputerName is already reporting to $ManagementGroupName"
        Foreach ($item in $arrCurrentMGs)
        {
            $ExistingMGName = $item.managementGroupName
            if ($ExistingMGName -ieq $ManagementGroupName)
            {
                Write-Warning "$env:ComputerName has already been configured to report to management group $ManagementGroupName"
                $bAlreadyConfigured = $true
            } else {
                if ($RemoveExistingMG)
                {
                    Write-Verbose "Removing Currently configured management group: $ExistingMGName"
                    $objAgent.RemoveManagementGroup($ExistingMGName)
                }
            }
        }

        If (!$bAlreadyConfigured)
        {
            Write-Verbose "$ManagementGroupName has not been configured on $env:comptername yet. Continuing configuration."
            If ($RemoveExistingMG -eq $FALSE)
            {
                If ($arrCurrentMGs.Count -ge 4)
                {
                    Write-Error "Unable to add additional MG to $env:COMPUTERNAME without removing any existing management groups. Currently there are $($arrCurrentMGs.count) management group configured, OpsMgr 2012 only supports up to 4 management groups for multihomed agents."
                    Exit
                }
            } else {
                Foreach ($item in $arrCurrentMGs)
                {
                    $ExistingMGName = $item.managementGroupName
                    Write-Verbose "Removing Currently configured management group: $ExistingMGName"
                    $objAgent.RemoveManagementGroup($ExistingMGName)
                }
            }
        
            #Add new MG
            Write-Verbose "Adding Management Group $ManagementGroupName to $env:ComputerName"
            $MGAddResult = $objAgent.AddManagementGroup($ManagementGroupName, $ManagementServer, $OpsMgrPort)
        }
        #Return result
        $error
    } -ArgumentList $ManagementServer, $ManagementGroupName, $OpsMgrPort, $RemoveExistingMG

    If ($AddResult)
    {
        Write-Error "Error occurred while configuring OpsMgr agent on $AgentComputer via WinRM."
        Write-Error $AddResult
		$Result = $false
    } else {
        Write-Verbose "$AgentComputer successfully configured"
		$Result = $true
    }
    #House clean
    Write-Verbose "Removing WinRM Session to $AgentComputer"
    Remove-PSSession $AgentSession
    $Result
}

Function Remove-OMManagementGroupFromAgent
{
<# 
 .Synopsis
  Remove a management group configuration from an OpsMgr agent

 .Description
  Remove a management group configuration from an OpsMgr agent using WinRM. If the management group have been successfully deleted, a boolean value $true will be returned, otherwise, a boolean value of $false is returned if any there are any errors occurred during the deletion process.

 .Parameter -AgentComputer
  Name of the agent computer

 .Parameter -UserName
  Alternative user name to connect to the agent computer (optional).

 .Parameter -Password
  Alternative password to connect to the agent computer (optional).

 .Parameter -WinRMPort
 The WinRM TCP port for configured on the agent computer. The default port of 5985 is used when not specified.

 .Parameter -ManagementGroupName
  Name of the management group to be removed.

 .Example
  # Remove management group "TYANG" from OpsMgr agent on "SERVER01"
  Remove-OMManagementGroupFromAgent -AgentComputer "SERVER01" -ManagementGroupName "TYANG"

  .Example
  # Connect to the agent computer "SERVER01" using alternative credentials and remove management group "TYANG" using WinRM port 1234
  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  Remove-OMManagementGroupFromAgent -AgentComputer "SERVER01" -UserName "Domain\Admin" -Password $Password -ManagementGroupName "TYANG" -WinRMPort 1234
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter the agent computer name')][Alias('Agent')][String]$AgentComputer,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the user name to connect to the agent computer')][Alias('u')][String]$Username = $null,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the password to connect to the agent computer')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the WinRM port number configured on the agent computer')][Int]$WinRMPort = 5985,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('MS')][String]$ManagementServer,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management group name')][Alias('MG')][String]$ManagementGroupName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the port number for the OpsMgr agent communication')][Int]$OpsMgrPort = 5723,
        [Parameter(Mandatory=$false,HelpMessage='Remove existing management groups that are configured on the agent comptuer')][Boolean]$RemoveExistingMG = $false
    )
    #Create WinRM connection to the agent comptuer
    Write-Verbose "Trying to connect to $AgentComputer using WinRM"
    If ($Username -and $Password)
    {
        Write-Verbose "Alternative credential specified for the WinRM connection to $AgentComputer"
        $AgentCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $Password
    }
    Try {
        Write-Verbose "Creating WinRM session to $AgentComputer"
        if ($AgentCred)
        {
            $AgentSession = New-PSSession -ComputerName $AgentComputer -Credential $AgentCred -Port $WinRMPort -ErrorAction Stop
        } else {
            $AgentSession = New-PSSession -ComputerName $AgentComputer -Port $WinRMPort -ErrorAction Stop
        }
    } Catch {
        Write-Error "Unable to establish WinRM session to $AgentComputer"
    }
    Write-Verbose "Configuring $AgentComputer via WinRM"
    $RemoveResult = Invoke-Command -Session $AgentSession -ScriptBlock {
        Param([String]$ManagementServer, [String]$ManagementGroupName, [int]$OpsMgrPort, [Boolean]$RemoveExistingMG)
        Try {
            $objAgent = New-object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        } Catch {
            Write-Error "Unable to create AgentConfigManager.MgmtSvcCfg object. Please make sure the appropriate version of OpsMgr 2012 agent is installed on $env:COMPUTERNAME"
        }

        #Get current configured management groups
        $arrCurrentMGs = $objAgent.GetManagementGroups()

         Foreach ($item in $arrCurrentMGs)
        {
            $MGName = $item.managementGroupName
            if ($MGName -ieq $ManagementGroupName)
            {
                 Write-Verbose "Removing management group: $MGName"
                $objAgent.RemoveManagementGroup($MGName)
            } 
        }

        #Return result
        $error
    } -ArgumentList $ManagementGroupName

    If ($RemoveResult)
    {
        Write-Error "Error occurred while configuring OpsMgr agent on $AgentComputer via WinRM."
        Write-Error $RemoveResult
		$Result = $false
		
    } else {
        Write-Verbose "$AgentComputer successfully configured."
		$Result= $true
    }
    #House clean
    Write-Verbose "Removing WinRM Session to $AgentComputer"
    Remove-PSSession $AgentSession
    $Result
}

Function Get-OMManagementGroupDefaultSettings
{
<# 
 .Synopsis
  Get OpsMgr management group default settings

 .Description
  Get OpsMgr management group default settings via OpsMgr SDK. A System.Collections.ArrayList is returned containing all management group default settings. Each setting in the arraylist is presented in a hashtable format.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" using alternative credentials and retrieve all the settings:

  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  Get-OMManagementGroupDefaultSettings -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password

 .Example
  # Connect to OpsMgr management group using the SMA OpsMgrSDK connection "OpsMgrSDK_TYANG" and retrieve all the settings:

  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  $MGSettings = Get-OMManagementGroupDefaultSettings -SDKConnection $SDKConnection 

#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null
    )

    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}


    $Admin = $MG.Administration
    $Settings = $Admin.Settings

    #Get Setting Types
    Write-Verbose 'Get all nested setting types'
    $arrRumtimeTypes = New-Object System.Collections.ArrayList
    $Assembly = [AppDomain]::CurrentDomain.GetAssemblies() |Where-Object { $_.FullName -eq 'Microsoft.EnterpriseManagement.OperationsManager, Version=7.0.5000.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35'}
    $SettingType = $assembly.definedtypes | Where-Object{$_.name -eq 'settings'}
    $TopLevelNestedTypes = $SettingType.GetNestedTypes()
    Foreach ($item in $TopLevelNestedTypes)
    {
        if ($item.DeclaredFields.count -gt 0)
        {
            [void]$arrRumtimeTypes.Add($item)
        }
        $NestedTypes = $item.GetNestedTypes()
        foreach ($NestedType in $NestedTypes)
        {
            [void]$arrRumtimeTypes.Add($NestedType)
        }
    }

    #Get Setting Values
    Write-Verbose 'Getting setting values'
    $arrSettingValues = New-Object System.Collections.ArrayList
    Foreach ($item in $arrRumtimeTypes)
    {
        Foreach ($field in $item.DeclaredFields)
        {
            $FieldSetting = $field.GetValue($field.Name)
            $SettingValue = $Settings.GetDefaultValue($FieldSetting)
            $hash = @{
                FieldName = $Field.Name
                Value = $SettingValue
                AllowOverride = $FieldSetting.AllowOverride
                SettingName = $item.Name
                SettingFullName = $item.FullName
            }
            $objSettingValue = New-object psobject -Property $hash
            [void]$arrSettingValues.Add($objSettingValue)
        }
    }
    Write-Verbose "Total number of Management Group default value found: $($arrSettingValues.count)."
    $arrSettingValues
}

Function Set-OMManagementGroupDefaultSetting
{
<# 
 .Synopsis
  Set OpsMgr management group default settings

 .Description
  Set OpsMgr management group default settings via OpsMgr SDK. A boolean value $true will be returned if the setting has been successfully set, otherwise, a boolean value of $false is returned if any there are any errors occurred.

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

 .Parameter -SettingType
  Full name of the setting type (can be retrieved from Get-OMManagementGroupDefaultSettings).

 .Parameter -FieldName
  Field name of the setting type (can be retrieved from Get-OMManagementGroupDefaultSettings).

 .Parameter -Value
  Desired value that the field should be set to.

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" using alternative credentials and set ProxyingEnabled default setting to TRUE:
  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  Set-OMManagementGroupDefaultSetting -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password -SettingType Microsoft.EnterpriseManagement.Administration.Settings+HealthService -FieldName ProxyingEnabled -Value $TRUE

.Example
  # Connect to OpsMgr management group using the SMA OpsMgrSDK connection "OpsMgrSDK_TYANG" and set ProxyingEnabled default setting to TRUE:
  $SDKConnection = Get-AutomationConnection -Name OpsMgrSDK_TYANG
  Set-OMManagementGroupDefaultSetting -SDKConnection $SDKConnection -SettingType Microsoft.EnterpriseManagement.Administration.Settings+HealthService -FieldName ProxyingEnabled -Value $TRUE
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the Setting Type name')][Alias('Setting')][String]$SettingType,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the Field name')][Alias('Field')][String]$FieldName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the new value for the field name')][Alias('v')]$Value
    )

    #Connect to MG
	If ($SDKConnection)
	{
		Write-Verbose "Connecting to Management Group via SDK $($SDKConnection.ComputerName)`..."
		$MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	} else {
		Write-Verbose "Connecting to Management Group via SDK $SDK`..."
		If ($Username -and $Password)
		{
			$MG = Connect-OMManagementGroup -SDK $SDK -UserName $Username -Password $Password
		} else {
			$MG = Connect-OMManagementGroup -SDK $SDK
		}
	}

    $Admin = $MG.Administration
    $Settings = $Admin.Settings

    #Get Setting Types
    $Assembly = [AppDomain]::CurrentDomain.GetAssemblies() |Where-Object { $_.FullName -eq 'Microsoft.EnterpriseManagement.OperationsManager, Version=7.0.5000.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35'}
    Write-Verbose "Getting $FieldName Field Type"
    $objSettingType = (New-object -TypeName $SettingType).GetType()
    #$objField = $objSettingType.GetDeclaredField($FieldName)
	$objField = $objSettingType.GetField($FieldName)
    $FieldSetting = $objField.GetValue($objField.Name)

     #Get current value - required to get value type
    $CurrentValue = $Settings.GetDefaultValue($FieldSetting)

    #Convert data type
    $ConvertedValue = $Value -as $CurrentValue.Gettype()
    If ($ConvertedValue -eq $null)
    {
        Write-Error "Unable to convert value $Value with type $($Value.gettype()) to type $($CurrentValue.Gettype())."
		$Result = $false
    } else {
        #Set default value
		Try {
			Write-Verbose "Setting default value of $FieldName to $Value"
			$Settings.SetDefaultValue($FieldSetting, $ConvertedValue)
			$Settings.ApplyChanges()
			$Result = $true
		} catch {
			Write-Error $_.Exception
			Write-Error "Unable to set the setting $SettingType`\$FieldName to $Value."
			$Result= $false
		}
    }
	$Result
}