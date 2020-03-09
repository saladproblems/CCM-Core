Describe 'Connect-CCM' {
    Context 'Initial Connection' {
        Mock 'New-CimSession' {
            New-MockObject -Type 'Microsoft.Management.Infrastructure.CimSession'
        }
        Mock 'Get-CimSession' {
            throw 'oh no'
        }
        Mock 'Remove-CimSession' {}

        mock 'Get-CimInstance' {
            [pscustomobject]@{ NamespacePath = 'xxx' }
        }
        Connect-CCM -ComputerName 'server' -Verbose
        Assert-MockCalled -CommandName 'New-CimSession' -Times 1
    }
}