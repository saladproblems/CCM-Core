Function Get-CCMResource 
{
    
    [cmdletbinding()]

    param(

        [Parameter(ValueFromPipeline=$true,Position=0,ParameterSetName='Name')]
        [Alias('ClientName','ResourceName')]
        [string[]]$Name,

        [Parameter(ValueFromPipeline=$true,Position=0,ParameterSetName='ResourceID')]
        [int32[]]$ResourceID,

        [Parameter(ParameterSetName='Filter')]
        [string]$Filter
    )

    Begin
    {
            $cimHash = $Global:CCMConnection.PSObject.Copy()
    }

    Process
    {
        Switch ($PSCmdlet.ParameterSetName)
        {
            'Name'
            {
                Foreach ($obj in $Name)
                {
                    if ($obj -match '\*')
                    {
                        Get-CimInstance @cimHash -ClassName SMS_R_System -filter "Name LIKE '$($obj -replace '\*','%')'"
                    }
                    else
                    {
                        Get-CimInstance @cimHash -ClassName SMS_R_System -filter "Name='$obj'"
                    }
                }

            }

            'CollectionID'
            {
                Foreach ($obj in $ResourceID)
                {
                    Get-CimInstance @cimHash -ClassName SMS_R_System -filter "ResourceID='$obj'"
                }
            }

            'Filter'
            {
                Foreach ($obj in $Filter)
                {
                    Get-CimInstance @cimHash -ClassName SMS_R_System -filter $Filter
                }
            }
            'Resource'
            {
                #this is incomplete, just need to add CimInstance to parameters and parameter set
                Foreach ($obj in $Resource)
                {
                    $obj | Get-CimInstance
                }
            }

        }
           
    }
}