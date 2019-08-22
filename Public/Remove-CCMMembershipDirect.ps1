Function Remove-CCMMembershipDirect {
    [cmdletbinding(SupportsShouldProcess, ConfirmImpact = 'High')]

    param(
        [Parameter()]
        [CimInstance[]]$Resource,

        [Parameter()]
        [CimInstance]$Collection
    )

    Process {
        [ciminstance[]]$collRule = Get-CimInstance -InputObject $Collection |
            Select-Object -ExpandProperty CollectionRules |
            Where-Object -Property ResourceID -In $Resource.ResourceID

        if (-not $collRule) { continue }

        If ($PSCmdlet.ShouldProcess("$($Collection.Name): $($collRule.RuleName -join ',')")) {
            Invoke-CimMethod -InputObject $Collection -MethodName DeleteMembershipRules -Arguments @{ collectionRules = $collRule }
        }
    }
}