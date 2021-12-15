function Get-CCMResourceMissingUpdate {
    <#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.PARAMETER All
   Query which updates are missing from a resource based on sms_updatecompliancestatus

.NOTES
   General notes

#>

    [cmdletbinding()]

    param(
        [parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [alias('ComputerName', 'Name', 'ResourceId')]
        [object]$InputObject,

        [parameter()]
        [switch]$All
    )

    begin {

        if (-not $All.IsPresent) {
            $isDeployed = 'AND sms_softwareupdate.isdeployed = 1'
        }

        $query = @'
Select * 
FROM SMS_SoftwareUpdate
Where isdeployed = 1
AND ArticleID in (
    Select ArticleID From sms_updatecompliancestatus
    WHERE status in (0,2)
    AND MachineID in (
        SELECT ResourceID from SMS_R_System
        WHERE ResourceID LIKE "{0}" or Name LIKE "{0}"
    )
)
ORDER By LocalizedDisplayName
    
'@ -f $isDeployed
    }


    process {
        $resourceInfo = switch ($InputObject) {
            { $PSItem.CimClass.CimSuperClassName -eq 'SMS_Resource' } {
                'sms_r_system.ResourceId = {0}' -f $PSItem.ResourceId
                break
            }
            { $PSItem -is [string] -or $PSItem -is [int] } {
                'sms_r_system.ResourceId = "{0}" OR sms_r_system.Name = "{0}"' -f $PSItem
            }

            default {
                'unexpected input type: {0}' -f $PSItem.GetType().Fullname
            }
        }
        Get-CCMCimInstance -Query ($query -f $resourceInfo)
    }

}