Function Get-CCMUserMachineRelationship {
    [alias('Get-SMS_UserMachineRelationship', 'Get-CCMClientUserRelationship')]
    [cmdletbinding()]

    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Identity')]
        [alias('Name')]
        [string[]]$Identity,

        [Parameter(ParameterSetName = 'Filter')]
        [string]$Filter,

        [Parameter()]
        [alias('Active')]
        [switch]$IsActive
    )

    Begin {
        try {
            $cimHash = $Global:CCMConnection.PSObject.Copy()
            $cimHash['ClassName'] = 'SMS_UserMachineRelationship'
        }
        catch {
            Throw 'Not connected to CCM, reconnect using Connect-CCM'
        }
    }

    Process {
        Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                Foreach ($obj in $Identity) {
                    Write-Verbose $obj
                    $filter = 'ResourceName LIKE "{0}" OR UniqueUserName LIKE "{0}" AND (IsActive = {1})' -f ($obj -replace '\*', '%' -replace '\\+', '\\'), [int]$IsActive.IsPresent

                    Get-CimInstance @cimHash -filter $Filter
                }
                continue
            }
            'Filter' {
                Get-CimInstance @cimHash -filter $Filter
            }
        }
    }
}