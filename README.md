# OpsMgrExtended PowerShell Module
## Introduction
The OpsMgrExtended PowerShell module automates several SCOM administrative and authoring tasks in PowerShell. more information and demo can be found at Tao Yang's blog:

* Introduction: http://blog.tyang.org/2015/06/24/automating-opsmgr-part-1-introducing-opsmgrextended-powershell-sma-module/
* Automating OpsMgr blog series: https://blog.tyang.org/tag/automating-opsmgr/

This module can also be found in PowerShell Gallery: https://www.powershellgallery.com/packages/OpsMgrExtended/1.3.0

## Version History

### Current version: v1.3.1
Change logs:
* Bug fix in Copy-OMManagementPack function. the password fields should be secureString.
* 
### Version: v1.3.0
Change logs:
* Bug fixes in New-OMOverride function
* Added SCOM 2016 SDK DLLs to the module (SCOM 2016 UR14)
* Updated the module manifest to make it compatible with PowerShell PackageManagement (WMF 5.0)
* Configured the module to automatically load SCOM 2016 SDK DLLs
* Removed Install-OpsMgrSDK and Import-OpsMgrSDK functions because they are not required

### Version v1.2.0
Change logs: http://blog.tyang.org/2015/10/14/automating-opsmgr-part-18-second-update-to-the-opsmgrextended-module-v1-2/


## Functions
This module offers the following functions:
* Add-OMManagementGroupToAgent
* Approve-OMManualAgents
* Backup-OMManagementPacks
* Connect-OMManagementGroup
* Copy-OMManagementPack
* Get-OMDAMembers
* Get-OMManagementGroupDefaultSettings
* Get-OMManagementPack  
* New-OM2StateEventMonitor
* New-OM2StatePerformanceMonitor
* New-OMAlertConfiguration
* New-OMComputerGroup
* New-OMComputerGroupExplicitMember
* New-OMConfigurationOverride
* New-OMEventCollectionRule
* New-OMInstanceGroup
* New-OMInstanceGroupExplicitMember
* New-OMManagementPack
* New-OMManagementPackReference
* New-OMModuleConfiguration
* New-OMOverride
* New-OMPerformanceCollectionRule
* New-OMPropertyOverride
* New-OMRule
* New-OMServiceMonitor
* New-OMTCPPortCheckDataSourceModuleType
* New-OMTCPPortCheckMonitorType
* New-OMTCPPortMonitoring
* New-OMWindowsServiceTemplateInstance
* Remove-OMGroup
* Remove-OMManagementGroupFromAgent
* Remove-OMManagementPack
* Remove-OMOverride
* Set-OMManagementGroupDefaultSetting
* Update-OMGroupDiscovery