<# This function should be moved to the CCM client module
Function Invoke-CCMClientScheduleUpdate
{
    [cmdletbinding()]

    param(
        [string]$ComputerName,
        [pscredential]$Credential,
        [switch]$UseDCOM
    )

    Begin
    {
        $x = 0

        $taskList = @'
            GUID,Task
            {00000000-0000-0000-0000-000000000003},Discovery Data Collection Cycle
			{00000000-0000-0000-0000-000000000001},Hardware Inventory Cycle
            {00000000-0000-0000-0000-000000000002},Software Inventory Cycle
            {00000000-0000-0000-0000-000000000021},Machine Policy Retrieval Cycle
            {00000000-0000-0000-0000-000000000022},Machine Policy Evaluation Cycle
            {00000000-0000-0000-0000-000000000108},Software Updates Assignments Evaluation Cycle
            {00000000-0000-0000-0000-000000000113},Software Update Scan Cycle
            {00000000-0000-0000-0000-000000000110},DCM policy

'@ | ConvertFrom-Csv
        
    }


    Process
    {
        
        foreach ($aComputerName in $ComputerName)
        {
            $cimParm = @{
                ComputerName = $aComputerName
                ErrorAction = 'Stop'
            }

            if ($Credential){ $cimParm['Credential'] = $Credential }
            if ($UseDCOM) { $cimParm['SessionOption'] = New-CimSessionOption -Protocol Dcom }
            
            try
            {        
                $CimSession = Get-CimSession -ComputerName $aComputerName -ErrorAction Stop
            }

            catch
            {
                $CimSession = New-CimSession @cimParm
            }
            if (-not $CimSession) 
            { 
                Write-Warning "Could not connect to $ComputerName"
                continue
            }

            $taskList | ForEach-Object {
                  
                $x++
                           
                $compProgressParm = @{
                    CurrentOperation = $PSItem.Task 
                    Activity = "$aComputerName - Triggering CCM client update Schedules" 
                    Status = "$x of $($taskList.Count)"
                    PercentComplete = 100*($x/$taskList.Count)
                }
                                
                Write-Progress @compProgressParm

                $taskProgressParm = @{
                    CimSession = $CimSession 
                    Namespace = 'root/ccm'
                    Class = 'SMS_CLIENT'
                    Name = 'TriggerSchedule'
                    Arguments = @{ sScheduleID = $PSItem.GUID } 
                    ErrorAction = 'SilentlyContinue'
                }

                Invoke-CimMethod @taskProgressParm

                if ($UseDCOM)
                {
                    $null = $CimSession | Get-CimInstance -ClassName Win32_Service -Filter "Name = 'winrm'" | Invoke-CimMethod -MethodName StartService
                }

            }
        }
    }

}
#>