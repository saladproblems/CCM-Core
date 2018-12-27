function Get-CCMClientExecutionRequest {
    param (
        
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ComputerName',
            Position = 0,
            Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(ParameterSetName = 'ComputerName')]
        [PSCredential]$Credential 

    )

    Begin
    {}

    Process {
        if (-not $CimSession) {
        
            try {
                $CimSession = Get-CimSession -ComputerName $ComputerName -ErrorAction Stop
            }
            catch {
                
                $cimParm = @{
                    ComputerName = $ComputerName
                }
                if ($Credential) {
                    $cimParm['Credential'] = $Credential
                }

                $CimSession = New-CimSession @cimParm -ErrorAction Stop
            }
            
        }
        
        $cimParm = @{            
            OutVariable = 'update'
            NameSpace   = 'root\ccm\SoftMgmtAgent'
            ClassName   = 'CCM_ExecutionRequestEx'
            CimSession  = $CimSession
        }

        Get-CimInstance @cimParm | ForEach-Object { $PSItem.PSObject.TypeNames.Insert(0, 'Microsoft.Management.Infrastructure.CimInstance.CCM_ExecutionRequestEx') ; $PSItem }
        
    }
}
