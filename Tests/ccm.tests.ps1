param(
    [string]$Server,

    #choose a resource with at least one collection membership
    [string]$ResourceName = $env:COMPUTERNAME
)

Remove-Module CCM -ErrorAction SilentlyContinue
get-module ccm -ListAvailable | Sort-Object version | Select-Object -Last 1 | Import-Module

Describe "CCM module function checks" {
    $localhostResource = Get-CCMResource -Identity $ResourceName
    Context Connect-CCM {
        it "Global variable should contain CimSession" { 
            $global:CCMConnection.CimSession | should -BeOfType [CimSession]
        }
        it "Global variable should be a valid namespace" {
            $global:CCMConnection.NameSpace | should -Match 'root\\sms\\site_[a-z]{3}'
        }        
    }

    Context "Get-CCMResource" {

        it "Find resource by Name" {
            $localhostResource | should -BeOfType [ciminstance]
        }
        it "Find resource by ResourceID" {
            $localhostResource.ResourceID | Get-CCMResource | should -BeOfType [ciminstance]
        }
        it "Requery resource CimInstance" {
            $localhostResource | Get-CCMResource | should -BeOfType [ciminstance]
        }
        it "Find resource by Query" {
            Get-CCMResource -Filter "name = '$ResourceName'" |
                should -BeOfType [ciminstance]
        }
    }

    Context "Get-CCMResourceMembership" {        
        it "Find resource by Name" {
            (Get-CCMResourceMembership -Identity $ResourceName).Count | 
                should -BeGreaterThan 0
        }
        it "Find resource membership by ResourceID" {
            ($localhostResource.ResourceID | Get-CCMResourceMembership).Count |
                should -BeGreaterThan 0
        }
        it "Find resource membership by CimInstance" {
            ($localhostResource | Get-CCMResourceMembership).Count |
                should -BeGreaterThan 0
        }
    }

    Context Get-CCMCollection {
        $Collection = Get-CCMCollection -Identity * | Select-Object -First 5
        it "Find all collections by Wildcard" {
            $Collection.Count | should -BeGreaterThan 0
        }
        it "Find collection by Name" {
            $Collection[0].Name | Get-CCMCollection |
                Should -BeOfType [ciminstance]
        }
        it "Requery CCM Collection for lazy properties" {
            ($Collection[0] | Get-CCMCollection).PSObject.TypeNames |
                Should -Not -Contain 'Microsoft.Management.Infrastructure.CimInstance#__PartialCIMInstance'
        }
        Remove-Variable Collection
    }

    Context Get-CCMCollectionMember {
        $Collection = Get-CCMCollection -Filter 'MemberCount > 0' | Select-Object -First 1
        it "Find collection member by wildcard" {
            ($Collection.Name -replace '..$','*$0' | Get-CCMCollectionMember).Count | 
                should -BeGreaterThan 0
        }
        it "Find collection member by Name" {
            ($Collection.Name -replace '..$','*$0' | Get-CCMCollectionMember).Count | 
                should -BeGreaterThan 0
        }
        it "Find collection member by Collection Object" {
            ($Collection | Get-CCMCollectionMember).Count | 
                should -BeGreaterThan 0
        }
    }

    Context Get-CCMScript {
        $Script = Get-CCMScript -Identity * | Select-Object -First 5
        it "Find all scripts by wildcard" {
            $Script.Count | should -BeGreaterThan 0
        }
        it "Find script by Name" {
            $Script[0].ScriptName | Get-CCMScript |
                Should -BeOfType [ciminstance]
        }
    }
}