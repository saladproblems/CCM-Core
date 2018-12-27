Function Get-CCMUserMachineRelationship {
    [alias('Get-SMS_UserMachineRelationship')]
    [cmdletbinding()]

    param(

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Identity')]
        [alias('Name')]
        [string[]]$Identity,

        [Parameter(ParameterSetName = 'Filter')]
        [string]$Filter,
        
        [Parameter()]        
        [switch]$Active
    )

    Begin {
        try {
            $cimHash = $Global:CCMConnection.PSObject.Copy()   
            $cimHash['ClassName'] = 'SMS_UserMachineRelationship'
        }
        catch {
            Throw 'Not connected to CCM, reconnect using Connect-CCM'
        }

        $filterSuffix = if ($Active.IsPresent) {
            'AND (IsActive = {0})' -f [int]($Active.IsPresent)
        }
    } 

    Process {
        Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                Foreach ($obj in $Identity) {
                    Write-Verbose $obj
                    $filter = if ($obj -match '\*') {
                        "ResourceName LIKE '{0}' OR UniqueUserName LIKE '{0}' $filterSuffix" -f ($obj -replace '\*', '%' -replace '\\', '\\')
                    }
                    else {
                        "ResourceName = '{0}' OR UniqueUserName = '{0}' $filterSuffix" -f ($obj -replace '\\', '\\')
                    }
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