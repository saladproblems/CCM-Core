Function Get-CCMSoftwareUpdate {

    [Alias()]
    [cmdletbinding(DefaultParameterSetName = 'identity')]

    param(
        #Specifies an SCCM Resource object by providing the 'Name' or 'ResourceID'.
        [Parameter(ValueFromPipeline, Position = 0, ParameterSetName = 'Identity')]
        [Alias('Name', 'CI_ID')]
        [string[]]$Identity,

        #Specifies a CIM instance object to use as input.
        [Parameter(ValueFromPipeline, ParameterSetName = 'inputObject')]
        [ValidateCimClass('SMS_G_System_QUICK_FIX_ENGINEERING,SMS_UpdatesAssignment')]
        [ciminstance]$inputObject,

        #Specifies a where clause to use as a filter. Specify the clause in either the WQL or the CQL query language.
        [Parameter(ParameterSetName = 'Filter')]
        [string]$Filter,

        [Parameter()]
        [string[]]$Property
    )

    Begin {
        try {
            $cimHash = $Global:CCMConnection.PSObject.Copy()
            if ($property) { 
                $cimHash['Property'] = $Property
            }
        }
        catch {
            Throw 'Not connected to CCM, reconnect using Connect-CCM'
        }
        $cimHash['ClassName'] = 'SMS_SoftwareUpdate'
    }

    Process {
        $PSCmdlet.ParameterSetName | Write-Verbose
        Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                #replace "*"" with % so users can use wildcard "*"
                foreach ($obj in ($Identity -replace '^$','%' -replace '\*','%')) {
                    #articleID doesn't include "KB", remove if found
                    Get-CimInstance @cimHash -Filter ('ArticleID LIKE "{0}" OR LocalizedDisplayName LIKE "{1}"' -f ($obj -replace '^kb'),$obj)
                }
            }
            'inputObject' {
                switch -Regex ($inputObject.CimClass.CimClassName) {
                    'SMS_G_System_QUICK_FIX_ENGINEERING' {
                        Get-CimInstance @cimHash -Filter ('articleID = "{0}"' -f ($inputObject.HotFixID -replace '[^0-9]'))
                    }
                    'SMS_UpdatesAssignment' {
                        Get-CimInstance @cimHash -Filter ('ci_id in ({0})' -f ($inputObject.AssignedCIs -join ',') )
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