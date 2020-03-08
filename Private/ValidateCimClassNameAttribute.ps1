class ValidateCimClass : System.Management.Automation.ValidateEnumeratedArgumentsAttribute {

    [string]$PropertyName    

    ValidateCimClass([string]$PropertyName) {
        $this.PropertyName = $PropertyName
    }

    [void]ValidateElement($Element) {
        if ([string]$Element.CimClass.CimClassName -ne $this.PropertyName) {
            throw ('{0} != {1}' -f $this.PropertyName, $Element.CimClass.CimClassName)
        }
    }
}
<#
function test-validator {
    [cmdletbinding()]
    param(
        [ValidateCimClass('Win32_Bios')]
        [ciminstance[]]$cimInstance
    )

    $cimInstance    
}

test-validator -ciminstance (Get-CimInstance Win32_Bios -computername localhost,localhost)
#>