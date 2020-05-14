function Get-CCMBoundaryGroup {
    [cmdletbinding()]
    
    param(
        [parameter(mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [alias('BoundaryGroupIDs')]
        [object[]]$Identity
    )
    begin {
        $cimHash = Copy-CCMConnection
        $cimHash['ClassName'] = 'SMS_BoundaryGroup'
        $filterTemplate = 'GroupGUID LIKE "{0}" OR GroupID LIKE "{0}" OR Name LIKE "{0}"'
    }
    process {
        Switch ($Identity) {
            { $PSItem -is [string] -or $PSItem -is [int] } {
                Get-CimInstance @cimHash -Filter ($filterTemplate -f $Identity -replace '\*', '%')            
            }
            { $PSItem -is [ciminstance] } {
                switch ($PSItem) {
                    <# add support for piping ccmclient cache object ROOT/ccm/LocationServices:BoundaryGroupCache
                    { $PSItem.CimSystemProperties.ClassName } {
                        Get-CimInstance @cimHash -Filter "groupid=$($psitem)"
                    }
                    #>
                    { $PSItem.CimSystemProperties.ClassName -eq 'SMS_BoundaryGroup' } {
                        Get-CimInstance -InputObject $PSItem
                    }
                }
            }
            default {
                Write-Error ('Did not recognize Identity: {0}{1}' -f $Identity, $Identity.GetType())
            }
        }
    }

}