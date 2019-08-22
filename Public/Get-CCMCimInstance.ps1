Function Get-CCMCimInstance {
    [Alias('Get-CCMInstance')]
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, Position = 0,ParameterSetName='Class')]
        [Alias('Class')]
        [string]$ClassName,

        [Parameter(ParameterSetName='Class')]
        [string]$Filter,

        [Parameter(ParameterSetName='Query')]
        [string]$Query,

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