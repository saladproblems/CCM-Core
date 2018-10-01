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