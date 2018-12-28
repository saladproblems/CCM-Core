# CCM-Core
A lightweight module for managing SCCM resources and collections that relies on CIM cmdlets and is compatible with PowerShell 6.0

Purpose:
* Get-WMIObject is deprecated and isn't currently in PowerShell 6.0, show how to use CIM cmdlets (wmi 2.0)
* Provide a faster, lightweight alternative to the Microsoft SCCM module
* Allow more complex WQL filtering than is offered by the SCCM module

Design Standards:
* When possible, return a cmdlet's default output type. Return cim instances and classes, and avoid custom object types
	* All output should work with built-in CIM functionality - Get-CimInstance, Set-CimInstance, Remove-CimInstance, Invoke-CimMethod should work with output
* Use format and type files to manipulate output without changing object types

### Primary Functions:
- Add-CCMMembershipDirect
- Connect-CCM
- Get-CCMCimClass
- Get-CCMCimInstance
- Get-CCMClientExecutionRequest
- Get-CCMCollection
- Get-CCMCollectionMember
- Get-CCMCollectionSettings
- Get-CCMResource
- Get-CCMResourceMembership
- Get-CCMScript
- Get-CCMScriptExecutionStatus
- Get-CCMUserMachineRelationship
- Invoke-CCMCollectionRefresh
- New-CCMCollection

### SupportFunctions
- Add-CCMClassType
- Get-NthWeekDay (Get-PatchTuesday)
