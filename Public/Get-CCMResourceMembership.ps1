Function Get-CCMResourceMembership {
    [Alias('Get-SMS_FullCollectionMembership')]
    [cmdletbinding()]

    param(
        #Specifies an the members an SCCM resource is a member of by the resource's name or ID.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Identity')]
        [Alias('ClientName', 'ResourceName', 'ResourceID', 'Name')]
        [string[]]$Identity,

        #Specifies a CIM instance object to use as input, must be SMS_R_System (returned by "get-CCMResource")
        [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'inputObject')]
        [ValidateScript( { $PSItem.CimClass.CimClassName -match 'SMS_R_System|SMS_FullCollectionMembership' })]
        [ciminstance]$inputObject,

        #Restrict results to only collections with a ServiceWindow count greater than 0
        [Parameter()]
        [alias('HasServiceWinow')]
        [switch]$HasMaintenanceWindow,

        #Specifies a set of instance properties to retrieve.
        [Parameter()]
        [string[]]$Property = @('Name', 'collectionid', 'lastchangetime', 'limittocollectionid', 'limittocollectionname'),

        # Parameter help description
        [Parameter()]
        [alias('showresourcename')]
        [switch]$IncludeResourceName,

        # working on a better name for this
        [Parameter()]
        [int]$PageSize = 300

    )

    Begin {
        $cimHash = $Global:CCMConnection.PSObject.Copy()
        $query = @'
            SELECT sms_r_system.NAME,
                {0}
            FROM   sms_collection
                INNER JOIN sms_fullcollectionmembership
                        ON sms_collection.collectionid =
                            sms_fullcollectionmembership.collectionid
                INNER JOIN sms_r_system
                        ON sms_r_system.resourceid =
                            sms_fullcollectionmembership.resourceid
            WHERE  sms_fullcollectionmembership.resourceid IN ( {1} )
                AND sms_collection.servicewindowscount >= {2}
            ORDER  BY NAME,
                    collectionid 
'@
        $propertyString = $Property -replace '^', 'sms_collection.' -join ','
    }

    Process {
        Write-Debug "Choosing parameterset: '$($PSCmdlet.ParameterSetName)'"
        $null = Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                Get-CCMResource $Identity -Property ResourceID | Select-Object -ExpandProperty ResourceID -OutVariable +resourceList
            }
            'inputObject' {
                $inputObject | Select-Object -ExpandProperty ResourceID -OutVariable +resourceList
            }
        }
    }

    End {
        $result = Get-CimInstance @cimHash -Query ($query -f $propertyString, ($resourceList -join ','), ([int]$HasMaintenanceWindow.IsPresent))

        foreach ($obj in $result) {
            $output = $obj.SMS_Collection | Add-Member -NotePropertyName ResourceName -NotePropertyValue $obj.sms_r_system.name -PassThru
            if ($IncludeResourceName.IsPresent) {
                $output.psobject.TypeNames.Insert(0, 'SMS_Collection_IncludeResourceName')
            }
            $output
        }
    }
}   