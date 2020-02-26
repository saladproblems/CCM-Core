#Find resources by collection, for use wth getting clients from multiple collections at once

function Find-CCMClientByCollection {
    [cmdletbinding()]    

    param(
        [CimInstance[]]$Collection
    )
    begin {

        $whereTemplate = @'
ResourceId in (
    Select ResourceId FROM sms_fullcollectionmembership
        WHERE CollectionId = "{0}"
)
'@

        $where = $Collection.ForEach( { $whereTemplate -f $PSItem.CollectionId } ) -join ' AND '

        $query = @'
SELECT * FROM SMS_R_System
INNER JOIN sms_fullcollectionmembership
                ON SMS_R_System.ResourceId =
                    sms_fullcollectionmembership.ResourceId
WHERE  {0}
'@ -f $where
    }

    process {
        Get-CimInstance -Query $query @global:CCMConnection
    }
}