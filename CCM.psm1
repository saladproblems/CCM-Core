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
#helper function for adding typenames
<#
    some objects with lazy properties use Microsoft.Management.Infrastructure.CimInstance#__PartialCIMInstance
    this will add the full object classname to the top of PSObject.TypeNames
#>
Filter Add-CCMClassType { $PSItem.PSObject.TypeNames.Insert(0,"Microsoft.Management.Infrastructure.CimInstance#$($PSItem.CimClass.CimClassName)");$PSItem }
Function Add-CCMCollectionMembershipRules {
  [cmdletbinding()]

  param(
    [Parameter(Mandatory)]
    #[ValidateScript({$PSItem.CimSystemProperties.ClassName -eq 'SMS_CollectionRule'})]
    [CimInstance[]]$MembershipRules,

    [Parameter(Mandatory)]
    [ValidateScript({$PSItem.CimSystemProperties.ClassName -match 'SMS_Collection'})]
    [CimInstance]$Collection
  )
  Begin {
    $CimSession = Get-CimSession -InstanceId $Collection.GetCimSessionInstanceId()
    $cimHash = $Global:CCMConnection.PSObject.Copy()
  }

  Process {
    $Collection | Invoke-CimMethod -MethodName AddMemberShipRules -Arguments @{ CollectionRules = [CimInstance[]]$MembershipRules } -ErrorAction Stop
  }

  End {
    $MembershipRules | Out-String | Write-Verbose
  }
}
Function Add-CCMMembershipDirect {
  [cmdletbinding()]

  param(
    [Parameter()]
    [ValidateScript({$PSItem.CimSystemProperties.ClassName -match '^sms_r_(system|user)'})]
    [CimInstance[]]$Resource,

    [Parameter()]
    [CimInstance]$Collection
  )

  Begin {
    $CimSession = Get-CimSession -InstanceId $Collection.GetCimSessionInstanceId()
    $cimHash = $Global:CCMConnection.PSObject.Copy()
  }

  Process {

    ForEach ($obj in $Resource) {
      $null = New-CimInstance -Namespace $cimHash.Namespace -ErrorAction Stop -OutVariable +cmRule -ClassName SMS_CollectionRuleDirect -ClientOnly -Property @{
        ResourceClassName = $obj.CimSystemProperties.ClassName
        RuleName          = '{0} added by {1} via {2} from {3} on {4}' -f $obj.Name, $env:USERNAME, $PSCmdlet.MyInvocation.InvocationName, $CimSession.ComputerName.ToUpper(), (Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt')
        ResourceID        = $obj.ResourceID
      }
    }

  }

  End {
    Add-CCMCollectionMembershipRules -Collection $Collection -MembershipRules $cmRule
  }

}
<# Testing with this was unsuccessful, keeping in module for reference

    Function Add-CCMMembershipQuery
    {
    [cmdletbinding(SupportsShouldProcess=$true)]

    param(

    #[CimSession]$CimSession,

    [String[]]$ResourceName,

    [Parameter(Mandatory=$true)]
    $Collection,

    [DateTime]$ExpriationDate = (Get-Date).AddDays(-1),
    [CimSession]$CimSession = (Get-CimSession -Name 'ccm-*' | Select-Object -First 1)

    )

    Begin
    {

    $cimHash = $Global:CCMConnection.PSObject.Copy()

    $QueryExpression = @'
    select
    SMS_R_SYSTEM.ResourceID,
    SMS_R_SYSTEM.ResourceType,
    SMS_R_SYSTEM.Name,
    SMS_R_SYSTEM.SMSUniqueIdentifier,
    SMS_R_SYSTEM.ResourceDomainORWorkgroup,
    SMS_R_SYSTEM.Client from SMS_R_System

    inner join SMS_G_System_SYSTEM on SMS_G_System_SYSTEM.ResourceID = SMS_R_System.ResourceId

    where
    SMS_G_System_SYSTEM.Name = "{0}"

    and
    (DateDiff(hh, SMS_R_System.CreationDate, GetDate()) < 12)

    '@

    }

    Process
    {

    ForEach ($obj in $ResourceName)
    {

    $null = New-CimInstance -Namespace $cimHash.Namespace -OutVariable +cmRule -ClassName SMS_CollectionRuleQuery -ClientOnly -Property @{
    RuleName = 'RBBuilds| {0} | {1} added by {2}' -f $ExprirationDate, $obj, $env:USERNAME, $PSCmdlet.MyInvocation.InvocationName, $CimSession.ComputerName.ToUpper(), (Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt')
    QueryExpression = $QueryExpression -f $ResourceName
    }

    }

    }

    End
    {
    #$cmRule
    #$SmsCollection
    $Collection | Invoke-CimMethod -MethodName AddMembershipRules -Arguments @{ CollectionRules = [CimInstance[]]$cmRule }
    }

    }

#>
<# for possible future use and conversion to class based module
    class ccmResourceTransform:System.Management.Automation.ArgumentTransformationAttribute {    
    [object] Transform([System.Management.Automation.EngineIntrinsics]$engineIntrinsics, [object]$object) {        
    $output = switch ($object) {
    { $PSItem -is [Microsoft.Management.Infrastructure.CimInstance] } {
    switch -Regex ($object.CimClass.CimClassName) {
    'SMS_R_System' {
    Get-CimInstance -InputObject $object                     
    }
    }
    }
    { $PSItem -is [string] } {                
    switch -Regex ($PSItem) {                    
    '^(%|\d).+$' {
    Get-CimInstance -ClassName SMS_R_System -Filter ('ResourceID LIKE "{0}"' -f $PSItem -replace '\*', '%') @global:CCMConnection 
    }
    default {
    Get-CimInstance -ClassName SMS_R_System -Filter ('Name LIKE "{0}"' -f $PSItem -replace '\*', '%') @global:CCMConnection 
    }
    }
    }
    }                    
    return $output
    }
    }
#>
Function Add-CCMMembershipCollection {
  [cmdletbinding()]

  param(
    [Parameter(Mandatory)]
    [ValidateScript({$PSItem.CimSystemProperties.ClassName -match 'SMS_Collection'})]
    [CimInstance[]]$MemberCollection,

    [Parameter(Mandatory)]
    [ValidateScript({$PSItem.CimSystemProperties.ClassName -match 'SMS_Collection'})]
    [CimInstance]$ParentCollection,
    
    [Parameter()]
    [ValidateSet('Include','Exclude')]
    [String]$MembershipType = 'Include'
  )

  Begin {
    $CimSession = Get-CimSession -InstanceId $ParentCollection.GetCimSessionInstanceId()
    $cimHash = $Global:CCMConnection.PSObject.Copy()
  }

  Process {

    ForEach ($obj in $MemberCollection) {
      $null = New-CimInstance -Namespace $cimHash.Namespace -ErrorAction Stop -OutVariable +cmRule -ClassName "SMS_CollectionRule$($MembershipType)Collection" -ClientOnly -Property @{
        RuleName          = $obj.Name
        "$($MembershipType)CollectionID"        = $obj.CollectionID
      }
    }

  }

  End {
    Add-CCMCollectionMembershipRules -Collection $ParentCollection -MembershipRules $cmRule
  }

}

function Connect-CCM {
  <#
      .SYNOPSIS
      This function establishes a connection to an SCCM Server system.

      .DESCRIPTION
      This function establishes a connection to an SCCM Server system. The function creates
      a CIM session [CimSession], queries the server for the SCCM site and namespace, and
      stores connection information in a global variable

      .INPUTS
      [string]

      .OUTPUTS
      [CimInstance]

      .EXAMPLE
      C:\PS>Connect-CCM -Server WINSCCM01

      Connects to the SCCM server WINSCCM01
  #>
  [CmdletBinding()]
  Param
  (
    #The name of the SCCM server
    [Parameter(Mandatory = $true)]
    [string]$ComputerName,

    #Removes previous CimSession if found
    [Parameter()]
    [switch]$Reconnect,

    #Specifies a PSCredential object that contains credentials for authenticating with the server
    [Parameter()]
    [System.Management.Automation.PSCredential]
    $Credential
  )

  process {
    Write-Verbose "Looking for CIM Session 'ccmConnection'"
    $cimSession = Get-CimSession -Name "ccmConnection" -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($Reconnect) {
      $cimSession | Remove-CimSession
    }

    $siteParm = @{
      ClassName = 'SMS_ProviderLocation'
      NameSpace = 'root/sms'
    }

    $siteName = try {
      (Get-CimInstance @siteParm -CimSession $cimSession)[0].NamespacePath -replace '^.+site_'
    }
    catch {
      $cimSession = New-CimSession -ComputerName $ComputerName -Name "ccmConnection" -Credential $Credential
      (Get-CimInstance @siteParm -CimSession $cimSession)[0].NamespacePath -replace '^.+site_'
    }
  }
  end {
    Set-Variable -Name global:CCMConnection -Value @{
      CimSession = $cimSession
      NameSpace  = 'root\sms\site_{0}' -f $siteName
    }
  }

}
<#
    placeholder for converting hardware inventory queries to readable format
#>
Function Find-CCMObject {
  [Alias()]
  [cmdletbinding()]

  param(
    #Specifies a CIM instance object to use as input.
    [Parameter(ValueFromPipeline, Mandatory)]
    [ciminstance[]]$inputObject
  )

  Begin {
    try {
      $cimHash = $Global:CCMConnection.PSObject.Copy()
    }
    catch {
      Throw 'Not connected to CCM, reconnect using Connect-CCM'
    }

    $cimHash['ClassName'] = 'SMS_ObjectContainerItem'
  }

  Process {
    foreach ($a_inputObject in $inputObject){
      if ($a_inputObject.CimClass.CimClassName -ne 'SMS_ObjectContainerNode'){
        $keyProperty = $a_inputObject.CimClass.CimClassProperties.Where({$_.Qualifiers.Name -eq 'key' -or $_.Name -match 'uniqueid$'}) |
        Sort-Object { $PSItem.name -match 'uniqueid'} |
        Select-Object -Last 1
        $findParm = @{
          #the uniqueID for the app includes version number, but the container location does not
          Filter =  '(InstanceKey = "{0}")' -f ($a_inputObject.($keyProperty.Name) -replace '/\d{1,5}$')
        }

        $containerItem = Get-CimInstance @cimHash @findParm
        $currentContainerNode = Get-CCMObjectContainerNode -Identity $containerItem.ContainerNodeID
      }
      else{
        $currentContainerNode = $a_inputObject
      }

      $sb = [System.Text.StringBuilder]::new()
      $null = $sb.Append("\$($currentContainerNode.Name)")

      while($currentContainerNode.ParentContainerNodeID){
        Write-Verbose $sb.ToString()
        $currentContainerNode = Get-CCMObjectContainerNode -Identity $currentContainerNode.ParentContainerNodeID
        $null = $sb.Insert(0,"\$($currentContainerNode.Name)")
      }
      $sb.ToString()
    }
  }
}
Function Get-CCMApplication {
  [Alias('Get-SMS_Application')]
  [cmdletbinding(DefaultParameterSetName = 'inputObject')]

  param(
    #Specifies an SCCM Application object by providing the CI_ID, CI_UniqueID, or 'LocalizedDisplayName'.
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Identity')]
    [Alias('CI_ID', 'CI_UniqueID', 'Name', 'LocalizedDisplayName')]
    [String[]]$Identity,

    #Specifies a CIM instance object to use as input.
    [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'inputObject')]
    [ciminstance]$inputObject,

    #Specifies a where clause to use as a filter. Specify the clause in either the WQL or the CQL query language.
    [Parameter(ParameterSetName = 'Filter')]
    [string]$Filter
  )

  Begin {
    try {
      $cimHash = $Global:CCMConnection.PSObject.Copy()
    }
    catch {
      Throw 'Not connected to CCM, reconnect using Connect-CCM'
    }

    $cimHash['ClassName'] = 'SMS_ApplicationLatest'

    $identityFilter = 'LocalizedDisplayName LIKE "{0}" OR CI_UniqueID LIKE "{0}"'
  }

  Process {
    Write-Debug "Choosing parameterset: '$($PSCmdlet.ParameterSetName)'"
    Switch ($PSCmdlet.ParameterSetName) {
      'Identity' {
        switch -Regex ($Identity -replace '\*','%') {
          '^(\d|%)+$' {
            Get-CimInstance @cimHash -Filter ('CI_ID LIKE "{0}"' -f $PSItem)
          }
          default {
            Get-CimInstance @cimHash -filter ($identityFilter -f $PSItem)
          }
        }
      }
      'inputObject' {
        $inputObject | Get-CimInstance
      }
      'Filter' {
        Foreach ($obj in $Filter) {
          Get-CimInstance @cimHash -filter $Filter
        }
      }
    }

  }
}
Function Get-CCMCimClass {
  [Alias('Get-CCMClass')]
  [cmdletbinding()]
  param(
    [Parameter(Mandatory, Position = 0)]
    [Alias('Class')]
    [string]$ClassName
  )

  Begin {
    try {
      $cimHash = $Global:CCMConnection.PSObject.Copy()
    }
    catch {
      Throw 'Not connected to CCM, reconnect using Connect-CCM'
    }
  }

  Process {
    Get-CimClass @cimHash @PSBoundParameters
  }
}
Function Get-CCMCimInstance {
  [Alias('Get-CCMInstance')]
  [cmdletbinding()]
  param(
    [Parameter(Mandatory, Position = 0,ParameterSetName='Class')]
    [Alias('Class')]
    [string]$ClassName,

    [Parameter(ParameterSetName='Class')]
    [string]$Filter,

    [Parameter(ParameterSetName='Query')]
    [string]$Query,

    [Parameter(Position = 1)]
    [Alias('Properties')]
    [string[]]$Property
  )

  Begin {
    try {
      $cimHash = $Global:CCMConnection.PSObject.Copy()
    }
    catch {
      Throw 'Not connected to CCM, reconnect using Connect-CCM'
    }
  }

  Process {
    Get-CimInstance @cimHash @PSBoundParameters
  }
}
function Get-CCMCimInstanceByResourceName {
  <#
      .SYNOPSIS

      Searches for a resource by resource ID or name

      .DESCRIPTION

      Searches for a resource by resource ID or name, meant to be a helper function for finding hardware inventory information. This function outputs PS Objects with a the resource record and each additional class as properties with the same name.

      .EXAMPLE
      C:\PS> Find-CCMRecordByResource -Identity ComputerName1, ComputerName2 -ClassName SMS_G_System_NETWORK_ADAPTER, SMS_G_System_PC_BIOS
      Returns PSObjects for each client computer which have the properties SMS_R_System, SMS_G_System_NETWORK_ADAPTE, and SMS_G_System_PC_BIOS

      .EXAMPLE
      C:\PS> Get-CCMCimClass *computer*system*

      CimClassName                        CimClassMethods      CimClassProperties
      ------------                        ---------------      ------------------
      SMS_G_System_COMPUTER_SYSTEM_PRODU… {}                   {ResourceID, GroupID, RevisionID, TimeStamp…}
      SMS_G_System_COMPUTER_SYSTEM        {}                   {ResourceID, GroupID, RevisionID, TimeStamp…}
      SMS_G_System_DEVICE_COMPUTERSYSTEM  {}                   {ResourceID, GroupID, RevisionID, TimeStamp…}

      C:\PS> Find-CCMRecordByResource -Identity Computer1 -ClassName SMS_G_System_COMPUTER_SYSTEM | Select-Object -ExpandProperty SMS_G_System_COMPUTER_SYSTEM | Select *last*

      Win32_OperatingSystem contains a computer's last start time, use Get-CCMCimClass to find the correct SMS class, and then use Find-CCMRecordByResource to view the last boot time for the resource

      .LINK

      https://github.com/saladproblems/CCM-Core

      .NOTES
      Please help me rename this function, having a hard time coming up with a meaningful one - message mcdonough.david@gmail.com or go to the github project site

  #>
  [cmdletbinding()]

  param(
    [parameter(mandatory)]
    [string[]]$ClassName,

    [parameter(valuefrompipeline,ValueFromPipelineByPropertyName)]
    [alias('ResourceId')]
    [string[]]$Identity       
  )

  begin {

    $sb = [System.Text.StringBuilder]::new()

    $null = $sb.AppendLine( 'SELECT * FROM SMS_R_System' )

    $ClassName | ForEach-Object {
      $null = $sb.AppendLine( "INNER JOIN $PSItem ON $PSItem.ResourceId = SMS_R_System.ResourceId" )
    }
    $null = $sb.AppendLine( 'WHERE SMS_R_System.Name LIKE "{0}" OR SMS_R_System.ResourceID LIKE "{0}"' )
  }

  process {
    foreach ($a_Identity in $Identity) {
      Get-CCMCimInstance -Query ( $sb.ToString() -f $a_Identity ) -Verbose
    }
  }
}
Function Get-CCMCollection {

  <#
      .SYNOPSIS

      Get an SCCM Collection

      .DESCRIPTION

      Get an SCCM Collection by Name or CollectionID

      .PARAMETER Name
      Specifies the file name.

      .PARAMETER Extension
      Specifies the extension. "Txt" is the default.

      .INPUTS

      None. You cannot pipe objects to Add-Extension.

      .OUTPUTS

      System.String. Add-Extension returns a string with the extension
      or file name.

      .EXAMPLE
      C:\PS> Get-CCMCollection *
      Retrieves all collections

      .EXAMPLE
      C:\PS> Get-CCMCollection *SVR*
      Returns all collections with SVR in the name

      .EXAMPLE
      C:\PS> Get-CCMCollection *SVR* -HasMaintenanceWindow
      Returns all collections with SVR in the name that have maintenance windows

      .LINK

      https://github.com/saladproblems/CCM-Core

  #>
  [Alias('Get-SMS_Collection')]
  [cmdletbinding(DefaultParameterSetName = 'inputObject')]

  param(
    #Specifies a CIM instance object to use as input.
    [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject')]
    [ciminstance[]]$InputObject,

    #Specifies an SCCM collection object by providing the collection name or ID.
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Identity')]
    [Alias('ClientName', 'CollectionName', 'CollectionID', 'Name')]
    [string[]]$Identity = '*',

    #Specifies a where clause to use as a filter. Specify the clause in the WQL query language.
    [Parameter(Mandatory, ParameterSetName = 'Filter')]
    [string]$Filter,

    #Only return collections with service windows - Maintenance windows are a lazy property, requery to view maintenance window info
    [Parameter()]
    [Parameter(ParameterSetName = 'Identity')]
    [alias('HasServiceWindow')]
    [switch]$HasMaintenanceWindow,

    #Specifies a set of instance properties to retrieve.
    [Parameter()]
    [string[]]$Property

  )

  Begin {
    $cimHash = $Global:CCMConnection.PSObject.Copy()

    if ($Property) {
      $cimHash['Property'] = $Property
    }

    if ($HasMaintenanceWindow.IsPresent) {
      $HasMaintenanceWindowSuffix = ' AND (ServiceWindowsCount > 0)'
    }
  }

  Process {
    Write-Debug "Chose parameterset '$($PSCmdlet.ParameterSetName)'"
    Switch ($PSCmdlet.ParameterSetName) {
      'Identity' {
        $cimFilter = switch -Regex ($Identity) {
          '\*' {
            'Name LIKE "{0}" OR CollectionID LIKE "{0}"' -f ($PSItem -replace '\*', '%')
          }

          Default {
            'Name = "{0}" OR CollectionID = "{0}"' -f $PSItem
          }
        }
      }
      'Filter' {
        Get-CimInstance @cimHash -ClassName SMS_Collection -Filter $Filter
      }
      'InputObject' {
        switch ($InputObject) {
          {$PSItem.CimInstance.cimclass -match 'SMS_ObjectContainerItem'} {
            'CollectionID = "{0}"' -f $PSItem.CollectionID
          }
        }
      }
    }

    if ($cimFilter) {
      $cimFilter = '({0}){1} ORDER BY Name' -f ($cimFilter -join ' OR '), $HasMaintenanceWindowSuffix
      Get-CimInstance @cimHash -ClassName SMS_Collection -Filter $cimFilter
    }
  }
  End
  {}
}
Function Get-CCMCollectionMember {

  [cmdletbinding()]
  param(
    #Specifies an SCCM Resource object by providing the 'Name' or 'ResourceID'.
    [Parameter(ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Identity')]
    [Alias('CollectionName','CollectionID')]
    [WildcardPattern]$Identity,

    #Specifies a CIM instance object to use as input.
    [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'inputObject')]
    [ciminstance[]]$inputObject,

    #Specifies a where clause to use as a filter. Specify the clause in either the WQL or the CQL query language.
    [Parameter(ParameterSetName = 'Filter')]
    [string]$Filter
  )

  Begin
  {
    try {
      $cimHash = $Global:CCMConnection.PSObject.Copy()
    }
    catch {
      Throw 'Not connected to CCM, reconnect using Connect-CCM'
    }
    #$cimHash['ClassName'] = 'SMS_FullCollectionMembership'

    $identityFilter = 'CollectionID LIKE "{0}" OR Name LIKE "{0}"'

    $collParm = @{
      KeyOnly = $true
      ClassName = 'SMS_Collection'
    }
  }

  Process {
    Write-Debug $PSCmdlet.ParameterSetName
    Switch ($PSCmdlet.ParameterSetName) {
      'Identity' {
        foreach($collection in (Get-CimInstance @cimHash @collParm -filter ($identityFilter -f $Identity.ToWql()) )) {
          Get-CimInstance @cimHash -ClassName SMS_FullCollectionMembership -Filter ($identityFilter -f $collection.CollectionID)
        }
      }
      'inputObject' {
        foreach ($a_inputObject in $inputObject) {
          Get-CimInstance @cimHash -ClassName SMS_FullCollectionMembership -Filter "CollectionID = '$($a_inputObject.CollectionID)'"
        }
      }
      'Filter' {
        Get-CimInstance @cimHash -filter $Filter
      }
    }
  }
}
Function Get-CCMCollectionSettings {
  [cmdletbinding()]

  param(
    [ValidateScript( {$PSItem.CimClass.CimClassName -eq 'SMS_Collection'})]
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Name')]
    [CimInstance]$Collection
  )

  Begin
  {}

  Process {
    foreach ($a_Collection in $Collection) {
      $cimHash = @{
        NameSpace  = $a_Collection.CimSystemProperties.Namespace
        CimSession = Get-CimSession -InstanceId $a_Collection.GetCimSessionInstanceId()
      }

      Get-CimInstance @cimHash -ClassName SMS_CollectionSettings -Filter "CollectionID = '$($a_Collection.CollectionID)'" | Get-CimInstance
    }

  }

}
Function Get-CCMObjectContainerItem {

  [Alias('Get-SMS_ObjectContainerItem', 'Get-CCMFolderChildItem','gcmfci')]
  [cmdletbinding(DefaultParameterSetName = 'none')]

  param(
    #Specifies a container by ContainerNodeID or SMS_ObjectContainerItem.
    [Parameter(ValueFromPipeline, Position = 0, ParameterSetName = 'Identity')]
    [string[]]$Identity,

    #Specifies a where clause to use as a filter. Specify the clause in either the WQL or the CQL query language.
    [Parameter(Mandatory = $true, ParameterSetName = 'Filter')]
    [string]$Filter,

    #Specifies a set of instance properties to retrieve.
    [Parameter()]
    [string[]]$Property
  )

  Begin {
    $cimHash = $Global:CCMConnection.PSObject.Copy()

    $cimHash['ClassName'] = 'SMS_ObjectContainerItem'
    $cimHash['KeyOnly'] = $true
  }

  Process {
    Write-Debug "Chose ParameterSet $($PSCmdlet.ParameterSetName)"
    $result = Switch -Regex ($PSCmdlet.ParameterSetName) {
      'none' {
        Get-CimInstance @cimHash
      }
      'Identity' {
        switch -Regex ($Identity) {
          '^SMS_ObjectContainerNode'{
            Get-CimInstance  @cimHash -Filter ($PSItem -replace '^.+?\s')
            continue
          }
          '^(\d|\*)+$' {
            Get-CimInstance @cimHash -Filter ('ContainerNodeID LIKE "{0}"' -f $PSItem -replace '\*', '%' )
          }
          default {
            $PSItem | Write-Warning
          }
        }
      }
      'Filter' {
        Get-CimInstance @cimHash -Filter $Filter
      }
    }

    if ($result){
      $resultParm = @{
        CimSession = $cimHash.CimSession
        NameSpace = $cimHash.NameSpace
        ClassName = ($result | Select-Object -first 1).ObjectTypeName -replace '^([^_]*_[^_]*).*$','$1'
      }

      #this will fail on types with multiple keys, may need to add support if any of these types can be in a folder
      $resultKey = (Get-CimClass @resultParm).CimClassProperties |
      Where-Object {$PSItem.Qualifiers.Name -eq 'key' -or $PSItem.Name -match 'uniqueid$'} |
      Select-Object -ExpandProperty Name -First 1

      $resultFilter = '({0} LIKE "{1}%")' #testing to see if this gets applications - they have a "/<version>" suffix

      if ($Property) {
        $resultParm['Property'] = $Property
      }
      foreach ($a_result in $result){
        Get-CimInstance @resultParm -Filter ($resultFilter -f $resultKey,$a_result.InstanceKey)
      }
    }
    else{
      Write-Verbose "No childitems found in '$Identity'"
    }
  }
  End
  {}
}
Function Get-CCMObjectContainerNode {

  [Alias('Get-SMS_ObjectContainerNode', 'Get-CCMFolder','Get-ObjectContainerNode')]
  [cmdletbinding(DefaultParameterSetName = 'Identity')]

  param(
    #Specifies a container by ContainerNodeID, FolderGuid, or Name
    [Parameter(Mandatory, ValueFromPipeline, Position = 0, ParameterSetName = 'Identity')]
    [string[]]$Identity,

    #Specifies a where clause to use as a filter. Specify the clause in either the WQL or the CQL query language.
    [Parameter(Mandatory = $true, ParameterSetName = 'Filter')]
    [string]$Filter,

    #Specifies a set of instance properties to retrieve.
    [Parameter()]
    [string[]]$Property,

    [Parameter(ValueFromPipeline, ParameterSetName = 'CimInstance')]
    [ciminstance[]]$CimInstance
  )

  Begin {
    $cimHash = $Global:CCMConnection.PSObject.Copy()

    $cimHash['ClassName'] = 'SMS_ObjectContainerNode'

    if ($Property) {
      $cimHash['Property'] = $Property
    }
  }

  Process {
    Write-Debug "Chose ParameterSet $($PSCmdlet.ParameterSetName)"
    Switch -Regex ($PSCmdlet.ParameterSetName) {
      'none' {
        Get-CimInstance @cimHash
      }
      'Identity' {
        switch -Regex ($Identity) {
          '^(%|\d).+$' {
            Get-CimInstance @cimHash -Filter ('ContainerNodeID LIKE "{0}"' -f ($PSItem -replace '\*', '%' ))
          }
          default {
            Get-CimInstance @cimHash -Filter ('FolderGuid LIKE "{0}" OR Name LIKE "{0}"' -f ($PSItem -replace '\*', '%' ))
          }
        }
      }
      'Filter' {
        Get-CimInstance @cimHash -Filter $Filter
      }
      'CimInstance' {
        switch ($CimInstance)
        {
          {$PSItem.CimClass.CimClassName -eq 'SMS_ObjectContainerNode'} {
            $CimInstance | Get-CimInstance
            continue
          }
          {$PSItem.CimClass.CimClassName -eq 'SMS_ObjectContainerItem'} {
            Get-CimInstance @cimHash -Filter ('ContainerNodeID = "{0}"' -f $PSItem.ContainerNodeID)
            continue
          }
          Default {
            <#
                $Filter = switch ($PSItem.)
                Get-CimInstance -CimSession $cimHash.CimSession -Namespace $cimHash.Namespace -ClassName SMS_ObjectContainerItem -Filter ''
            #>
          }
        }

      }
    }
  }
  End
  {}
}
Function Get-CCMResource {
  <#
      .SYNOPSIS

      Get an SCCM Resource

      .DESCRIPTION

      Get an SCCM Resource by Name or ResourceID

      .OUTPUTS
      Microsoft.Management.Infrastructure.CimInstance#root/sms/site_qtc/SMS_R_System

      .EXAMPLE
      C:\PS> Get-CCMResource *
      Retrieves all Resources

      .EXAMPLE
      C:\PS> Get-CCMResource *SVR*
      Returns all resources with SVR in the name

      .LINK

      https://github.com/saladproblems/CCM-Core

  #>
  [Alias('Get-SMS_R_System')]
  [cmdletbinding()]

  param(
    #Specifies an SCCM Resource object by providing the 'Name' or 'ResourceID'.
    [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Identity')]
    [Alias('Name', 'ClientName', 'ResourceName', 'ResourceID', 'InputObject')]
    [object[]]$Identity,

    #Specifies a where clause to use as a filter. Specify the clause in either the WQL or the CQL query language.
    [Parameter(Mandatory, ParameterSetName = 'Filter')]
    [string[]]$Filter,

    [Parameter()]
    [string[]]$Property = '*'
  )

  Begin {
    try {
      $cimHash = $Global:CCMConnection.PSObject.Copy()
    }
    catch {
      Throw 'Not connected to CCM, reconnect using Connect-CCM'
    }
    [string]$propertyString = $Property -replace '^', 'SMS_R_System.' -join ','
  }

  Process {
    Switch ($Identity) {
      { $PSItem -is [string] } {
        Get-CimInstance @cimHash -Query ('SELECT {0} FROM SMS_R_System WHERE ResourceId LIKE "{1}" OR Name LIKE "{1}"' -f $propertyString, ($PSItem -replace '\*', '%'))                   
      }
      { $PSItem -is [ciminstance] } {
        switch ($PSItem) {
          {$PSItem.CimSystemProperties.ClassName -eq 'SMS_R_System'} {
            Get-CimInstance -InputObject $PSItem
          }
          {$PSItem.CimSystemProperties.ClassName -eq 'SMS_Collection'} {
            Get-CimInstance @cimHash -Query ('SELECT {0} FROM SMS_R_System INNER JOIN SMS_FullCollectionMembership ON SMS_R_System.ResourceId = SMS_FullCollectionMembership.ResourceId WHERE CollectionId = "{1}"' -f $propertyString, $PSItem.CollectionId)
          }
          default {
            $PSItem.CimSystemProperties.ClassName
          }
        }
      }
    }
    if ($Filter) {        
      $Filter | ForEach-Object {
        Get-CimInstance @cimHash -Query ("SELECT {0} FROM SMS_R_System WHERE {1}" -f $propertyString, $PSItem)
      }
    }
  }
}
Function Get-CCMResourceMembership {
  [Alias('Get-SMS_FullCollectionMembership')]
  [cmdletbinding(DefaultParameterSetName = 'inputObject')]

  param(
    #Specifies the members an SCCM resource is a member of by the resource's name or ID.
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Identity')]
    [Alias('ClientName', 'ResourceName', 'ResourceID', 'Name')]
    [string[]]$Identity,

    #Specifies a CIM instance object to use as input, must be SMS_R_System (returned by "get-CCMResource")
    [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'inputObject')]
    [ValidateScript( {$PSItem.CimClass.CimClassName -match 'SMS_R_System|SMS_FullCollectionMembership'})]
    [ciminstance]$inputObject,

    #Restrict results to only collections with a ServiceWindow count greater than 0
    [Parameter()]
    [alias('HasServiceWinow')]
    [switch]$HasMaintenanceWindow,

    #Specifies a set of instance properties to retrieve.
    [Parameter()]
    [string[]]$Property = @('Name','collectionid','lastchangetime','limittocollectionid','limittocollectionname'),

    # Parameter help description
    [Parameter()]
    [switch]$ShowResourceName
  )

  Begin {
    $cimHash = $Global:CCMConnection.PSObject.Copy()

    $cimHash['ClassName'] = 'SMS_FullCollectionMembership'

    $query = @'
        SELECT {0}
        FROM   sms_collection
               INNER JOIN sms_fullcollectionmembership
                       ON sms_collection.collectionid =
                          sms_fullcollectionmembership.collectionid
        WHERE  sms_fullcollectionmembership.resourceid = {1} AND
            sms_collection.servicewindowscount > {2}
        ORDER BY Name,CollectionID
'@

    $getCollParm = @{ HasMaintenanceWindow = $HasMaintenanceWindow.IsPresent }

    if ($Property) {
      $getCollParm['Property'] = $Property
    }
  }

  Process {
    Write-Debug "Choosing parameterset: '$($PSCmdlet.ParameterSetName)'"
    $resourceList = Switch ($PSCmdlet.ParameterSetName) {
      'Identity' {
        Get-CCMResource $Identity
      }
      'inputObject' {
        Get-CCMResource -inputObject $inputObject
      }
    }
    $resourceList | ForEach-Object {
      $ccmParam = @{
        Query = $query -f ($Property -join ','),$PSItem.ResourceID,($HasMaintenanceWindow.IsPresent -1)
      }
      $collection = Get-CimInstance @global:CCMConnection @ccmParam
      if($ShowResourceName.IsPresent) {
        Write-Host $PSItem.Name -ForegroundColor Green
      }
      Write-Output $collection
    }
  }
}
Function Get-CCMScript {

  [cmdletbinding(DefaultParameterSetName = 'inputObject')]

  param(
    #Specifies a CIM instance object to use as input.
    [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject')]
    [ciminstance[]]$InputObject,

    #Specifies an SCCM collection object by providing the collection name or ID.
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Identity')]
    [Alias('ScriptGUID', 'ScriptName')]
    [string[]]$Identity,

    [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Author')]
    [string[]]$Author,

    [Parameter(ParameterSetName = 'Filter')]
    [string]$Filter
  )

  Begin {
    try {
      $cimHash = $Global:CCMConnection.PSObject.Copy()
    }
    catch {
      Throw 'Not connected to CCM, reconnect using Connect-CCM'
    }
    $cimHash['ClassName'] = 'SMS_Scripts'
  }

  Process {
    Write-Debug $PSCmdlet.ParameterSetName
    Switch ($PSCmdlet.ParameterSetName) {
      'inputObject' {
        $inputObject | Get-CimInstance
      }
      'Identity' {
        Foreach ($obj in $Identity) {
          Get-CimInstance @cimHash -Filter ('ScriptName LIKE "{0}" OR ScriptGUID LIKE "{0}"' -f $obj -replace '\*', '%' -replace '\[', '[$0]' )
        }
      }
      'Author' {
        Foreach ($obj in $Author) {
          Get-CimInstance @cimHash -Filter "Author LIKE '$($obj -replace '\*','%')'"
        }
      }
      'Filter' {
        Foreach ($obj in $Filter) {
          Get-CimInstance @cimHash -Filter $Filter
        }
      }
    }
  }
}
Function Get-CCMScriptExecutionStatus {
  [cmdletbinding()]

  [alias('Get-CCMScriptsExecutionStatus')]

  param(
    [Parameter(ValueFromPipeline = $true)]
    [ciminstance[]]
    $Script,

    [Parameter()]
    [datetime]
    $Start,

    [Parameter()]
    [datetime]
    $End

  )

  begin {
    try {
      [hashtable]$cimHash = $Global:CCMConnection.PSObject.Copy()
    }
    catch {
      Throw 'Not connected to CCM, reconnect using Connect-CCM'
    }

    $cimHash['ClassName'] = 'SMS_ScriptsExecutionStatus'

    $cimArray = [System.Collections.ArrayList]::new()
  }

  process {
    $cimArray.AddRange([ciminstance[]]$Script)
  }

  end {
    $filter = $cimArray.ForEach( { 'ScriptGUID = "{0}"' -f $PSItem.ScriptGuid }) -join ' OR '

    Get-CimInstance @cimHash -Filter $filter
  }
}
Function Get-CCMSoftwareUpdate {

  [Alias()]
  [cmdletbinding(DefaultParameterSetName = 'inputObject')]

  param(
    #Specifies an SCCM Resource object by providing the 'Name' or 'ResourceID'.
    [Parameter(ValueFromPipeline, Position = 0, ParameterSetName = 'Identity')]
    [Alias('Name','CI_ID')]
    [string[]]$Identity='*',

    #Specifies a CIM instance object to use as input.
    [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'inputObject')]
    [ciminstance]$inputObject,

    #Specifies a where clause to use as a filter. Specify the clause in either the WQL or the CQL query language.
    [Parameter(ParameterSetName = 'Filter')]
    [string]$Filter,

    [Parameter()]
    [string[]]$Property = @('ArticleID','BulletinID','LocalizedDescription','LocalizedDisplayName','LocalizedCategoryInstanceNames')
  )

  Begin {
    try {
      $cimHash = $Global:CCMConnection.PSObject.Copy()
    }
    catch {
      Throw 'Not connected to CCM, reconnect using Connect-CCM'
    }
    $cimHash['ClassName'] = 'SMS_SoftwareUpdate'
  }

  Process {
    Switch ($PSCmdlet.ParameterSetName) {
      'Identity' {
        foreach ($obj in $Identity) {
          Get-CimInstance @cimHash -Filter ('ArticleID LIKE "{0}" OR LocalizedDisplayName LIKE "{0}"' -f $obj -replace '\*','%')
        }
      }
      'inputObject' {
        switch -Regex ($inputObject.CimClass.CimClassName) {
          'SMS_G_System_QUICK_FIX_ENGINEERING' {
            $cimHash['Property'] = $Property
            Get-CimInstance @cimHash -Filter ('articleID = "{0}"' -f ($inputObject.HotFixID -replace '[^0-9]'))
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
Function Get-CCMSoftwareUpdateGroup {
  <#
      .SYNOPSIS

      Gets an SCCM 'Software Update Group' (sug/SMS_AuthorizationList)

      .DESCRIPTION

      Gets an SCCM 'Software Update Group' (sug/SMS_AuthorizationList) by Name or CI_ID

      .OUTPUTS
      Microsoft.Management.Infrastructure.CimInstance#root/sms/site_qtc/SMS_AuthorizationList

      .EXAMPLE
      C:\PS> Get-CCMSoftwareUpdateGroup *
      Retrieves all software update groups

      .EXAMPLE
      C:\PS> Get-CCMSoftwareUpdateGroup ADR*
      Returns all resources whose  start with ADR

      .LINK

      https://github.com/saladproblems/CCM-Core

  #>
  [Alias('Get-SMS_AuthorizationList','Get-CCMSUG')]
  [cmdletbinding(DefaultParameterSetName = 'inputObject')]

  param(
    #Specifies an SCCM Resource object by providing the 'Name' or 'ResourceID'.
    [Parameter(ValueFromPipeline, Position = 0, ParameterSetName = 'Identity')]
    [Alias('Name','CI_ID')]
    [string[]]$Identity='*',

    #Specifies a CIM instance object to use as input.
    [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'inputObject')]
    [ciminstance]$inputObject,

    #Specifies a where clause to use as a filter. Specify the clause in either the WQL or the CQL query language.
    [Parameter(ParameterSetName = 'Filter')]
    [string]$Filter
  )

  Begin {
    try {
      $cimHash = $Global:CCMConnection.PSObject.Copy()
    }
    catch {
      Throw 'Not connected to CCM, reconnect using Connect-CCM'
    }
    $cimHash['ClassName'] = 'SMS_AuthorizationList'
  }

  Process {
    Switch ($PSCmdlet.ParameterSetName) {
      'Identity' {
        foreach ($obj in $Identity) {
          Get-CimInstance @cimHash -Filter ('LocalizedDisplayName LIKE "{0}" OR ci_id LIKE "{0}"' -f $obj -replace '\*','%')
        }
      }
      'inputObject' {
        $inputObject | Get-CimInstance
      }
      'Filter' {
        foreach ($obj in $Filter) {
          Get-CimInstance @cimHash -filter $obj
        }
      }
    }

  }
}
Function Get-CCMUserMachineRelationship {
  [alias('Get-SMS_UserMachineRelationship', 'Get-CCMClientUserRelationship')]
  [cmdletbinding()]

  param(
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Identity')]
    [alias('Name')]
    [string[]]$Identity,

    [Parameter(ParameterSetName = 'Filter')]
    [string]$Filter,

    [Parameter()]
    [alias('Active')]
    [switch]$IsActive
  )

  Begin {
    try {
      $cimHash = $Global:CCMConnection.PSObject.Copy()
      $cimHash['ClassName'] = 'SMS_UserMachineRelationship'
    }
    catch {
      Throw 'Not connected to CCM, reconnect using Connect-CCM'
    }        
  }

  Process {
    Switch ($PSCmdlet.ParameterSetName) {
      'Identity' {
        Foreach ($obj in $Identity) {
          Write-Verbose $obj
          $filter = 'ResourceName LIKE "{0}" OR UniqueUserName LIKE "{0}"' -f ($obj -replace '\*', '%' -replace '\\+', '\\')
          if ($null -ne $PSBoundParameters.IsActive) {
            $Filter = $Filter -replace '$', (' AND IsActive = {0}' -f [int]$IsActive.IsPresent)
          }

          Get-CimInstance @cimHash -filter $Filter

          $PSBoundParameters | Out-String | Write-Host
        }
        continue
      }
      'Filter' {
        Get-CimInstance @cimHash -filter $Filter
      }
    }
  }
}
Function Get-NthWeekDay {
  [cmdletbinding()]
  [alias('Get-PatchTuesday')]
  param(
    [parameter()]
    [ccm.Month]$Month = (Get-Date -Format 'MM'),

    [parameter()]
    [int]$Year = (Get-Date -Format 'yyyy'),

    [Parameter()]
    [int]$Nth = 2,

    [Parameter()]
    [DayOfWeek]$DayOfWeek = [DayOfWeek]::Tuesday
  )

  begin {
    $FirstDayOfMonth = ([datetime]"$Month/1/$Year").Date
    $daysInMonth = [datetime]::DaysInMonth($Year,$Month)
  }
  process {

    $foundDays = 1..$daysInMonth |
    ForEach-Object { $FirstDayOfMonth.AddDays($PSItem - 1) } |
    Where-Object { $PSItem.DayOfWeek -eq $DayOfWeek }

    try {
      $foundDays[($Nth - 1)]
    }
    catch {
      Write-Error -ErrorAction Stop -Message "Did not find '$Nth'th '$DayOfWeek' in '$Month', '$Year'"
    }
  }
}
Function Invoke-CCMCollectionRefresh {

  [cmdletbinding()]

  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    [CimInstance[]]$Collection,
    [switch]$Wait
  )

  Begin {}

  Process {
    foreach ($obj in $Collection) {
      $time = $obj.LastRefreshTime

      $null = $obj | Invoke-CimMethod -MethodName RequestRefresh

      '{0}: Collection "{1}" updated {2}' -f $MyInvocation.InvocationName, $obj.name, $obj.LastRefreshTime | Write-Verbose

      $obj = $obj | Get-CimInstance

      $x = $null

      While ( $Wait -and $obj.LastRefreshTime -eq $time -and $x -le 6000 ) {

        $x++
        Write-Progress -Activity 'Waiting for Collection Refresh' -Status "Collection $($obj.Name)"
        if ( ($x % 30) -eq 0 ) {
          '{0}: waiting for "{1}", {2} seconds elapsed' -f $MyInvocation.InvocationName, $obj.Name, $x |
          Write-Verbose
        }

        Start-Sleep -Seconds 1
        $obj = $obj | Get-CimInstance
      }

      '{0}: Collection "{1}" updated {2}' -f $MyInvocation.InvocationName, $obj.name, $obj.LastRefreshTime |
      Write-Verbose

      $obj

    }
  }

}
Function New-CCMCollection
{
  [cmdletbinding()]
  [Alias('New-SMS_Collection')]

  param(
    [Parameter(Mandatory)]
    [Alias('CollectionName')]
    [string]$Name,

    [ccm.CollectionType]$CollectionType,

    [Parameter(Mandatory,ParameterSetName='CollectionID')]
    [string]$LimitToCollectionID,

    [Parameter(Mandatory,ParameterSetName='Collection')]
    [ValidateScript({$PSItem.CimClass.CimClassName -eq 'SMS_Collection'})]
    [ciminstance]$LimitToCollection
  )

  Begin
  {
    $cimHash = $sbCCMGetCimParm.InvokeReturnAsIs()
  }

  Process
  {
    $newCollectionProperty = @{
      Name = $Name
      CollectionType = [int]$CollectionType
      LimitToCollectionID = $LimitToCollectionID
    }
    if ($LimitToCollection)
    {
      $newCollectionProperty['LimitToCollectionID'] = $LimitToCollection.CollectionID
    }

    $newCollectionProperty | Out-String | Write-Verbose

    New-CimInstance -OutVariable newCollection @cimHash -ClassName SMS_Collection -Property $newCollectionProperty
  }
}
Function Remove-CCMMembershipRules {
  # Including alias 'Remove-CCMMembershipDirect' to support scripts using previous module versions
  [Alias('Remove-CCMMembershipDirect')]
  [cmdletbinding(SupportsShouldProcess, ConfirmImpact = 'High')]

  param(
    [Parameter(Mandatory,ParameterSetName='Identity')]
    [Alias('MemberCollection','UserName','Name','Resource')]
    #[ValidateScript({$PSItem.CimSystemProperties.ClassName -match '^sms_(r_(system|user)|collection)'})]
    [String[]]$Identity,

    [Parameter(Mandatory)]
    [ValidateScript({$PSItem.CimSystemProperties.ClassName -eq 'sms_collection'})]
    [CimInstance]$Collection,
    
    [Parameter(ParameterSetName='All')]
    [Switch]$All = $false
  )

  Begin {
    #Variables
    [String[]]$Result = @()
  }
  
  Process {
    Write-Debug "Choosing parameterset: '$($PSCmdlet.ParameterSetName)'"
    Switch ($PSCmdlet.ParameterSetName) {
      'Identity' {
        switch -Regex ($Identity) {
          
          # If a Resource CimInstance is passed, let's filter out the ResourceId
          '^SMS_r_(system|user) \(ResourceId = (?<ResourceId>\d+)\)$'{
            $null = $Identity -match '\(ResourceId = (?<ResourceId>\d+)\)'
            $Result += $Matches.ResourceID
            #Get-CCMResourceMembership -Identity $Result |
            #Where-Object {$PSItem.CollectionID -eq $Collection.CollectionID}
          }
          
          # Anything else should be a name or Resource ID as a string
          default {
            $Result += (Get-CCMResource -Identity $Identity).ResourceID
            #Get-CCMResourceMembership -Identity $Identity |
            #Where-Object {$PSItem.CollectionID -eq $Collection.CollectionID}
          }
        }
        [ciminstance[]]$collRule = Get-CimInstance -InputObject $Collection |
        Select-Object -ExpandProperty CollectionRules |
        Where-Object {
          ( $PSItem.CimClass.CimClassName -eq 'SMS_CollectionRuleDirect' -and $PSItem.ResourceID -in $Result)
          # Next line is to support CollectionRules
          #-or ( $PSItem.CimClass.CimClassName -match 'SMS_CollectionRule(Include|Exclude)Collection' -and $PSItem.IncludeCollectionID -in $Matches.ResourceID )
        }
        
      }
      'All' {
        [ciminstance[]]$collRule = Get-CimInstance -InputObject $Collection |
        Select-Object -ExpandProperty CollectionRules
      }
    }

    if (-not $collRule) { continue }

    If ($PSCmdlet.ShouldProcess("$($Collection.Name): $($collRule.RuleName -join ',')")) {
      Invoke-CimMethod -InputObject $Collection -MethodName DeleteMembershipRules -Arguments @{ collectionRules = $collRule }
    }
  }
}
#null
