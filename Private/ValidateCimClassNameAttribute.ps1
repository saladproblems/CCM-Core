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
        if ($this.PropertyName -notmatch "$($Element.CimClass.CimClassName)$") {
            throw ('Unexpected CIM class type: {0}' -f $Element.CimClass.CimClassName)
        }
    }
}