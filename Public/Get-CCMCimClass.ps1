Function Get-CCMCimClass {
    [Alias('Get-CCMClass')]
    [cmdletbinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Class')]
        [string]$ClassName,

        [Parameter(Position = 1)]
        [string]$PropertyName,

        [Parameter(Position = 2)]
        [string]$MethodName

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