Function Get-CCMCollectionMember {

    [cmdletbinding()]
    param(
        #Specifies an SCCM Resource object by providing the 'Name' or 'ResourceID'.
        [Parameter(ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Identity')]
        [Alias('CollectionName','CollectionID')]
        [WildcardPattern]$Identity,

        #Specifies a CIM instance object to use as input.
        [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'inputObject')]
        [ciminstance[]]$inputObject,

        #Specifies a where clause to use as a filter. Specify the clause in either the WQL or the CQL query language.
        [Parameter(ParameterSetName = 'Filter')]
        [string]$Filter
    )

    Begin
    {
        try {
            $cimHash = $Global:CCMConnection.PSObject.Copy()
        }
        catch {
            Throw 'Not connected to CCM, reconnect using Connect-CCM'
        }
        #$cimHash['ClassName'] = 'SMS_FullCollectionMembership'

        $identityFilter = 'CollectionID LIKE "{0}" OR Name LIKE "{0}"'

        $collParm = @{
            KeyOnly = $true
            ClassName = 'SMS_Collection'
        }
    }

    Process {
        Write-Debug $PSCmdlet.ParameterSetName
        Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach($collection in (Get-CimInstance @cimHash @collParm -filter ($identityFilter -f $Identity.ToWql()) )) {
                    Get-CimInstance @cimHash -ClassName SMS_FullCollectionMembership -Filter ($identityFilter -f $collection.CollectionID)
                }
            }
            'inputObject' {
                foreach ($a_inputObject in $inputObject) {
                    Get-CimInstance @cimHash -ClassName SMS_FullCollectionMembership -Filter "CollectionID = '$($a_inputObject.CollectionID)'"
                }
            }
            'Filter' {
                Get-CimInstance @cimHash -filter $Filter
            }
        }
    }
}