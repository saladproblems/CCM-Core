function Connect-CCM
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [switch]$Reconnect,

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

        try
        {
            $null = Get-CimInstance Win32_BIOS -ErrorAction Stop -CimSession $cim
        }
        catch
        {
            $cimSession = New-CimSession -ComputerName $ComputerName -Name "ccmConnection" -Credential $Credential
        }
    }
    end
    {
        $siteName = (Get-CimInstance -ClassName SMS_ProviderLocation -CimSession $cimSession -Namespace root/sms)[0].NamespacePath -replace '^.+site_'

        Set-Variable -Name global:CCMConnection -Value @{
            CimSession = $cimSession
            NameSpace = 'root\sms\site_{0}' -f $siteName
        }
    }
    
}