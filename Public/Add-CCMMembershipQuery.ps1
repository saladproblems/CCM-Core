Function Add-CCMMembershipQuery {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory)]
        [ValidateCimClass('SMS_Collection')]
        $Collection,

        [parameter(Mandatory)]
        [string]$RuleName,

        [parameter(Mandatory)]
        [ValidateScript( { Test-CCMQueryExpression -QueryExpression $PSItem })]
        [string]$QueryExpression
    )

    Begin {
        $cimHash = $Global:CCMConnection.PSObject.Copy()            
        
        $queryObjParam = @{
            ClientOnly = $true
            ClassName  = 'SMS_CollectionRuleQuery'
            Namespace  = $cimHash.Namespace
            Property   = @{
                QueryExpression = $QueryExpression
            }        
        }
        $cimRule = New-CimInstance @queryObjParam
    }

    Process {
        Invoke-CimMethod -InputObject $Collection -MethodName AddMembershipRules -Arguments @{ CollectionRules = [CimInstance[]]$cimRule }
    }

}
