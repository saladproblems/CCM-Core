Function Get-CCMObjectContainerItem {

    [Alias('Get-SMS_ObjectContainerItem', 'Get-CCMFolderChildItem','gcmfci')]
    [cmdletbinding(DefaultParameterSetName = 'none')]

    param(
        #Specifies a container by ContainerNodeID or SMS_ObjectContainerItem.
        [Parameter(ValueFromPipeline, Position = 0, ParameterSetName = 'Identity')]
        [string[]]$Identity,

        #Specifies a where clause to use as a filter. Specify the clause in either the WQL or the CQL query language.
        [Parameter(Mandatory = $true, ParameterSetName = 'Filter')]
        [string]$Filter,

        #Specifies a set of instance properties to retrieve.
        [Parameter()]
        [string[]]$Property
    )

    Begin {
        $cimHash = $Global:CCMConnection.PSObject.Copy()

        $cimHash['ClassName'] = 'SMS_ObjectContainerItem'
        $cimHash['KeyOnly'] = $true
    }

    Process {
        Write-Debug "Chose ParameterSet $($PSCmdlet.ParameterSetName)"
        $result = Switch -Regex ($PSCmdlet.ParameterSetName) {
            'none' {
                Get-CimInstance @cimHash
            }
            'Identity' {
                switch -Regex ($Identity) {
                    '^SMS_ObjectContainerNode'{
                        Get-CimInstance  @cimHash -Filter ($PSItem -replace '^.+?\s')
                        continue
                    }
                    '^(\d|\*)+$' {
                        Get-CimInstance @cimHash -Filter ('ContainerNodeID LIKE "{0}"' -f $PSItem -replace '\*', '%' )
                    }
                    default {
                        $PSItem | Write-Warning
                    }
                }
            }
            'Filter' {
                Get-CimInstance @cimHash -Filter $Filter
            }
        }

        if ($result){
            $resultParm = @{
                CimSession = $cimHash.CimSession
                NameSpace = $cimHash.NameSpace
                ClassName = ($result | Select-Object -first 1).ObjectTypeName -replace '^([^_]*_[^_]*).*$','$1'
            }

            #this will fail on types with multiple keys, may need to add support if any of these types can be in a folder
            $resultKey = (Get-CimClass @resultParm).CimClassProperties |
                Where-Object {$PSItem.Qualifiers.Name -eq 'key' -or $PSItem.Name -match 'uniqueid$'} |
                    Select-Object -ExpandProperty Name -First 1

            $resultFilter = '({0} LIKE "{1}%")' #testing to see if this gets applications - they have a "/<version>" suffix

            if ($Property) {
                $resultParm['Property'] = $Property
            }
            foreach ($a_result in $result){
                Get-CimInstance @resultParm -Filter ($resultFilter -f $resultKey,$a_result.InstanceKey)
            }
        }
        else{
            Write-Verbose "No childitems found in '$Identity'"
        }
    }
    End
    {}
}