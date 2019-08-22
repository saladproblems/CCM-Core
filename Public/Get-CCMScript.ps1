Function Get-CCMScript {

    [cmdletbinding(DefaultParameterSetName = 'inputObject')]

    param(
        #Specifies a CIM instance object to use as input.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject')]
        [ciminstance[]]$InputObject,

        #Specifies an SCCM collection object by providing the collection name or ID.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Identity')]
        [Alias('ScriptGUID', 'ScriptName')]
        [string[]]$Identity,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Author')]
        [string[]]$Author,

        [Parameter(ParameterSetName = 'Filter')]
        [string]$Filter
    )

    Begin {
        try {
            $cimHash = $Global:CCMConnection.PSObject.Copy()
        }
        catch {
            Throw 'Not connected to CCM, reconnect using Connect-CCM'
        }
        $cimHash['ClassName'] = 'SMS_Scripts'
    }

    Process {
        Write-Debug $PSCmdlet.ParameterSetName
        Switch ($PSCmdlet.ParameterSetName) {
            'inputObject' {
                $inputObject | Get-CimInstance
            }
            'Identity' {
                Foreach ($obj in $Identity) {
                    Get-CimInstance @cimHash -Filter ('ScriptName LIKE "{0}" OR ScriptGUID LIKE "{0}"' -f $obj -replace '\*', '%' -replace '\[', '[$0]' )
                }
            }
            'Author' {
                Foreach ($obj in $Author) {
                    Get-CimInstance @cimHash -Filter "Author LIKE '$($obj -replace '\*','%')'"
                }
            }
            'Filter' {
                Foreach ($obj in $Filter) {
                    Get-CimInstance @cimHash -Filter $Filter
                }
            }
        }
    }
}