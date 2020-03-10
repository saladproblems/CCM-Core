Get-Module -ListAvailable ccm | Sort-Object Version | Select-Object -last 1 | Import-Module -Force

InModuleScope -ModuleName ccm {
    describe 'connect-ccm' {
        context 'Use existing connection' {
            mock 'Get-CimSession' {
                New-MockObject -type 'Microsoft.Management.Infrastructure.CimSession'
            }
            mock New-CimSession { }
            mock Set-Variable { }
            mock Get-CimInstance {
                [pscustomobject]@{
                    NamespacePath = '\site_xxx'
                }
            }
            Connect-CCM -ComputerName 'mock'

            it 'Did not create new connection' {
                Assert-MockCalled -CommandName Get-CimSession -Times 1
                Assert-MockCalled -CommandName New-CimSession -Times 0
            }
            it 'Set ccmConnection variable' {
                Assert-MockCalled -CommandName Set-Variable -ParameterFilter { $Name -eq 'global:CCMConnection' -and $Value.NameSpace -eq 'root\sms\site_xxx' }
            }
        }
        context 'New connection' {
            mock 'Get-CimSession' {
                Write-Error 'no session found'
            }
            mock New-CimSession {
                New-MockObject -type 'Microsoft.Management.Infrastructure.CimSession'
            }
            mock Set-Variable { }
            mock Get-CimInstance {
                [pscustomobject]@{
                    NamespacePath = '\site_xxx'
                }
            }
            Connect-CCM -ComputerName 'mock'

            it 'Create new connection' {
                Assert-MockCalled -CommandName New-CimSession -Times 1
            }
            it 'Set ccmConnection variable' {
                Assert-MockCalled -CommandName Set-Variable -ParameterFilter { $Name -eq 'global:CCMConnection' -and $Value.NameSpace -eq 'root\sms\site_xxx' }
            }
        }
        context 'Reconnect' {
            mock 'Get-CimSession' {
                New-MockObject -type 'Microsoft.Management.Infrastructure.CimSession'
            }
            mock 'Remove-CimSession' {}
            mock New-CimSession {
                New-MockObject -type 'Microsoft.Management.Infrastructure.CimSession'
            }
            mock Set-Variable { }
            mock Get-CimInstance {
                [pscustomobject]@{
                    NamespacePath = '\site_xxx'
                }
            }
            Connect-CCM -ComputerName 'mock' -Reconnect

            it 'Find existing connection' {
                Assert-MockCalled -CommandName Get-CimSession -Times 1
            }
            it 'Remove connection' {
                Assert-MockCalled -CommandName Remove-CimSession
            }
            it 'Create new connection' {
                Assert-MockCalled -CommandName New-CimSession -Times 1
            }
            it 'Set ccmConnection variable' {
                Assert-MockCalled -CommandName Set-Variable -ParameterFilter { $Name -eq 'global:CCMConnection' -and $Value.NameSpace -eq 'root\sms\site_xxx' }
            }
        }
    }
}