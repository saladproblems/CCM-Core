    Write-Verbose "Importing $($MyInvocation.MyCommand.Name )"

#helper function for adding typenames
<#
some objects with lazy properties use Microsoft.Management.Infrastructure.CimInstance#__PartialCIMInstance
this will add the full object classname to the top of PSObject.TypeNames
#>
Filter Add-CCMClassType { $PSItem.PSObject.TypeNames.Insert(0,"Microsoft.Management.Infrastructure.CimInstance#$($PSItem.CimClass.CimClassName)");$PSItem }
Function Add-CCMMembershipDirect {
    [cmdletbinding(SupportsShouldProcess = $true)]

    param(
        [Parameter()]
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
                ResourceClassName = 'SMS_R_System'
                RuleName          = '{0} added by {1} via {2} from {3} on {4}' -f $obj.Name, $env:USERNAME, $PSCmdlet.MyInvocation.InvocationName, $CimSession.ComputerName.ToUpper(), (Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt')
                ResourceID        = $obj.ResourceID
            } 
        } 

    }

    End {        
        $Collection | Invoke-CimMethod -MethodName AddMemberShipRules -Arguments @{ CollectionRules = [CimInstance[]]$cmRule } -ErrorAction Stop

        $cmRule | Out-String | Write-Verbose
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
function Connect-CCM {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter()]
        [switch]$Reconnect,

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
$sbCCMGetCimParm = {
     try {
         $Global:CCMConnection.PSObject.Copy()
     }
     catch {
         Throw 'Not connected to CCM, reconnect using Connect-CCM'
     }
 }
 
 <#
 I think this is bad practice, but I don't have a good workaround - Remove-CimInstance can delete any CCM objects
 piped to it. Users can override this, but this will make it a bit harder to accidentally remove collections, resources, etc.
 #>
 try {
      $PSDefaultParameterValues.Add("Remove-CimInstance:Confirm",$true)
 }
 catch{}

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
        [Parameter(Mandatory, Position = 0)]
        [Alias('Class')]
        [string]$ClassName,

        [Parameter()]
        [string]$Filter,

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
function Get-CCMClientExecutionRequest {
    param (
        
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ComputerName',
            Position = 0,
            Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(ParameterSetName = 'ComputerName')]
        [PSCredential]$Credential 

    )

    Begin
    {}

    Process {
        if (-not $CimSession) {
        
            try {
                $CimSession = Get-CimSession -ComputerName $ComputerName -ErrorAction Stop
            }
            catch {
                
                $cimParm = @{
                    ComputerName = $ComputerName
                }
                if ($Credential) {
                    $cimParm['Credential'] = $Credential
                }

                $CimSession = New-CimSession @cimParm -ErrorAction Stop
            }
            
        }
        
        $cimParm = @{            
            OutVariable = 'update'
            NameSpace   = 'root\ccm\SoftMgmtAgent'
            ClassName   = 'CCM_ExecutionRequestEx'
            CimSession  = $CimSession
        }

        Get-CimInstance @cimParm | ForEach-Object { $PSItem.PSObject.TypeNames.Insert(0, 'Microsoft.Management.Infrastructure.CimInstance.CCM_ExecutionRequestEx') ; $PSItem }
        
    }
}
Function Get-CCMCollection {

    <#
.SYNOPSIS

Get an SCCM Collection

.DESCRIPTION

Get an SCCM Collection by name or CollectionID, or requery a collection to retrieve lazy properties

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

.LINK

https://github.com/saladproblems/CCM-Core

#>
    [Alias('Get-SMS_Collection')]
    [cmdletbinding()]

    param(

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Name')]
        [Alias('ClientName', 'CollectionName')]
        [ValidateCount(1, 500)]
        [string[]]$Name,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1, ParameterSetName = 'CollectionID')]
        [ValidateCount(1, 500)]
        [string[]]$CollectionID,

        [Parameter(Mandatory = $true, ParameterSetName = 'Filter')]
        [string]$Filter,

        [string[]]$Property = @( 'Name', 'CollectionID', 'LastChangeTime', 'LimitToCollectionID', 'LimitToCollectionname', 'MemberCount' )

    )

    Begin {       
        $cimHash = $Global:CCMConnection.PSObject.Copy()

        if ($Property) {
            $cimHash.Property = $Property
        }                
    }

    Process {

        Write-Verbose $PSCmdlet.ParameterSetName

        $cimFilter = Switch ($PSCmdlet.ParameterSetName) {
            'Name' {
                switch -Regex ($Name) {
                    '\*' { 
                        "Name LIKE '$($PSItem -replace '\*','%')'"                        
                    }
                        
                    Default {
                        "Name='$PSItem'"
                    }
                }                
            }

            'CollectionID' {
                Foreach ($obj in $CollectionID) {                   
                    "CollectionID='$obj'"
                }
            }
            'Filter' {
                $Filter
            }

            #Add handling piping in a resource here
        }
        
        Get-CimInstance @cimHash -ClassName SMS_Collection -Filter ($cimFilter -join ' OR ') |
            Add-CCMClassType

    }
    End
    {}
}
Function Get-CCMCollectionMember {    
    
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

            Get-CimInstance @cimHash -ClassName SMS_FullCollectionMembership -Filter "CollectionID = '$($a_Collection.CollectionID)'" | Get-CimInstance
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
<#
Function Get-ObjectContainerNode {

    [Alias('Get-SMS_ObjectContainerNode', 'Get-CCMFolder')]
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Identity')]
        [alias('FolderGUID', 'FolderName', 'Name')]
        [guid[]]$Identity,

        [Parameter(Mandatory = $true, ParameterSetName = 'Filter')]
        [string]$Filter
    )

    Begin {       
        $cimHash = $Global:CCMConnection.PSObject.Copy()

        if ($Property) {
            $cimHash.Property = $Property
        }                
    }

    Process {

        Write-Verbose $PSCmdlet.ParameterSetName

        $cimFilter = Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                switch ($Identity) {
                    { 
                        try {
                            [guid]$Identity
                        }
                        catch {
                            $false
                        }
                    } { 
                        "Name LIKE '$($PSItem -replace '\*','%')'"                        
                    }
                        
                    Default {
                        "Name='$PSItem'"
                    }
                }                
            }

            'CollectionID' {
                Foreach ($obj in $CollectionID) {                   
                    "CollectionID='$obj'"
                }
            }
            'Filter' {
                $Filter
            }

            #Add handling piping in a resource here
        }
        
        Get-CimInstance @cimHash -ClassName SMS_Collection -Filter ($cimFilter -join ' OR ') |
            Add-CCMClassType

    }
    End
    {}
}
#>
Function Get-CCMResource {
    [Alias('Get-SMS_R_System')]
    [cmdletbinding()]

    param(

        [Parameter(ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Name')]
        [Alias('ClientName', 'ResourceName')]
        [string[]]$Name,

        [Parameter(ValueFromPipelineByPropertyName = $true, Position = 0, ParameterSetName = 'ResourceID')]
        [int32[]]$ResourceID,

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
    } 

    Process {
        Switch ($PSCmdlet.ParameterSetName) {
            'Name' {
                Foreach ($obj in $Name) {
                    if ($obj -match '\*') {
                        Get-CimInstance @cimHash -ClassName SMS_R_System -filter "Name LIKE '$($obj -replace '\*','%')'"
                    }
                    else {
                        Get-CimInstance @cimHash -ClassName SMS_R_System -filter "Name='$obj'"
                    }
                }

            }
            'ResourceID' {
                Foreach ($obj in $ResourceID) {
                    Get-CimInstance @cimHash -ClassName SMS_R_System -filter "ResourceID='$obj'"
                }
            }
            'Filter' {
                Foreach ($obj in $Filter) {
                    Get-CimInstance @cimHash -ClassName SMS_R_System -filter $Filter
                }
            }
        }
           
    }
}
Function Get-CCMResourceMembership {
    [Alias('Get-SMS_FullCollectionMembership')]
    [cmdletbinding(SupportsShouldProcess = $true)]

    param(

        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1, ParameterSetName = 'Name')]
        [Alias('ClientName', 'ResourceName')]
        [string[]]$Name,

        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1, ParameterSetName = 'ResourceID')]
        [int[]]$ResourceID,

        [string[]]$Property
    )

    Begin {     
        $cimHash = $Global:CCMConnection.PSObject.Copy()

        $cimHash['ClassName'] = 'SMS_FullCollectionMembership'

        if ($Property) { $cimHash['Property'] = $Property }
        
        #$sbGetCollName = { (Get-CCMCollection -CollectionID $PSItem.CollectionID -Property name).Name}
    }

    Process {
        Switch ($PSCmdlet.ParameterSetName) {
            'Name' {
                Foreach ($obj in $Name) {
                    Get-CCMCollection -CollectionID (Get-CimInstance @cimHash -filter "Name='$obj'").CollectionID | 
                        Sort-Object -Property Name
                        
                }

            }

            'ResourceID' {
                Foreach ($obj in $ResourceID) {
                    Get-CCMCollection -CollectionID (Get-CimInstance @cimHash -filter "ResourceID='$obj'") | 
                        Sort-Object -Property Name
                }
            }
        }
           
    }
}
Function Get-CCMScript {
    
    [cmdletbinding(SupportsShouldProcess = $true)]

    param(
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ScriptGUID')]
        [Alias('GUID')]
        [guid[]]$ScriptGUID,

        [Parameter(ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'ScriptName')]
        [Alias('Name')]
        [string[]]$ScriptName,

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
    }

    Process {
        $cimFilter = $null

        $cimFilter = Switch ($PSCmdlet.ParameterSetName) {
            'ScriptName' {
                Foreach ($obj in $ScriptName) {
                    if ($obj -match '\*') {
                        "ScriptName LIKE '$($obj -replace '\*','%')'" | Write-Output -OutVariable cap
                    }
                    else {
                        "ScriptName = '$obj'"
                    }
                }
            }
            'Author' {
                Foreach ($obj in $Author) {
                    if ($obj -match '\*') {
                        "Author LIKE '$($obj -replace '\*','%')'" | Write-Output -OutVariable cap
                    }
                    else {
                        "Author = '$obj'"
                    }
                }
            }

            'ScriptGUID' {
                Foreach ($obj in $ScriptGUID) {
                    "ScriptGuid='$obj'"
                }
            }

            'Filter' {
                Foreach ($obj in $Filter) {
                    $Filter
                }
            }           
        }

        #"\" is an escape character in WQL
        Get-CimInstance @cimHash -ClassName SMS_Scripts -Filter ($cimFilter -join ' OR ' -replace '\\', '\\' ) | Add-CCMClassType
        
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
Function Get-CCMUserMachineRelationship {
    [alias('Get-SMS_UserMachineRelationship')]
    [cmdletbinding()]

    param(

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Identity')]
        [alias('Name')]
        [string[]]$Identity,

        [Parameter(ParameterSetName = 'Filter')]
        [string]$Filter,
        
        [Parameter()]        
        [switch]$Active
    )

    Begin {
        try {
            $cimHash = $Global:CCMConnection.PSObject.Copy()   
            $cimHash['ClassName'] = 'SMS_UserMachineRelationship'
        }
        catch {
            Throw 'Not connected to CCM, reconnect using Connect-CCM'
        }

        $filterSuffix = if ($Active.IsPresent) {
            'AND (IsActive = {0})' -f [int]($Active.IsPresent)
        }
    } 

    Process {
        Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                Foreach ($obj in $Identity) {
                    Write-Verbose $obj
                    $filter = if ($obj -match '\*') {
                        "ResourceName LIKE '{0}' OR UniqueUserName LIKE '{0}' $filterSuffix" -f ($obj -replace '\*', '%' -replace '\\', '\\')
                    }
                    else {
                        "ResourceName = '{0}' OR UniqueUserName = '{0}' $filterSuffix" -f ($obj -replace '\\', '\\')
                    }
                    Get-CimInstance @cimHash -filter $Filter
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
        $daysInMonth = (($FirstDayOfMonth.AddMonths(1) - $FirstDayOfMonth).totaldays)        
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
<# This function should be moved to the CCM client module
Function Invoke-CCMClientScheduleUpdate
{
    [cmdletbinding()]

    param(
        [string]$ComputerName,
        [pscredential]$Credential,
        [switch]$UseDCOM
    )

    Begin
    {
        $x = 0

        $taskList = @'
            GUID,Task
            {00000000-0000-0000-0000-000000000003},Discovery Data Collection Cycle
			{00000000-0000-0000-0000-000000000001},Hardware Inventory Cycle
            {00000000-0000-0000-0000-000000000002},Software Inventory Cycle
            {00000000-0000-0000-0000-000000000021},Machine Policy Retrieval Cycle
            {00000000-0000-0000-0000-000000000022},Machine Policy Evaluation Cycle
            {00000000-0000-0000-0000-000000000108},Software Updates Assignments Evaluation Cycle
            {00000000-0000-0000-0000-000000000113},Software Update Scan Cycle
            {00000000-0000-0000-0000-000000000110},DCM policy

'@ | ConvertFrom-Csv
        
    }


    Process
    {
        
        foreach ($aComputerName in $ComputerName)
        {
            $cimParm = @{
                ComputerName = $aComputerName
                ErrorAction = 'Stop'
            }

            if ($Credential){ $cimParm['Credential'] = $Credential }
            if ($UseDCOM) { $cimParm['SessionOption'] = New-CimSessionOption -Protocol Dcom }
            
            try
            {        
                $CimSession = Get-CimSession -ComputerName $aComputerName -ErrorAction Stop
            }

            catch
            {
                $CimSession = New-CimSession @cimParm
            }
            if (-not $CimSession) 
            { 
                Write-Warning "Could not connect to $ComputerName"
                continue
            }

            $taskList | ForEach-Object {
                  
                $x++
                           
                $compProgressParm = @{
                    CurrentOperation = $PSItem.Task 
                    Activity = "$aComputerName - Triggering CCM client update Schedules" 
                    Status = "$x of $($taskList.Count)"
                    PercentComplete = 100*($x/$taskList.Count)
                }
                                
                Write-Progress @compProgressParm

                $taskProgressParm = @{
                    CimSession = $CimSession 
                    Namespace = 'root/ccm'
                    Class = 'SMS_CLIENT'
                    Name = 'TriggerSchedule'
                    Arguments = @{ sScheduleID = $PSItem.GUID } 
                    ErrorAction = 'SilentlyContinue'
                }

                Invoke-CimMethod @taskProgressParm

                if ($UseDCOM)
                {
                    $null = $CimSession | Get-CimInstance -ClassName Win32_Service -Filter "Name = 'winrm'" | Invoke-CimMethod -MethodName StartService
                }

            }
        }
    }

}
#>
Function Invoke-CCMCollectionRefresh {

    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [CimInstance[]]$Collection,
        [switch]$Wait
    )

    Begin {
        $spin = @{
            0 = '\'
            1 = '|'
            2 = '/'
            3 = '-'
        }
    }

    Process {
        foreach ($obj in $Collection) {
            $time = $obj.LastRefreshTime
            
            $null = $obj | Invoke-CimMethod -MethodName RequestRefresh

            '{0}: Collection "{1}" updated {2}' -f $MyInvocation.InvocationName, $obj.name, $obj.LastRefreshTime | Write-Verbose

            $obj = $obj | Get-CimInstance

            $x = $null

            While ( $Wait -and $obj.LastRefreshTime -eq $time -and $x -le 6000 ) {
                
                $x++
                Write-Progress -Activity 'Waiting for Collection Refresh' -Status "Collection $($obj.Name)" -CurrentOperation $spin[($x % 4)]
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
<#This function should be moved to the CCM client module

Function Invoke-CCMPackageRerun
{
    [cmdletbinding()]

    param(
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [pscredential]$Credential
    )

    Begin
    {
        $rerunSB = {
        
            Get-CimInstance -ClassName CCM_SoftwareDistribution -namespace root\ccm\policy\machine/ActualConfig -OutVariable Advertisements | Set-CimInstance -Property @{ 
                ADV_RepeatRunBehavior = 'RerunAlways'
                ADV_MandatoryAssignments = $True
            }

            foreach ($a_Advertisement in $Advertisements)
            {
                Write-Verbose -Message "Searching for schedule for package: $() - $($a_Advertisement.PKG_Name)"
                Get-CimInstance -ClassName CCM_Scheduler_ScheduledMessage -namespace "ROOT\ccm\policy\machine\actualconfig" -filter "ScheduledMessageID LIKE '$($a_Advertisement.ADV_AdvertisementID)%'" | 
                    ForEach-Object {

                        $null = Invoke-CimMethod -Namespace 'root\ccm' -ClassName SMS_CLIENT -MethodName TriggerSchedule @{ sScheduleID = $PSItem.ScheduledMessageID }

                        [pscustomobject]@{
                            PKG_Name = $a_Advertisement.PKG_Name
                            ADV_AdvertisementID = $a_Advertisement.ADV_AdvertisementID
                            sScheduleID = $PSItem.ScheduledMessageID
                        }
                    }
            }
            
        }

        $ComputerList = [System.Collections.Generic.List[string]]::new()
    }

    Process
    {
        $ComputerList.AddRange( ([string[]]$ComputerName) )
    }

    End
    {
        $invokeParm = @{
                ScriptBlock = $rerunSB                
        }

        $invokeParm['ComputerName'] = $ComputerList
        
        if ($Credential){
            $invokeParm['Credential'] = $Credential
        }

        if ($ComputerName -eq $env:COMPUTERNAME)
        {
            $invokeParm.Remove('Credential')
            $invokeParm.Remove('ComputerName')
        }

        $invokeParm | Out-String | Write-Verbose

        Invoke-Command @invokeParm
    }

}

#https://kelleymd.wordpress.com/2015/02/08/run-local-advertisement-with-triggerschedule/
#>
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
<#This function should be moved to the client function module

function Start-CCMClientComplianceSettingsEvaluation
{
    [cmdletbinding()]
    
    [alias('Start-DCMComplianceEvaluation')]

    param (
        
        [Parameter(ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName='ComputerName',
            Position=0,
            Mandatory=$true)]
        [string]$ComputerName,

        [Parameter(ParameterSetName='ComputerName')]
        [PSCredential]$Credential,

        [Parameter(ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false,
            ParameterSetName='CimSession',
            Mandatory=$true)]
        [Microsoft.Management.Infrastructure.CimSession]$CimSession,        

        [switch]$WaitForEvalutaion
    )

    Begin
    {
        $LastComplianceStatusHash = @{
            0 = 'Non-Compliant'
            1 = 'Compliant'
            2 = 'Submitted'
            3 = 'Unknown'
            4 = 'Detecting'
            5 = 'Not Evaluated'                  
        }  
        <#
        $StatusHash = @{
            0 = 'Idle'
            1 = 'Evaluated'
            5 = 'Not Evaluated'                                   
        }         
}

    Process
    {
        if (-not $CimSession)
        {
        
            try
            {
                $CimSession = Get-CimSession -ComputerName $ComputerName -ErrorAction Stop
            }
            catch
            {
                
                $cimParm = @{
                    ComputerName = $ComputerName
                }
                if ($Credential)
                {
                    $cimParm['Credential'] = $Credential
                }

                $CimSession = New-CimSession @cimParm -ErrorAction Stop
            }
            
        }

        $systemTime = [system.management.ManagementDateTimeConverter]::ToDmtfDateTime(($CimSession | Get-CimInstance Win32_OperatingSystem).LocalDateTime.addminutes(-10))

        $cimParm = @{                        
            NameSpace = 'root\ccm\dcm'
            ClassName = 'SMS_DesiredConfiguration'
            CimSession = $CimSession
        }

        $baseline = Get-CimInstance @cimParm
        
        foreach ($obj in $baseline)
        {            
            $null = Invoke-CimMethod -CimSession $CimSession -InputObject $obj -MethodName TriggerEvaluation -Arguments @{ Name = $obj.Name; version = $obj.Version }            
        }

        $cimParm['Filter'] = "LastEvalTime < '$systemTime' OR LastComplianceStatus = 3"
            
        While ( $WaitForEvalutaion -and (Get-CimInstance @cimParm) -and $x -le 5)
        {
            foreach ($obj in $baseline)
            {
                if (-not $x)
                {
                    $null = Invoke-CimMethod -ErrorAction Stop -InputObject $obj -MethodName TriggerEvaluation -Arguments @{ Name = $obj.Name; version = $obj.Version }
                }
            }
            
            Write-Progress -Activity 'Refreshing compliance items' -Status "$($update.count) items remaining"
            $x++

            foreach ($obj in $baseline)
            {
                $null = Invoke-CimMethod -InputObject $obj -MethodName TriggerEvaluation -Arguments @{ Name = $obj.Name; version = $obj.Version }
            }
        
            Start-Sleep -Seconds 10
        }

        $cimParm.Remove('Filter')

        Get-CimInstance @cimParm | Select-Object @{Name="ComputerName";Expression={$PSItem.PSComputerName}}, 
            @{Name="DisplayName";Expression={ '{0}: v{1}' -f $PSItem.DisplayName,$PSItem.Version }},
            #@{Name="Status";Expression={$PSItem.Status}},
            @{Name="LastComplianceStatus";Expression={ $LastComplianceStatusHash[ [int]($PSItem.LastComplianceStatus) ] }}, 
            @{Name="LastEvalTime";Expression={Get-Date $PSItem.LastEvalTime}}
    }
}
#>
