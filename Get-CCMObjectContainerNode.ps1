Function Get-ObjectContainerNode {

    [Alias('Get-SMS_ObjectContainerNode', 'Get-CCMFolder')]
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Identity')]
        [alias('FolderGUID', 'FolderName', 'Name')]
        [guid[]]$Identity,

        [Parameter(Mandatory = $true, ParameterSetName = 'Filter')]
        [string]$Filter
    )

    Begin {       
        $cimHash = $Global:CCMConnection.PSObject.Copy()

        if ($Property) {
            $cimHash.Property = $Property
        }                
    }

    Process {

        Write-Verbose $PSCmdlet.ParameterSetName

        $cimFilter = Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                switch ($Identity) {
                    { 
                        try {
                            [guid]$Identity
                        }
                        catch {
                            $false
                        }
                    } { 
                        "Name LIKE '$($PSItem -replace '\*','%')'"                        
                    }
                        
                    Default {
                        "Name='$PSItem'"
                    }
                }                
            }

            'CollectionID' {
                Foreach ($obj in $CollectionID) {                   
                    "CollectionID='$obj'"
                }
            }
            'Filter' {
                $Filter
            }

            #Add handling piping in a resource here
        }
        
        Get-CimInstance @cimHash -ClassName SMS_Collection -Filter ($cimFilter -join ' OR ') |
            Add-CCMClassType

    }
    End
    {}
}