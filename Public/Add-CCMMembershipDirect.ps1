Function Add-CCMMembershipDirect {
    [cmdletbinding()]

    param(
        [Parameter()]
        [ValidateScript( {$PSItem.CimSystemProperties.ClassName -match '^sms_r_(system|user)'})]
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
        $Collection | Invoke-CimMethod -MethodName AddMemberShipRules -Arguments @{ CollectionRules = [CimInstance[]]$cmRule } -ErrorAction Stop

        $cmRule | Out-String | Write-Verbose
    }

}