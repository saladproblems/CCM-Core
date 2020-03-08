<#
.SYNOPSIS
    Class for validating cim Class type names
.DESCRIPTION
    Long description
.EXAMPLE
    function test-validator {
        [cmdletbinding()]
        param(
            [ValidateCimClass('Win32_Bios')]
            [ciminstance[]]$cimInstance
        )

        $cimInstance    
    }
    test-validator -ciminstance (Get-CimInstance Win32_Bios -computername localhost,localhost)

    Use the validator in a function to verify the cim class is the correct type 
.NOTES
    The goal here is to clean up code in some of the module's functions by using this validator to confirm we aren't performing the actions on the wrong type of objects
#>
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