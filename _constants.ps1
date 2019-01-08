$sbCCMGetCimParm = {
    try {
        $Global:CCMConnection.PSObject.Copy()
    } catch {
        Throw 'Not connected to CCM, reconnect using Connect-CCM'
    }
}

#region Force confirm prompt for Remove-CimInstance
<#
 I think this is bad practice, but I don't have a good workaround - Remove-CimInstance can delete any CCM objects
 piped to it. Users can override this, but this will make it a bit harder to accidentally remove collections, resources, etc.
 #>
try {
    $PSDefaultParameterValues.Add("Remove-CimInstance:Confirm", $true)
} catch {}
#end region Force confirm prompt

#using Add-Type instead of Enum because I want to group by namespace
Add-Type -TypeDefinition @'
namespace CCM
{
     public enum Month
     {
          January = 1,
          February = 2,
          March = 3,
          April = 4,
          May = 5,
          June = 6,
          July = 7,
          August = 8,
          September = 9,
          October = 10,
          November = 11,
          December = 12

     }
     public enum RecurrenceType
     {
          NONE = 1,
          DAILY = 2,
          WEEKLY = 3,
          MONTHLYBYWEEKDAY = 4,
          MONTHLYBYDATE = 5
     }

     public enum ServiceWindowType
     {
          GENERAL = 1,
          UPDATES = 4,
          OSD = 5
     }
     public enum CollectionType
     {
          OTHER = 0,
          USER = 1,
          DEVICE = 2
     }
     public enum RefreshType
     {
          Manual = 1,
          Periodi = 2,
          Incremental = 4,
          IncrementalAndPeriodic = 6
     }

}
'@