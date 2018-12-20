Function Get-CCMResourceMembership
{
    [cmdletbinding(SupportsShouldProcess=$true)]

    param(

        [Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=1,ParameterSetName='Name')]
        [Alias('ClientName','ResourceName')]
        [string[]]$Name,

        [Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=1,ParameterSetName='ResourceID')]
        [int[]]$ResourceID,

        [string[]]$Property
    )

    Begin
    {     
        $cimHash = $Global:CCMConnection.PSObject.Copy()

        $cimHash['ClassName'] = 'SMS_FullCollectionMembership'

        if ($Property) { $cimHash['Property'] = $Property }
        
        #$sbGetCollName = { (Get-CCMCollection -CollectionID $PSItem.CollectionID -Property name).Name}
    }

    Process
    {
        Switch ($PSCmdlet.ParameterSetName)
        {
            'Name'
            {
                Foreach ($obj in $Name)
                {
                    Get-CCMCollection -CollectionID (Get-CimInstance @cimHash -filter "Name='$obj'").CollectionID | 
                        Sort-Object -Property Name
                        
                }

            }

            'ResourceID'
            {
                Foreach ($obj in $ResourceID)
                {
                    Get-CCMCollection -CollectionID (Get-CimInstance @cimHash -filter "ResourceID='$obj'") | 
                        Sort-Object -Property Name
                }
            }
        }
           
    }
}