Function Get-CCMSoftwareUpdate {

    [Alias()]
    [cmdletbinding(DefaultParameterSetName = 'inputObject')]

    param(
        #Specifies an SCCM Resource object by providing the 'Name' or 'ResourceID'.
        [Parameter(ValueFromPipeline, Position = 0, ParameterSetName = 'Identity')]
        [Alias('Name','CI_ID')]
        [string[]]$Identity='*',

        #Specifies a CIM instance object to use as input.
        [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'inputObject')]
        [ciminstance]$inputObject,

        #Specifies a where clause to use as a filter. Specify the clause in either the WQL or the CQL query language.
        [Parameter(ParameterSetName = 'Filter')]
        [string]$Filter,

        [Parameter()]
        [string[]]$Property = @('ArticleID','BulletinID','LocalizedDescription','LocalizedDisplayName','LocalizedCategoryInstanceNames')
    )

    Begin {
        try {
            $cimHash = $Global:CCMConnection.PSObject.Copy()
        }
        catch {
            Throw 'Not connected to CCM, reconnect using Connect-CCM'
        }
        $cimHash['ClassName'] = 'SMS_SoftwareUpdate'
    }

    Process {
        Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($obj in $Identity) {
                    Get-CimInstance @cimHash -Filter ('ArticleID LIKE "{0}" OR LocalizedDisplayName LIKE "{0}"' -f $obj -replace '\*','%')
                }
            }
            'inputObject' {
                switch -Regex ($inputObject.CimClass.CimClassName) {
                    'SMS_G_System_QUICK_FIX_ENGINEERING' {
                        $cimHash['Property'] = $Property
                        Get-CimInstance @cimHash -Filter ('articleID = "{0}"' -f ($inputObject.HotFixID -replace '[^0-9]'))
                    }
                }
            }
            'Filter' {
                foreach ($obj in $Filter) {
                    Get-CimInstance @cimHash -filter $obj
                }
            }
        }

    }
}