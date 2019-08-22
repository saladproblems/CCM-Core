Function Get-CCMResourceMembership {
    [Alias('Get-SMS_FullCollectionMembership')]
    [cmdletbinding(DefaultParameterSetName = 'inputObject')]

    param(
        #Specifies an the members an SCCM resource is a member of by the resource's name or ID.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Identity')]
        [Alias('ClientName', 'ResourceName', 'ResourceID', 'Name')]
        [string[]]$Identity,

        #Specifies a CIM instance object to use as input, must be SMS_R_System (returned by "get-CCMResource")
        [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'inputObject')]
        [ValidateScript( {$PSItem.CimClass.CimClassName -match 'SMS_R_System|SMS_FullCollectionMembership'})]
        [ciminstance]$inputObject,

        #Restrict results to only collections with a ServiceWindow count greater than 0
        [Parameter()]
        [alias('HasServiceWinow')]
        [switch]$HasMaintenanceWindow,

        #Specifies a set of instance properties to retrieve.
        [Parameter()]
        [string[]]$Property = @('Name','collectionid','lastchangetime','limittocollectionid','limittocollectionname'),

        # Parameter help description
        [Parameter()]
        [switch]$ShowResourceName
    )

    Begin {
        $cimHash = $Global:CCMConnection.PSObject.Copy()

        $cimHash['ClassName'] = 'SMS_FullCollectionMembership'

        $query = @'
        SELECT {0}
        FROM   sms_collection
               INNER JOIN sms_fullcollectionmembership
                       ON sms_collection.collectionid =
                          sms_fullcollectionmembership.collectionid
        WHERE  sms_fullcollectionmembership.resourceid = {1} AND
            sms_collection.servicewindowscount > {2}
        ORDER BY Name,CollectionID
'@

        $getCollParm = @{ HasMaintenanceWindow = $HasMaintenanceWindow.IsPresent }

        if ($Property) {
            $getCollParm['Property'] = $Property
        }
    }

    Process {
        Write-Debug "Choosing parameterset: '$($PSCmdlet.ParameterSetName)'"
        $resourceList = Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                Get-CCMResource $Identity
            }
            'inputObject' {
                Get-CCMResource -inputObject $inputObject
            }
        }
        $resourceList | ForEach-Object {
            $ccmParam = @{
                Query = $query -f ($Property -join ','),$PSItem.ResourceID,($HasMaintenanceWindow.IsPresent -1)
            }
            $collection = Get-CimInstance @global:CCMConnection @ccmParam
            if($ShowResourceName.IsPresent) {
                Write-Host $PSItem.Name -ForegroundColor Green
            }
            Write-Output $collection
        }
    }
}