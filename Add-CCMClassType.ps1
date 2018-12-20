#helper function for adding typenames
<#
some objects with lazy properties use Microsoft.Management.Infrastructure.CimInstance#__PartialCIMInstance
this will add the full object classname to the top of PSObject.TypeNames
#>
Filter Add-CCMClassType { $PSItem.PSObject.TypeNames.Insert(0,"Microsoft.Management.Infrastructure.CimInstance#$($PSItem.CimClass.CimClassName)");$PSItem }