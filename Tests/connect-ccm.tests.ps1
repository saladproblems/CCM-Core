Describe 'Connect-CCM' {
    Context 'New connection' {
    Mock 'New-CimSession' {
        Write-Error 'oh no'
        #New-MockObject -Type 'Microsoft.Management.Infrastructure.CimSession'
    }
    Mock 'Get-CimSession' {
        New-MockObject -Type 'Microsoft.Management.Infrastructure.CimSession'
    }
    Mock 'Remove-CimSession' {}

    mock 'Get-CimInstance' {
        [pscustomobject]@{ NamespacePath = 'xxx' }
    }
    Connect-CCM -ComputerName 'server'
    Assert-MockCalled -CommandName 'New-CimSession' -Times 1
}
}