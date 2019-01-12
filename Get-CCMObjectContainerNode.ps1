Function Get-CCMObjectContainerNode {

    [Alias('Get-SMS_ObjectContainerNode', 'Get-CCMFolder','Get-ObjectContainerNode')]
    [cmdletbinding(DefaultParameterSetName = 'Identity')]

    param(
        #Specifies a container by ContainerNodeID, FolderGuid, or Name
        [Parameter(Mandatory, ValueFromPipeline, Position = 0, ParameterSetName = 'Identity')]
        [string[]]$Identity,

        #Specifies a where clause to use as a filter. Specify the clause in either the WQL or the CQL query language.
        [Parameter(Mandatory = $true, ParameterSetName = 'Filter')]
        [string]$Filter,

        #Specifies a set of instance properties to retrieve.
        [Parameter()]
        [string[]]$Property,

        [Parameter(ValueFromPipeline, ParameterSetName = 'CimInstance')]
        [ciminstance[]]$CimInstance
    )

    Begin {
        $cimHash = $Global:CCMConnection.PSObject.Copy()

        $cimHash['ClassName'] = 'SMS_ObjectContainerNode'

        if ($Property) {
            $cimHash['Property'] = $Property
        }      
    }

    Process {
        Write-Debug "Chose ParameterSet $($PSCmdlet.ParameterSetName)"
        Switch -Regex ($PSCmdlet.ParameterSetName) {
            'none' {
                Get-CimInstance @cimHash
            }
            'Identity' {
                switch -Regex ($Identity) {
                    '^(%|\d).+$' {
                        Get-CimInstance @cimHash -Filter ('ContainerNodeID LIKE "{0}"' -f ($PSItem -replace '\*', '%' ))
                    }
                    default {                        
                        Get-CimInstance @cimHash -Filter ('FolderGuid LIKE "{0}" OR Name LIKE "{0}"' -f ($PSItem -replace '\*', '%' ))
                    }
                }
            }
            'Filter' {
                Get-CimInstance @cimHash -Filter $Filter
            }
            'CimInstance' {
                switch ($CimInstance)
                {
                    {$PSItem.CimClass.CimClassName -eq 'SMS_ObjectContainerNode'} {
                        $CimInstance | Get-CimInstance
                        continue
                    }
                    {$PSItem.CimClass.CimClassName -eq 'SMS_ObjectContainerItem'} {
                        Get-CimInstance @cimHash -Filter ('ContainerNodeID = "{0}"' -f $PSItem.ContainerNodeID)
                        continue
                    }
                    Default {
                        <#
                        $Filter = switch ($PSItem.)
                        Get-CimInstance -CimSession $cimHash.CimSession -Namespace $cimHash.Namespace -ClassName SMS_ObjectContainerItem -Filter ''
                        #>
                    }
                }

            }
        }
    }
    End
    {}
}