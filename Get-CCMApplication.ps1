Function Get-CCMApplication {
    [Alias('Get-SMS_Application')]
    [cmdletbinding(DefaultParameterSetName = 'inputObject')]

    param(
        #Specifies an SCCM Application object by providing the CI_ID, CI_UniqueID, or 'LocalizedDisplayName'.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Identity')]
        [Alias('CI_ID', 'CI_UniqueID', 'Name', 'LocalizedDisplayName')]
        [String[]]$Identity,

        #Specifies a CIM instance object to use as input.
        [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'inputObject')]
        [ciminstance]$inputObject,

        #Specifies a where clause to use as a filter. Specify the clause in either the WQL or the CQL query language.
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

        $cimHash['ClassName'] = 'SMS_ApplicationLatest'

        $identityFilter = 'LocalizedDisplayName LIKE "{0}" OR CI_UniqueID LIKE "{0}"'
    }

    Process {
        Write-Debug "Choosing parameterset: '$($PSCmdlet.ParameterSetName)'"
        Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                switch -Regex ($Identity -replace '\*','%') {
                    '^(\d|%)+$' {
                        Get-CimInstance @cimHash -Filter ('CI_ID LIKE "{0}"' -f $PSItem)
                    }
                    default {
                        Get-CimInstance @cimHash -filter ($identityFilter -f $PSItem)
                    }
                }
            }
            'inputObject' {
                $inputObject | Get-CimInstance
            }
            'Filter' {
                Foreach ($obj in $Filter) {
                    Get-CimInstance @cimHash -filter $Filter
                }
            }
        }

    }
}