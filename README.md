# CCM-Core
A lightweight module for managing SCCM resources and collections that relies on CIM cmdlets and is compatible with PowerShell 6.0

Purpose:

* Get-WMIObject is deprecated and isn't currently in PowerShell 6.0, show how to use CIM cmdlets (wmi 2.0)
* Provide a faster, lightweight alternative to the Microsoft SCCM module
* Allow more complex WQL filtering than is offered by the SCCM module
* There are over 4,000 cim classes in the CCM namespace and over 500 methods. The module should help users discover and use these by returning native, re-usable cim instances instead of custom classes and PSObjects

Design Standards:

* When possible, return a cmdlet's default output type. Return cim instances and classes and avoid custom object types
* Use format and type files to manipulate output without changing object types
