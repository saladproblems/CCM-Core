Function Get-CCMCollection 
{
    
    [cmdletbinding()]

    param(

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0,ParameterSetName='Name')]
        [Alias('ClientName','CollectionName')]
        [ValidateCount(1,500)]
        [string[]]$Name,

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=1,ParameterSetName='CollectionID')]
        [ValidateCount(1,500)]
        [string[]]$CollectionID,

        [Parameter(Mandatory=$true,ParameterSetName='Filter')]
        [string]$Filter,

        [string[]]$Property = @( 'Name','CollectionID','LastChangeTime','LimitToCollectionID','LimitToCollectionname','MemberCount' )

    )

    Begin
    {       
        $cimHash = $Global:CCMConnection.PSObject.Copy()

        if ($Property)
        {
            $cimHash.Property = $Property
        }                
    }

    Process
    {

        Write-Verbose $PSCmdlet.ParameterSetName

        $cimFilter = Switch ($PSCmdlet.ParameterSetName)
        {
            'Name'
            {
                switch -Regex ($Name)
                {
                    '\*'
                    { 
                        "Name LIKE '$($PSItem -replace '\*','%')'"                        
                    }
                        
                    Default
                    {
                        "Name='$PSItem'"
                    }
                }                
            }

            'CollectionID'
            {
                Foreach ($obj in $CollectionID)
                {                   
                    "CollectionID='$obj'"
                }
            }
            'Filter'
            {
                $Filter
            }

            #Add handling piping in a resource here
        }
          
    }
    
    End
    {
        Get-CimInstance @cimHash -ClassName SMS_Collection -Filter ($cimFilter -join ' OR ') | Add-CimClassType
    }
}