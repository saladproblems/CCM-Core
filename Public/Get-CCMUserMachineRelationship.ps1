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
                    $filter = 'ResourceName LIKE "{0}" OR UniqueUserName LIKE "{0}"' -f ($obj -replace '\*', '%' -replace '\\+', '\\')
                    if ($null -ne $PSBoundParameters.IsActive) {
                        $Filter = $Filter -replace '$', (' AND IsActive = {0}' -f [int]$IsActive.IsPresent)
                    }

                    Get-CimInstance @cimHash -filter $Filter

                    $PSBoundParameters | Out-String | Write-Host
                }
                continue
            }
            'Filter' {
                Get-CimInstance @cimHash -filter $Filter
            }
        }
    }
}