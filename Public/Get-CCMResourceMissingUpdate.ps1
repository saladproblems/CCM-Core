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
        [bool]$ExcludeUndeployed = $true
    )

    begin {
        try {
            $cimHash = $Global:CCMConnection.PSObject.Copy()
        }
        catch {
            Throw 'Not connected to CCM, reconnect using Connect-CCM'
        }

        $filterDeployed = if ($ExcludeUndeployed) {
            'AND IsDeployed = 1'
        }

        $query = @'
SELECT *
FROM SMS_SoftwareUpdate
WHERE ArticleID in (
    Select ArticleID From sms_updatecompliancestatus
    WHERE status in (0,2)
    AND MachineID in (
        SELECT ResourceID from SMS_R_System
        WHERE ResourceID LIKE "{0}" or Name LIKE "{0}"
    )
)
{1}

ORDER By LocalizedDisplayName
    
'@
    }


    process {
        $resourceInfo = switch ($InputObject) {
            { $PSItem.CimClass.CimSuperClassName -eq 'SMS_Resource' } {
                $PSItem.ResourceId
                break
            }
            { $PSItem -is [string] -or $PSItem -is [int] } {
                $PSItem
            }

            default {
                'unexpected input type: {0}' -f $PSItem.GetType().Fullname
            }
        }
        $query -f $resourceInfo, $isDeployed | Write-Verbose
        Get-CimInstance @cimHash -Query ($query -f $resourceInfo, $filterDeployed)
    }

}