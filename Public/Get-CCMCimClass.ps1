Function Get-CCMCimClass {
    [Alias('Get-CCMClass')]
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [Alias('Class')]
        [string]$ClassName
    )

    Begin {
        try {
            $cimHash = $Global:CCMConnection.PSObject.Copy()
        }
        catch {
            Throw 'Not connected to CCM, reconnect using Connect-CCM'
        }
    }

    Process {
        Get-CimClass @cimHash @PSBoundParameters
    }
}