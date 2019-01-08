Function Get-CCMResourceMembership {
    [Alias('Get-SMS_FullCollectionMembership')]
    [cmdletbinding(DefaultParameterSetName = 'inputObject')]

    param(
        #Specifies an the members an SCCM resource is a member of by the resource's name or ID.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Identity')]
        [Alias('ClientName', 'ResourceName', 'ResourceID', 'Name')]
        [WildcardPattern[]]$Identity,

        #Specifies a CIM instance object to use as input, must be SMS_R_System (returned by "get-CCMResource")
        [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'inputObject')]
        [ValidateScript( {$PSItem.CimClass.CimClassName -eq 'SMS_R_System'})]
        [ciminstance]$inputObject,

        #Restrict results to only collections with a ServiceWindow count greater than 0
        [Parameter()]
        [alias('HasServiceWinow')]
        [switch]$HasMaintenanceWindow,

        #Specifies a set of instance properties to retrieve.
        [Parameter()]
        [string[]]$Property,

        # Parameter help description
        [Parameter()]
        [switch]$ShowResourceName
    )

    Begin {
        $cimHash = $Global:CCMConnection.PSObject.Copy()

        $cimHash['ClassName'] = 'SMS_FullCollectionMembership'

        if ($Property) { $cimHash['Property'] = $Property }

        $getCollParm = @{ HasMaintenanceWindow = $HasMaintenanceWindow.IsPresent }

        if ($Property) {
            $getCollParm['Property'] = $Property
        }
    }

    Process {
        Write-Debug "Choosing parameterset: '$($PSCmdlet.ParameterSetName)'"
        Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                $resourceMembership = switch -Regex ($Identity.ToWql()) {
                    '^(\d|%)+$' {
                        Get-CimInstance @cimHash -Filter ('ResourceID LIKE "{0}"' -f $PSItem)
                    }
                    default {
                        Get-CimInstance @cimHash -filter ('Name LIKE "{0}"' -f $PSItem)
                    }
                }
                if ($ShowResourceName.IsPresent) {
                    Write-Host "Collection memberships for: '$($resourceMembership[0].Name)'" -ForegroundColor Green
                }
                Get-CCMCollection -Identity $resourceMembership.CollectionID @getCollParm
            }
            'inputObject' {
                if ($ShowResourceName.IsPresent) {
                    Write-Host "Collection memberships for '$($inputObject.ResourceID)':" -ForegroundColor Green
                }
                $inputObject.ResourceID | Get-CCMResourceMembership @getCollParm
            }
        }
    }
}