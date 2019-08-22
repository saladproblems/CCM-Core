$sbCCMGetCimParm = {
    try {
        $Global:CCMConnection.PSObject.Copy()
    }
    catch {
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
}
catch {}
#end region Force confirm prompt

#using Add-Type instead of Enum because I want to group by namespace
Add-Type -ErrorAction SilentlyContinue -TypeDefinition @'
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
     public enum FolderType
     {
          TYPE_PACKAGE = 2,
          TYPE_ADVERTISEMENT = 3,
          TYPE_QUERY = 7,
          TYPE_REPORT = 8,
          TYPE_METEREDPRODUCTRULE = 9,
          TYPE_CONFIGURATIONITEM = 11,
          TYPE_OSINSTALLPACKAGE = 14,
          TYPE_STATEMIGRATION = 17,
          TYPE_IMAGEPACKAGE = 18,
          TYPE_BOOTIMAGEPACKAGE = 19,
          TYPE_TASKSEQUENCEPACKAGE = 20,
          TYPE_DEVICESETTINGPACKAGE = 21,
          TYPE_DRIVERPACKAGE = 23,
          TYPE_DRIVER = 25,
          TYPE_SOFTWAREUPDATE = 1011,
          TYPE_CONFIGURATIONBASELINE = 2011
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
     public enum EvalResult {
          Not_Yet_Evaluated = 1,
          Not_Applicable = 2,
          Evaluation_Failed = 3,
          Evaluated_Remediated_Failed = 4,
          Not_Evaluated_Dependency_Failed = 5,
          Evaluated_Remediated_Succeeded = 6,
          Evaluation_Succeeded = 7
     }
     public enum EvaluationState
     {
          None = 0,
          Available = 1,
          Submitted = 2,
          Detecting = 3,
          PreDownload = 4,
          Downloading = 5,
          WaitInstall = 6,
          Installing = 7,
          PendingSoftReboot = 8,
          PendingHardReboot = 9,
          WaitReboot = 10,
          Verifying = 11,
          InstallComplete = 12,
          Error = 13,
          WaitServiceWindow = 14,
          WaitUserLogon = 15,
          WaitUserLogoff = 16,
          WaitJobUserLogon = 17,
          WaitUserReconnect = 18,
          PendingUserLogoff = 19,
          PendingUpdate = 20,
          WaitingRetry = 21,
          WaitPresModeOff = 22,
          WaitForOrchestration = 23
     }
     public enum Recurrence {
          NONE = 1,
          DAILY = 2,
          WEEKLY = 3,
          MONTHLYBYWEEKDAY = 4,
          MONTHLYBYDATE = 5
     }
     public enum DCMEvaluationState {
          NonCompliant = 0,
          Compliant = 1,
          Submitted = 2,
          Unknown = 3,
          Detecting = 4,
          NotEvaluated = 5
     }
}
'@