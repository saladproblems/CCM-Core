function Wait-CCMClientSoftwareUpdate {
    [cmdletbinding()]
    param (
        [Alias('Wait-CCMClientSoftwareUpdateInstallation')]
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ComputerName',
            Position = 0,
            Mandatory = $true)]
        [alias('Name')]
        [string[]]$ComputerName,

        [Parameter(ParameterSetName = 'ComputerName')]
        [PSCredential]$Credential,

        [Parameter(ParameterSetName = 'CimSession')]
        [CimSession[]]$CimSession,

        [switch]$Quiet,

        [int]$Interval = 5
    )

    begin {
        $cimParam = @{
            NameSpace = 'root/ccm/ClientSDK'
            ClassName = 'CCM_SoftwareUpdate'
            Filter = 'EvaluationState < 8'
        }
    }
    process {
        Switch ($PSCmdlet.ParameterSetName) {
            'ComputerName' {
                $cimParam['ComputerName'] = $ComputerName

                if ($Credential) {
                    $cimParam['Credential'] = $Credential
                }
            }

            'CimSession' {
                $cimParam['CimSession'] = $CimSession
            }
        }

        While (($updates = Get-CimInstance @cimParam)) {
            $updates | ForEach-Object {
                Write-Progress -Activity 'Waiting for patch installation' -CurrentOperation $PSItem.PSComputerName -Status ('{0}: {1}' -f [CCM.EvaluationState]$PSItem.EvaluationState,$PSItem.Name)
            }
            if (-not $Quiet.IsPresent){
                $updates | Out-String | Write-Host -ForegroundColor Green
            }
            Start-Sleep -Seconds $Interval
        }
    }
    end {}
}