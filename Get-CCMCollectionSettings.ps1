Function Get-CCMCollectionSettings {    
    [cmdletbinding()]

    param(
        [ValidateScript( {$PSItem.CimClass.CimClassName -eq 'SMS_Collection'})]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Name')]
        [CimInstance]$Collection        
    )

    Begin
    {}

    Process {
        foreach ($a_Collection in $Collection) {
            $cimHash = @{
                NameSpace  = $a_Collection.CimSystemProperties.Namespace
                CimSession = Get-CimSession -InstanceId $a_Collection.GetCimSessionInstanceId()
            }

            Get-CimInstance @cimHash -ClassName SMS_CollectionSettings -Filter "CollectionID = '$($a_Collection.CollectionID)'" | Get-CimInstance
        }
           
    }

}