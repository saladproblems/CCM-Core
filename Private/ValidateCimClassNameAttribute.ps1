<#
.SYNOPSIS
    Class for validating cim Class type names
.DESCRIPTION
    Long description
.EXAMPLE
function test-validator {
    [cmdletbinding()]
    param(
        [ValidateCimClass('Win32_OperatingSystem')]
        [ciminstance[]]$cimInstance
    )

    $cimInstance    
}
test-validator -ciminstance (Get-CimInstance Win32_operatingsystem -computername localhost,localhost)

Use the validator in a function to verify the cim class is the correct type 
.EXAMPLE
    function test-validator {
        [cmdletbinding()]
        param(
            [ValidateCimClass('Win32_Bios,Win32_OperatingSystem')]
            [ciminstance[]]$cimInstance
        )

        $cimInstance    
    }
    test-validator -ciminstance (Get-CimInstance Win32_operatingsystem -computername localhost,localhost)

    Use a comma delimited list of cimclass names 
.NOTES
    The goal here is to clean up code in some of the module's functions by using this validator to confirm we aren't performing the actions on the wrong type of objects
#>
class ValidateCimClass : System.Management.Automation.ValidateEnumeratedArgumentsAttribute {

    [string]$PropertyName    

    ValidateCimClass([string[]]$PropertyName) {
        $this.PropertyName = $PropertyName -split ','
    }

    [void]ValidateElement($Element) {
        if ([string]$Element.CimClass.CimClassName -in $this.PropertyName) {
            throw ('{0} != {1}' -f $this.PropertyName, $Element.CimClass.CimClassName)
        }
    }
}