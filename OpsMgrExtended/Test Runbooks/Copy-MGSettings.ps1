Workflow Copy-MGSettings
{
	Write-Verbose "Getting OpsMgrSDK connections."
	$SourceSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_TYANG"
	$DestSDKConn = Get-AutomationConnection -Name "OpsMgrSDK_Azure"
	$CopyResult = InlineScript
	{
		$SourceMGSettings = Get-OMManagementGroupDefaultSettings -SDKConnection $USING:SourceSDKConn
		$iTotal = $SourceMGSettings.count
		$iSuccessful = 0
		$iSkipped = 0
		$iFailed = 0
		$arrSkippedSettings = New-Object System.Collections.ArrayList
		#Some MG specific settings must be excluded
		[Void]$arrSkippedSettings.Add("WebConsole")
		[Void]$arrSkippedSettings.Add("DataWarehouseDatabaseName")
		[Void]$arrSkippedSettings.Add("DataWarehouseServerName")
		[Void]$arrSkippedSettings.Add("ReportingServerUrl")
		Foreach ($Setting in $SourceMGSettings)
		{
			$SettingFullName = $Setting.SettingFullName
			$SettingField = $Setting.FieldName
			$SettingValue = $Setting.Value
			If ($SettingValue.length -eq 0 -or $arrSkippedSettings.Contains($SettingField))
			{
				$iSkipped ++
				Write-Verbose "Skipping Setting Full Name: $SettingFullName, Field Name: $SettingField because either the value is NULL or it is one of the pre-configured skipped fields."
			} else {
				Write-Verbose "Setting Full Name: $SettingFullName, Field Name: $SettingField, Value: $SettingValue"
				$SetDestMG = Set-OMManagementGroupDefaultSetting -SDKConnection $USING:DestSDKConn -SettingType $SettingFullName -FieldName $SettingField -Value $SettingValue
				If ($SetDestMG)
				{
					$iSuccessful ++
					Write-Verbose "The setting $SettingFullName`\$SettingField has been set to $SettingValue."
				} else {
					$iFailed ++
					Write-Error "Unable to set $SettingFullName`\$SettingField to $SettingValue."
				}
			}
		}
		"There are totally $iTotal settings in the source management group. $iSuccessful have been successfully copied to the destination management group. $iSkipped settings have been skipped and $iFailed settings have failed to be copied."
	}
	Write-Verbose "Copying is done. now emailing the result."
	#Email result using SendEmail SMA module (http://blog.tyang.org/2014/10/31/simplified-way-send-emails-mobile-push-notifications-sma/)
	$SMTPConnection = Get-AutomationConnection -Name "OutlookSMTP"
	$TaoContact = Get-AutomationConnection -Name "tyang"
	Send-Email -SMTPSettings $SMTPConnection -To $TaoContact.Email -Subject "SCOM Management Group Settings Copy Result" -Body $CopyResult -HTMLBody $false
}