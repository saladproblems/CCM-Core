Function Get-CCMSoftwareUpdateDeployment {
    [alias('Get-SMS_UpdatesAssignment')]
    [cmdletbinding(DefaultParameterSetName = 'Identity')]

    param(
        [parameter(ParameterSetName = 'Identity', position = 0)]
        [string]$Identity = '*',

        [parameter(ValueFromPipeline, ParameterSetName = 'inputObject')]
        [ValidateCimClass('SMS_Collection,SMS_UpdatesAssignment,SMS_SoftwareUpdate')]
        [ciminstance[]]$InputObject,

        [parameter(Mandatory, ParameterSetName = 'Filter')]
        [string]$Filter
    )

    Begin {
        $cimHash = Copy-CCMConnection
        $cimHash['ClassName'] = 'SMS_UpdatesAssignment'
        #SMS_UpdatesAssignment
    }

    Process {
        Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                Get-CimInstance @cimHash -Filter ('AssignmentName LIKE "{0}" OR AssignmentID LIKE "{0}"' -f ($Identity -replace '^$', '%') -replace '\*', '%')
            }
            
            'inputObject' {
                switch -Regex ($inputObject[0].CimClass.CimClassName) {
                    #requery the object if it's a update assignment
                    'SMS_UpdatesAssignment' {
                        $inputObject | Get-CimInstance
                    }
                    #provide all deployments targeted at a collection
                    'SMS_Collection' {
                        Get-CimInstance @cimHash -Filter ('TargetCollectionID IN ({0})' -f ($inputObject.CollectionID -replace '^|$', '"' -join ',') )
                    }
                    'SMS_SoftwareUpdate' {
                        Get-CimInstance @cimHash -Filter ('AssignedCIs IN ({0})' -f ($inputObject.CI_ID -join ','))
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