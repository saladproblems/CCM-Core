Function Invoke-CCMCollectionRefresh {

    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [CimInstance[]]$Collection,
        [switch]$Wait
    )

    Begin {}

    Process {
        foreach ($obj in $Collection) {
            $time = $obj.LastRefreshTime

            $null = $obj | Invoke-CimMethod -MethodName RequestRefresh

            '{0}: Collection "{1}" updated {2}' -f $MyInvocation.InvocationName, $obj.name, $obj.LastRefreshTime | Write-Verbose

            $obj = $obj | Get-CimInstance

            $x = $null

            While ( $Wait -and $obj.LastRefreshTime -eq $time -and $x -le 6000 ) {

                $x++
                Write-Progress -Activity 'Waiting for Collection Refresh' -Status "Collection $($obj.Name)"
                if ( ($x % 30) -eq 0 ) {
                    '{0}: waiting for "{1}", {2} seconds elapsed' -f $MyInvocation.InvocationName, $obj.Name, $x |
                        Write-Verbose
                }

                Start-Sleep -Seconds 1
                $obj = $obj | Get-CimInstance
            }

            '{0}: Collection "{1}" updated {2}' -f $MyInvocation.InvocationName, $obj.name, $obj.LastRefreshTime |
                Write-Verbose

            $obj

        }
    }

}