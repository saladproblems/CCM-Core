Function Get-CCMSoftwareUpdateDeployment {
    [alias('Get-SMS_UpdatesAssignment')]
    [cmdletbinding(DefaultParameterSetName = 'Identity')]

    param(
        [parameter(ParameterSetName = 'Identity', position = 0)]
        [string]$Identity = '*',

        [parameter(ValueFromPipeline, ParameterSetName = 'inputObject')]
        [ValidateCimClass('SMS_Collection,SMS_UpdatesAssignment,SMS_SoftwareUpdate,SMS_R_System')]
        [ciminstance[]]$InputObject,

        [parameter(Mandatory, ParameterSetName = 'Filter')]
        [string]$Filter
    )

    Begin {
        $cimHash = Copy-CCMConnection
        
        $classHash = @{ ClassName = 'SMS_UpdatesAssignment' }
  
        $systemQueryTemplate = @'
    select * from SMS_UpdatesAssignment
    where TargetCollectionID IN(
        Select CollectionID from sms_fullcollectionmembership
        where ResourceID = {0}
    )
'@
    }

    Process {
        Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                Get-CimInstance @cimHash @classHash -Filter ('AssignmentName LIKE "{0}" OR AssignmentID LIKE "{0}"' -f ($Identity -replace '^$', '%') -replace '\*', '%')
            }
            
            'inputObject' {
                switch -Regex ($inputObject[0].CimClass.CimClassName) {
                    #requery the object if it's a update assignment
                    'SMS_UpdatesAssignment' {
                        $inputObject | Get-CimInstance
                    }
                    #provide all deployments targeted at a collection
                    'SMS_Collection' {
                        Get-CimInstance @cimHash @classHash -Filter ('TargetCollectionID IN ({0})' -f ($inputObject.CollectionID -replace '^|$', '"' -join ',') )
                    }
                    'SMS_SoftwareUpdate' {
                        Get-CimInstance @cimHash @classHash -Filter ('AssignedCIs IN ({0})' -f ($inputObject.CI_ID -join ','))
                    }
                    'SMS_R_System' {
                        Get-CimInstance @cimHash -Query ($systemQueryTemplate -f ($inputObject.ResourceID))
                    }
                }
            }
            'Filter' {
                foreach ($obj in $Filter) {
                    Get-CimInstance @cimHash @classHash -filter $obj
                }
            }
        }

    }

}