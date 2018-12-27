Function New-CCMCollection
{
    [cmdletbinding()]
    [Alias('New-SMS_Collection')]

    param(
        [Parameter(Mandatory)]
        [Alias('CollectionName')]
        [string]$Name,

        [ccm.CollectionType]$CollectionType,

        [Parameter(Mandatory,ParameterSetName='CollectionID')]
        [string]$LimitToCollectionID,

        [Parameter(Mandatory,ParameterSetName='Collection')]
        [ValidateScript({$PSItem.CimClass.CimClassName -eq 'SMS_Collection'})]
        [ciminstance]$LimitToCollection
    )

    Begin
    {       
        $cimHash = $sbCCMGetCimParm.InvokeReturnAsIs()
    }

    Process
    {
        $newCollectionProperty = @{
            Name = $Name
            CollectionType = [int]$CollectionType
            LimitToCollectionID = $LimitToCollectionID
        }
        if ($LimitToCollection)
        {
            $newCollectionProperty['LimitToCollectionID'] = $LimitToCollection.CollectionID
        }

        $newCollectionProperty | Out-String | Write-Verbose
        
        New-CimInstance -OutVariable newCollection @cimHash -ClassName SMS_Collection -Property $newCollectionProperty
    }
}