function Get-CCMUpdatesAssignment {
    [Alias('Get-SoftwareUpdateDeployment', 'Get-SMS_UpdatesAssignment', 'Get-CCMUpdateDeployment')]
    [cmdletbinding()]
    
    param(
        [parameter(mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [alias('AssignmentID', 'AssignmentName', 'Name')]
        [object[]]$Identity
    )
    begin {
        $cimHash = Copy-CCMConnection
        $cimHash['ClassName'] = 'SMS_UpdatesAssignment'
        $filterTemplate = 'AssignmentID LIKE "{0}" OR AssignmentName LIKE "{0}" OR AssignmentDescription LIKE "{0}"'
    }
    process {
        Switch ($Identity) {
            { $PSItem -is [string] -or $PSItem -is [int] } {
                Get-CimInstance @cimHash -Filter ($filterTemplate -f $Identity -replace '\*', '%')            
            }
            { $PSItem -is [ciminstance] } {
                switch ($PSItem) {
                    { $PSItem.CimSystemProperties.ClassName -eq 'SMS_Collection' } {
                        Get-CimInstance -ClassName $cimHash.ClassName -Filter "TargetCollectionID = '$PSItem.CollectionID'"
                    }
                    { $PSItem.CimSystemProperties.ClassName -eq 'SMS_R_System' } {
                        Get-CimInstance -ClassName $cimHash.ClassName -Filter "TargetCollectionID IN (Select CollectionID from sms_fullcollectionmembership Where ResourceID = $($PSItem.ResourceID))"
                    }
                }
            }
            default {
                Write-Error ('Did not recognize Identity: {0}{1}' -f $Identity, $Identity.GetType())
            }
        }
    }

}