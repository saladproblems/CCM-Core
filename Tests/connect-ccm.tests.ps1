
InModuleScope  CCM {
    Describe 'Connect-CCM' {   
        Mock 'New-CimSession' {
            New-MockObject -Type 'Microsoft.Management.Infrastructure.CimSession'
        }
        mock 'Get-CimInstance' {
            [pscustomobject]@{ NamespacePath = 'xxx' }
        }
        mock 'Get-CimSession' {
            throw 'not found'
        }
        Context 'Use existing CimSession' {
            mock 'Get-CimSession' {
                New-MockObject -Type 'Microsoft.Management.Infrastructure.CimSession'
            }
            Connect-CCM -ComputerName 'server'

            it 'Search for existing CIM session' {
                Assert-MockCalled -CommandName 'Get-CimSession'
            }
            it 'Created new CIM Session' {
                Assert-MockCalled -CommandName 'New-CimSession' -Times 1 -ExclusiveFilter { $ComputerName -eq 'Server' -and $Credential -eq $null }                
            }
            it 'Queried Server for sitecode' {
                Assert-MockCalled -CommandName 'Get-CimInstance' -ExclusiveFilter { $ClassName -eq 'SMS_ProviderLocation' -and $NameSpace -eq 'root/sms' }
            }
            it 'Set variable CCMConnection' {
                $global:CCMConnection.NameSpace | Should -Be root\sms\site_xxx
                $global:CCMConnection.CimSession | Should -BeOfType 'Microsoft.Management.Infrastructure.CimSession'
            }
        }
        Context 'Connect' {
            Connect-CCM -ComputerName 'server'
            it 'Search for existing CIM session (and fail)' {
                Assert-MockCalled -CommandName 'Get-CimSession'
            }
            it 'Created new CIM Session' {
                Assert-MockCalled -CommandName 'New-CimSession' -Times 1 -ExclusiveFilter { $ComputerName -eq 'Server' -and $Credential -eq $null }                
            }
            it 'Queried Server for sitecode' {
                Assert-MockCalled -CommandName 'Get-CimInstance' -ExclusiveFilter { $ClassName -eq 'SMS_ProviderLocation' -and $NameSpace -eq 'root/sms' }
            }
            it 'Set variable CCMConnection' {
                $global:CCMConnection.NameSpace | Should -Be root\sms\site_xxx
                $global:CCMConnection.CimSession | Should -BeOfType 'Microsoft.Management.Infrastructure.CimSession'
            }
        }
        Context 'Connect with Credential' {        
            Connect-CCM -ComputerName 'server' -Credential (New-MockObject -Type PSCredential)
            it 'Search for existing CIM session (and fail)' {
                Assert-MockCalled -CommandName 'Get-CimSession'
            }
            it 'Created new CIM Session' {
                Assert-MockCalled -CommandName 'New-CimSession' -Times 1 -ExclusiveFilter { $ComputerName -eq 'Server' -and $Credential -ne $null }                
            }
            it 'Queried Server for sitecode' {
                Assert-MockCalled -CommandName 'Get-CimInstance' -ExclusiveFilter { $ClassName -eq 'SMS_ProviderLocation' -and $NameSpace -eq 'root/sms' }
            }
            it 'Set variable CCMConnection' {
                $global:CCMConnection.NameSpace | Should -Be root\sms\site_xxx
                $global:CCMConnection.CimSession | Should -BeOfType 'Microsoft.Management.Infrastructure.CimSession'
            }
        }
        Context 'Reconnect' {
            Connect-CCM -ComputerName 'server'
            mock 'Get-CimSession' {
                New-MockObject -Type 'Microsoft.Management.Infrastructure.CimSession'
            }
            mock 'Remove-CimSession' { }            
            it 'Search for existing CIM session' {
                Assert-MockCalled -CommandName 'Get-CimSession'
            }
            it 'Remove connection CIM Session' {
                Assert-MockCalled -CommandName Remove-CimSession
            }
            it 'Created new CIM Session' {
                Assert-MockCalled -CommandName 'New-CimSession' -Times 1 -ExclusiveFilter { $ComputerName -eq 'Server' -and $Credential -eq $null }                
            }
            it 'Queried Server for sitecode' {
                Assert-MockCalled -CommandName 'Get-CimInstance' -ExclusiveFilter { $ClassName -eq 'SMS_ProviderLocation' -and $NameSpace -eq 'root/sms' }
            }
            it 'Set variable CCMConnection' {
                $global:CCMConnection.NameSpace | Should -Be root\sms\site_xxx
                $global:CCMConnection.CimSession | Should -BeOfType 'Microsoft.Management.Infrastructure.CimSession'
            }
        }
    }
}
