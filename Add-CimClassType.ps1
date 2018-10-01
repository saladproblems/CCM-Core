#helper function for adding typenames
Filter Add-CimClassType { $PSItem.PSObject.TypeNames.Insert(0,"CimInstance.$($PSItem.CimClass.CimClassName)");$PSItem }