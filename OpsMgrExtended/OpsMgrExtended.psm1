Function Connect-OMManagementGroup
{
<# 
 .Synopsis
  Connect to OpsMgr Management Group using SDK

 .Description
  Connect to OpsMgr Management Group Data Access Service using SDK

 .Parameter -SDKConnection
  OpsMgr SDK Connection object (SMA connection or hash table).

 .Parameter -SDK
  Management Server name.

 .Parameter -UserName
  Alternative user name to connect to the management group (optional).

 .Parameter -Password
  Alternative password to connect to the management group (optional).

  .Parameter -DLLPath
  Optionally, specify an alternative path to the OpsMgr SDK DLLs if they have not been installed in GAC.

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01"
  Connect-OMManagementGroup -SDK "OpsMgrMS01"

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" using different credential
  $Password = ConvertTo-SecureString -AsPlainText "password1234" -force
  $MG = Connect-OMManagementGroup -SDK "OpsMgrMS01" -Username "domain\SCOM.Admin" -Password $Password

 .Example
  # Connect to OpsMgr management group via management server "OpsMgrMS01" using current user's credential
  $MG = Connect-OMManagementGroup -SDK "OpsMgrMS01"
  OR
  $MG = Connect-OMManagementGroup -Server "OPSMGRMS01"

 .Example
  # Connect to OpsMgr management group using the SMA connection "OpsMgrSDK_TYANG"
  $SDKCOnnection = Get-AutomationConnection "OpsMgrSDK_TYANG"
  $MG = Connect-OMManagementGroup -SDKConnection $SDKConnection
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName='SMAConnection',Mandatory=$true,HelpMessage='Please specify the SMA Connection object')][Alias('Connection','c')][Object]$SDKConnection,
		[Parameter(ParameterSetName='IndividualParameter',Mandatory=$true,HelpMessage='Please enter the Management Server name')][Alias('DAS','Server','s')][String]$SDK,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the user name to connect to the OpsMgr management group')][Alias('u')][String]$Username = $null,
        [Parameter(ParameterSetName='IndividualParameter',Mandatory=$false,HelpMessage='Please enter the password to connect to the OpsMgr management group')][Alias('p')][SecureString]$Password = $null
    )
	If ($SDKConnection)
	{
		$SDK = $SDKConnection.ComputerName
		$Username = $SDKConnection.Username
		$Password = ConvertTo-SecureString -AsPlainText $SDKConnection.Password -force
	}
    #Check User name and password parameter
    If ($Username)
    {
        If (!$Password)
        {
            Write-Error "Password for user name $Username must be specified!"
			Return $null
        }
    }

    #Connect to the management group
	$MGConnSetting = New-Object Microsoft.EnterpriseManagement.ManagementGroupConnectionSettings($SDK)
	If ($Username -and $Password)
	{
		$MGConnSetting.UserName = $Username
		$MGConnSetting.Password = $Password
	}
	$MG = New-Object Microsoft.EnterpriseManagement.ManagementGroup($MGConnSetting)
    $MG
}
