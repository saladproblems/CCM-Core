<# for future use
class ccmResourceTransformAttribute:System.Management.Automation.ArgumentTransformationAttribute {    
    [object] Transform([System.Management.Automation.EngineIntrinsics]$engineIntrinsics, [object]$object) {        
        $output = switch ($object) {
            { $PSItem -is [Microsoft.Management.Infrastructure.CimInstance] } {
                switch -Regex ($object.CimClass.CimClassName) {
                    'SMS_R_System' {
                        Get-CimInstance -InputObject $object                     
                    }
                }
            }
            { $PSItem -is [string] } {                
                switch -Regex ($PSItem) {                    
                    '^(%|\d)+$' {
                        Get-CimInstance -ClassName SMS_R_System -Filter ('ResourceID LIKE "{0}"' -f $PSItem -replace '\*', '%') @global:CCMConnection 
                    }
                    default {
                        Get-CimInstance -ClassName SMS_R_System -Filter ('Name LIKE "{0}"' -f $PSItem -replace '\*', '%') @global:CCMConnection 
                    }
                }
            }
        }                    
        return $output
    }
}
#>