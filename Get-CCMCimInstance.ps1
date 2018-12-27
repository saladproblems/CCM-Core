Function Get-CCMCimInstance {   
    [Alias('Get-CCMInstance')]
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [Alias('Class')]
        [string]$ClassName,

        [Parameter()]
        [string]$Filter,

        [Parameter(Position = 1)]
        [Alias('Properties')]
        [string[]]$Property
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
        Get-CimInstance @cimHash @PSBoundParameters
    }
}