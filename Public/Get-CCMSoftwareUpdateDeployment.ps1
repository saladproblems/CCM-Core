Function Get-CCMSoftwareUpdateDeployment {
    [alias('Get-SMS_UpdatesAssignment')]
    [cmdletbinding()]

    param(
        [parameter(ValueFromPipeline)]
        [object]$InputObject = '*'
    )

    Begin {
        $cimHash = Copy-CCMConnection
        #SMS_UpdatesAssignment
    }

    Process {
        $query = switch ($InputObject) {
            { $PSItem -is [string] } {
                'select * from SMS_UpdatesAssignment Where AssignmentName LIKE "{0}" OR AssignmentID LIKE "{0}" OR TargetCollectionID LIKE "{0}"' -f
                ($InputObject -replace '\*', '%')
            }
            { $PSItem -is [ciminstance] } {
                switch ($PSItem){
                    { $PSItem.CimClass.CimClassName -eq 'SMS_Collection' }{
                        'select * from SMS_UpdatesAssignment Where TargetCollectionID = "{0}"' -f $PSItem.CollectionId
                    }
                }
            }
        }
        $query | ForEach-Object {
            Get-CimInstance @cimHash -Query $PSItem
        }
    }

}