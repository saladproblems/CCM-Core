function Connect-CCM {
    <#
    .SYNOPSIS
        This function establishes a connection to an SCCM Server system.

    .DESCRIPTION
        This function establishes a connection to an SCCM Server system. The function creates
        a CIM session [CimSession], queries the server for the SCCM site and namespace, and
        stores connection information in a global variable

    .INPUTS
        [string]

    .OUTPUTS
        [CimInstance]

    .EXAMPLE
        C:\PS>Connect-CCM -Server WINSCCM01

        Connects to the SCCM server WINSCCM01
    #>
    [CmdletBinding()]
    Param
    (
        #The name of the SCCM server
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        #Removes previous CimSession if found
        [Parameter()]
        [switch]$Reconnect,

        #Specifies a PSCredential object that contains credentials for authenticating with the server
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    process {
        Write-Verbose "Looking for CIM Session 'ccmConnection'"
        $cimSession = Get-CimSession -Name "ccmConnection" -ErrorAction SilentlyContinue | Select-Object -First 1

        if ($Reconnect) {
            $cimSession | Remove-CimSession
        }

        $siteParm = @{
            ClassName = 'SMS_ProviderLocation'
            NameSpace = 'root/sms'
        }

        $siteName = try {
            (Get-CimInstance @siteParm -CimSession $cimSession)[0].NamespacePath -replace '^.+site_'
        } catch {
            $cimSession = New-CimSession -ComputerName $ComputerName -Name "ccmConnection" -Credential $Credential
            (Get-CimInstance @siteParm -CimSession $cimSession)[0].NamespacePath -replace '^.+site_'
        }
    }
    end {
        Set-Variable -Name global:CCMConnection -Value @{
            CimSession = $cimSession
            NameSpace  = 'root\sms\site_{0}' -f $siteName
        }
    }
}