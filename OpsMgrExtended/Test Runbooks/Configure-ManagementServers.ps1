Workflow Configure-ManagementServers
{
    Param (
        [Parameter(Mandatory=$true, HelpMessage='Please enter the name of a the SMA OpsMgrSDK Connection')][string]$OpsMgrSDKConnection,
		[Parameter(Mandatory=$true, HelpMessage='Please enter the Group Calculation Interval (in milliseconds)')][int]$GroupCalcInterval,
		[Parameter(Mandatory=$true, HelpMessage='Please enter the Data Warehouse Dataset Maintenance timeout (in seconds)')][int]$DWDSMaintTimeout,
		[Parameter(Mandatory=$true, HelpMessage='Please enter the Data Warehouse Bulk Insert Command timeout (in seconds)')][int]$DWBulkInsertTimeout,
		[Parameter(Mandatory=$true, HelpMessage='Please enter the SQL Server Reconnect attempt interval (in seconds)')][int]$DALInitiateClearPoolSeconds
    )
    #Define configuration values
	#Registry key values are documented here: http://blogs.technet.com/b/kevinholman/archive/2014/06/25/tweaking-scom-2012-management-servers-for-large-environments.aspx
    $DALInitiateClearPool  = 1

	#Get all management servers of the managment group
	Write-Verbose "Getting SMA connection object $OpsMgrSDKCOnnection"
	$SDKConnection = Get-AutomationConnection -Name $OpsMgrSDKConnection

	#construct a PS credential object using the username and password specified in the SMA connection. This credential will be used to connect to the management servers
	
	$UserName = $SDKConnection.UserName
	Write-Verbose "Creating a PS credential using UserName $UserName."
	$SecurePassword= ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	$MSCred = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword

	Write-Verbose "Getting list of management servers in this management group."
    $colMS = InlineScript {
        #Connect to management group
        $MG = Connect-OMManagementGroup -SDKConnection $USING:SDKConnection
        $Admin = $MG.Administration

        #Get all management servers in the management group
        $colMS = $Admin.GetAllManagementServers()
        $colMS
    }

    #Configure each management server
    Foreach -Parallel ($MS in $colMS)
    {
        $MSName = $MS.Name
        Write-Output "Configuring $MSName...."
        InlineScript
        {
            $VerbosePreference = [System.Management.Automation.ActionPreference]$Using:VerbosePreference
			$DebugPreference = [System.Management.Automation.ActionPreference]$Using:DebugPreference
			#Group Calculation interval
			Write-Verbose "Configuring Group Calculation Interval on $MSName."
            If (Get-Item -Path Registry::'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0' | Where-Object {$_.Property -eq 'GroupCalcPollingIntervalMilliseconds'})
            {
               Set-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0' -Name GroupCalcPollingIntervalMilliseconds -value $USING:GroupCalcInterval
            } else {
               New-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0' -Name GroupCalcPollingIntervalMilliseconds -value $USING:GroupCalcInterval -PropertyType DWord | Out-Null
            }

            #DW Dataset maintenance timout
			Write-Verbose "Configuring DW Dataset maintenance timout on $MSName."
            $DWRegKey = 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse'
            If (!(Test-Path $DWRegKey))
            {
                New-Item -path $DWRegKey | Out-Null
            }
            If (Get-Item -Path Registry::'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse' | Where-Object {$_.Property -eq 'Command Timeout Seconds'})
            {
               Set-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse' -Name 'Command Timeout Seconds' -value $USING:DWDSMaintTimeout
            } else {
               New-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse' -Name 'Command Timeout Seconds' -value $USING:DWDSMaintTimeout -PropertyType DWord | Out-Null
            }

            #DW Bulk Insert Command Timeout
			Write-Verbose "Configuring DW Bulk Insert Command Timeout on $MSName."
            $DWRegKey = 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse'
            If (!(Test-Path $DWRegKey))
            {
                New-Item -path $DWRegKey | Out-Null
            }
            If (Get-Item -Path Registry::'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse' | Where-Object {$_.Property -eq 'Command Timeout Seconds'})
            {
               Set-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse' -Name 'Bulk Insert Command Timeout Seconds' -value $USING:DWBulkInsertTimeout
            } else {
               New-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse' -Name 'Bulk Insert Command Timeout Seconds' -value $USING:DWBulkInsertTimeout -PropertyType DWord | Out-Null
            }

            #SQL Server Reconnect Behaviour
			Write-Verbose "Configuring SQL Server Reconnect Behaviour on $MSName."
            If (Get-Item -Path Registry::'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\System Center\2010\Common\DAL' | Where-Object {$_.Property -eq 'DALInitiateClearPool'})
            {
               Set-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\DAL' -Name 'DALInitiateClearPool' -value $USING:DALInitiateClearPool
            } else {
               New-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\DAL' -Name 'DALInitiateClearPool' -value $USING:DALInitiateClearPool -PropertyType DWord | Out-Null
            }
            If (Get-Item -Path Registry::'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\System Center\2010\Common\DAL' | Where-Object {$_.Property -eq 'DALInitiateClearPoolSeconds'})
            {
               Set-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\DAL' -Name 'DALInitiateClearPoolSeconds' -value $USING:DALInitiateClearPoolSeconds
            } else {
               New-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\DAL' -Name 'DALInitiateClearPoolSeconds' -value $USING:DALInitiateClearPoolSeconds -PropertyType DWord | Out-Null
            }
        } -PSComputerName $MSName -PSCredential $MSCred
    }
	Write-Output "Done."
}