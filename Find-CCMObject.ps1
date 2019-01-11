Function Find-CCMObject {
    [Alias()]
    [cmdletbinding()]

    param(
        #Specifies a CIM instance object to use as input.
        [Parameter(ValueFromPipeline, Mandatory)]
        [ciminstance[]]$inputObject
    )

    Begin {
        try {
            $cimHash = $Global:CCMConnection.PSObject.Copy()   
        }
        catch {
            Throw 'Not connected to CCM, reconnect using Connect-CCM'
        }

        $cimHash['ClassName'] = 'SMS_ObjectContainerItem'
    }

    Process {
        foreach ($a_inputObject in $inputObject){
            if ($a_inputObject.CimClass.CimClassName -ne 'SMS_ObjectContainerNode'){
                $keyProperty = $a_inputObject.CimClass.CimClassProperties.Where({$_.Qualifiers.Name -eq 'key' -or $_.Name -match 'uniqueid$'}) |
                    Sort-Object { $PSItem.name -match 'uniqueid'} |
                        Select-Object -Last 1
                $findParm = @{
                    #the uniqueID for the app includes version number, but the container location does not
                    Filter =  '(InstanceKey = "{0}")' -f ($a_inputObject.($keyProperty.Name) -replace '/\d{1,5}$')
                }      

                $containerItem = Get-CimInstance @cimHash @findParm
                $currentContainerNode = Get-CCMObjectContainerNode -Identity $containerItem.ContainerNodeID
            }
            else{
                $currentContainerNode = $a_inputObject
            }

            $sb = [System.Text.StringBuilder]::new()
            $null = $sb.Append("\$($currentContainerNode.Name)")

            while($currentContainerNode.ParentContainerNodeID){
                Write-Verbose $sb.ToString()
                $currentContainerNode = Get-CCMObjectContainerNode -Identity $currentContainerNode.ParentContainerNodeID
                $null = $sb.Insert(0,"\$($currentContainerNode.Name)")                
            }
            $sb.ToString()
        }
    }
}