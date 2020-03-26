InModuleScope -ModuleName ccm {
    Describe 'Get-CCMResource' {
        mock 'Copy-CCMConnection' { @{} }
        mock 'Get-CimInstance'
        Get-CCMResource -InputObject 'computername'
        it 'Get Resource by Name' {
            Assert-MockCalled -CommandName 'Get-CimInstance' -ParameterFilter {
                $query -match ('^SELECT.*SMS_R_System.*WHERE.*ResourceID.*Name' -f ($Property -join ','),$Identity)
            }
        }
    }
}