<#
.SYNOPSIS
    Copies CCM connection variable
.DESCRIPTION
    Copies CCM connection variable, so that CCM functions don't update the orginal variable. Hashtables are references in memory, so it's necessary to use the copy method to create a new object in case functions modify it
#>

function Copy-CCMConnection {
    [cmdletbinding()]
    param()

    process {
        try {
            $Global:CCMConnection.PSObject.Copy()
        }
        catch {
            Throw 'Not connected to CCM, reconnect using Connect-CCM'
        }
    }
}