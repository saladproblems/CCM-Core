function Start-CCMClientComplianceSettingsEvaluation
{
    [cmdletbinding()]
    
    [alias('Start-DCMComplianceEvaluation')]

    param (
        
        [Parameter(ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName='ComputerName',
            Position=0,
            Mandatory=$true)]
        [string]$ComputerName,

        [Parameter(ParameterSetName='ComputerName')]
        [PSCredential]$Credential,

        [Parameter(ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false,
            ParameterSetName='CimSession',
            Mandatory=$true)]
        [Microsoft.Management.Infrastructure.CimSession]$CimSession,        

        [switch]$WaitForEvalutaion
    )

    Begin
    {
        $LastComplianceStatusHash = @{
            0 = 'Non-Compliant'
            1 = 'Compliant'
            2 = 'Submitted'
            3 = 'Unknown'
            4 = 'Detecting'
            5 = 'Not Evaluated'                  
        }  
        <#
        $StatusHash = @{
            0 = 'Idle'
            1 = 'Evaluated'
            5 = 'Not Evaluated'                                   
        } 
        #>
}

    Process
    {
        if (-not $CimSession)
        {
        
            try
            {
                $CimSession = Get-CimSession -ComputerName $ComputerName -ErrorAction Stop
            }
            catch
            {
                
                $cimParm = @{
                    ComputerName = $ComputerName
                }
                if ($Credential)
                {
                    $cimParm['Credential'] = $Credential
                }

                $CimSession = New-CimSession @cimParm -ErrorAction Stop
            }
            
        }

        $systemTime = [system.management.ManagementDateTimeConverter]::ToDmtfDateTime(($CimSession | Get-CimInstance Win32_OperatingSystem).LocalDateTime.addminutes(-10))

        $cimParm = @{                        
            NameSpace = 'root\ccm\dcm'
            ClassName = 'SMS_DesiredConfiguration'
            CimSession = $CimSession
        }

        $baseline = Get-CimInstance @cimParm
        
        foreach ($obj in $baseline)
        {            
            $null = Invoke-CimMethod -CimSession $CimSession -InputObject $obj -MethodName TriggerEvaluation -Arguments @{ Name = $obj.Name; version = $obj.Version }            
        }

        $cimParm['Filter'] = "LastEvalTime < '$systemTime' OR LastComplianceStatus = 3"
            
        While ( $WaitForEvalutaion -and (Get-CimInstance @cimParm) -and $x -le 5)
        {
            foreach ($obj in $baseline)
            {
                if (-not $x)
                {
                    $null = Invoke-CimMethod -ErrorAction Stop -InputObject $obj -MethodName TriggerEvaluation -Arguments @{ Name = $obj.Name; version = $obj.Version }
                }
            }
            
            Write-Progress -Activity 'Refreshing compliance items' -Status "$($update.count) items remaining"
            $x++

            foreach ($obj in $baseline)
            {
                $null = Invoke-CimMethod -InputObject $obj -MethodName TriggerEvaluation -Arguments @{ Name = $obj.Name; version = $obj.Version }
            }
        
            Start-Sleep -Seconds 10
        }

        $cimParm.Remove('Filter')

        Get-CimInstance @cimParm | Select-Object @{Name="ComputerName";Expression={$PSItem.PSComputerName}}, 
            @{Name="DisplayName";Expression={ '{0}: v{1}' -f $PSItem.DisplayName,$PSItem.Version }},
            #@{Name="Status";Expression={$PSItem.Status}},
            @{Name="LastComplianceStatus";Expression={ $LastComplianceStatusHash[ [int]($PSItem.LastComplianceStatus) ] }}, 
            @{Name="LastEvalTime";Expression={Get-Date $PSItem.LastEvalTime}}
    }
}