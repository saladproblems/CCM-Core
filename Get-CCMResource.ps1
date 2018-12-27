Function Get-CCMResource {
    [Alias('Get-SMS_R_System')]
    [cmdletbinding()]

    param(

        [Parameter(ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Name')]
        [Alias('ClientName', 'ResourceName')]
        [string[]]$Name,

        [Parameter(ValueFromPipelineByPropertyName = $true, Position = 0, ParameterSetName = 'ResourceID')]
        [int32[]]$ResourceID,

        [Parameter(ParameterSetName = 'Filter')]
        [string]$Filter
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
        Switch ($PSCmdlet.ParameterSetName) {
            'Name' {
                Foreach ($obj in $Name) {
                    if ($obj -match '\*') {
                        Get-CimInstance @cimHash -ClassName SMS_R_System -filter "Name LIKE '$($obj -replace '\*','%')'"
                    }
                    else {
                        Get-CimInstance @cimHash -ClassName SMS_R_System -filter "Name='$obj'"
                    }
                }

            }
            'ResourceID' {
                Foreach ($obj in $ResourceID) {
                    Get-CimInstance @cimHash -ClassName SMS_R_System -filter "ResourceID='$obj'"
                }
            }
            'Filter' {
                Foreach ($obj in $Filter) {
                    Get-CimInstance @cimHash -ClassName SMS_R_System -filter $Filter
                }
            }
        }
           
    }
}