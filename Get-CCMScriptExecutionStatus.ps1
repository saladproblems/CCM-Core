Function Get-CCMScriptExecutionStatus {
    [cmdletbinding()]

    [alias('Get-CCMScriptsExecutionStatus')]

    param(
        [Parameter(ValueFromPipeline = $true)]
        [ciminstance[]]
        $Script,

        [Parameter()]
        [datetime]
        $Start,

        [Parameter()]
        [datetime]
        $End

    )

    begin {
        try {
            [hashtable]$cimHash = $Global:CCMConnection.PSObject.Copy()
        } catch {
            Throw 'Not connected to CCM, reconnect using Connect-CCM'
        }

        $cimHash['ClassName'] = 'SMS_ScriptsExecutionStatus'

        $cimArray = [System.Collections.ArrayList]::new()
    }

    process {
        $cimArray.AddRange([ciminstance[]]$Script)
    }

    end {
        $filter = $cimArray.ForEach( { 'ScriptGUID = "{0}"' -f $PSItem.ScriptGuid }) -join ' OR '

        Get-CimInstance @cimHash -Filter $filter
    }
}