function Connect-CCM
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [Parameter()]
        [switch]$Reconnect,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    process
    {
        Write-Verbose "Looking for CIM Session 'ccmConnection'"
        $cimSession = Get-CimSession -Name "ccmConnection" -ErrorAction SilentlyContinue | Select-Object -First 1

        if ($Reconnect)
        {
            $cimSession | Remove-CimSession
        }
        
        $siteParm = @{
            ClassName = 'SMS_ProviderLocation'
            NameSpace = 'root/sms'
        }

        $siteName = try
        {
            (Get-CimInstance @siteParm -CimSession $cimSession)[0].NamespacePath -replace '^.+site_'
        }
        catch
        {
            $cimSession = New-CimSession -ComputerName $ComputerName -Name "ccmConnection" -Credential $Credential
            (Get-CimInstance @siteParm -CimSession $cimSession)[0].NamespacePath -replace '^.+site_'
        }
    }
    end
    {
        Set-Variable -Name global:CCMConnection -Value @{
            CimSession = $cimSession
            NameSpace = 'root\sms\site_{0}' -f $siteName
        }
    }
    
}