Function Get-CCMScript {

    [cmdletbinding(SupportsShouldProcess = $true)]

    param(
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ScriptGUID')]
        [Alias('GUID')]
        [guid[]]$ScriptGUID,

        [Parameter(ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'ScriptName')]
        [Alias('Name')]
        [string[]]$ScriptName,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Author')]
        [string[]]$Author,

        [Parameter(ParameterSetName = 'Filter')]
        [string]$Filter
    )

    Begin {
        try {
            $cimHash = $Global:CCMConnection.PSObject.Copy()
        } catch {
            Throw 'Not connected to CCM, reconnect using Connect-CCM'
        }
    }

    Process {
        $cimFilter = $null

        $cimFilter = Switch ($PSCmdlet.ParameterSetName) {
            'ScriptName' {
                Foreach ($obj in $ScriptName) {
                    if ($obj -match '\*') {
                        "ScriptName LIKE '$($obj -replace '\*','%')'" | Write-Output -OutVariable cap
                    } else {
                        "ScriptName = '$obj'"
                    }
                }
            }
            'Author' {
                Foreach ($obj in $Author) {
                    if ($obj -match '\*') {
                        "Author LIKE '$($obj -replace '\*','%')'" | Write-Output -OutVariable cap
                    } else {
                        "Author = '$obj'"
                    }
                }
            }

            'ScriptGUID' {
                Foreach ($obj in $ScriptGUID) {
                    "ScriptGuid='$obj'"
                }
            }

            'Filter' {
                Foreach ($obj in $Filter) {
                    $Filter
                }
            }
        }

        #"\" is an escape character in WQL
        Get-CimInstance @cimHash -ClassName SMS_Scripts -Filter ($cimFilter -join ' OR ' -replace '\\', '\\' ) | Add-CCMClassType

    }
}