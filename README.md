# CCM-Core
A lightweight module for managing SCCM resources and collections that relies on CIM cmdlets and is compatible with PowerShell Core and 7.0

Purpose:
* Get-WMIObject is deprecated and isn't currently in PowerShell 7.0, to show how to use CIM cmdlets (wmi 2.0)
* Provide a faster, lightweight alternative to the Microsoft SCCM module
* Allow more complex WQL filtering than is offered by the SCCM module

Design Goals:
* When possible, return a cmdlet's default output type. Return cim instances, and avoid custom object types (no PSObjects)
	* All output should work with built-in CIM functionality - Get-CimInstance, Set-CimInstance, Remove-CimInstance, Invoke-CimMethod should work with output
* Every function should have Filter and Property parameters
* Use format and type files to manipulate output without changing object types

When Contributing:
* When contributing to the module please update the .PS1, ps1xml, etc. files, but not the PSD1 or PSM1 directly. I'm working on improving my pipeline, and the supporting files like the manifest/module are created dynamically from the .ps1 files, so any manual changes to the PSM1 are ultimately overwritten

### Public Functions:
- Add-CCMMembershipDirect
- Add-CCMMembershipQuery
- Connect-CCM
- Find-CCMClientByCollection
- Find-CCMObject
- Get-CCMApplication
- Get-CCMBoundaryGroup
- Get-CCMCimClass
- Get-CCMCimInstance
- Get-CCMCimInstanceByResourceName
- Get-CCMCollection
- Get-CCMCollectionMember
- Get-CCMCollectionSettings
- Get-CCMObjectContainerItem
- Get-CCMObjectContainerNode
- Get-CCMResource
- Get-CCMResourceMembership
- Get-CCMScript
- Get-CCMScriptExecutionStatus
- Get-CCMSoftwareUpdate
- Get-CCMSoftwareUpdateDeployment
- Get-CCMSoftwareUpdateGroup
- Get-CCMUpdatesAssignment
- Get-CCMUserMachineRelationship
- Get-NthWeekDay
- Invoke-CCMCollectionRefresh
- New-CCMCollection
- Remove-CCMMembershipDirect
- Test-CCMQueryRule


### SupportFunctions:
- Add-CCMClassType
- Get-NthWeekDay (Get-PatchTuesday)

### Classes
