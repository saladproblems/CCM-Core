Function Get-CCMCollection {

    <#
.SYNOPSIS

Get an SCCM Collection

.DESCRIPTION

Get an SCCM Collection by Name or CollectionID

.PARAMETER Name
Specifies the file name.

.PARAMETER Extension
Specifies the extension. "Txt" is the default.

.INPUTS

None. You cannot pipe objects to Add-Extension.

.OUTPUTS

System.String. Add-Extension returns a string with the extension
or file name.

.EXAMPLE
C:\PS> Get-CCMCollection *
Retrieves all collections

.EXAMPLE
C:\PS> Get-CCMCollection *SVR*
Returns all collections with SVR in the name

.EXAMPLE
C:\PS> Get-CCMCollection *SVR* -HasMaintenanceWindow
Returns all collections with SVR in the name that have maintenance windows

.LINK

https://github.com/saladproblems/CCM-Core

#>
    [Alias('Get-SMS_Collection')]
    [cmdletbinding(DefaultParameterSetName = 'inputObject')]

    param(
        #Specifies a CIM instance object to use as input.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject')]
        [ValidateCimClass('SMS_Collection,SMS_R_System')]
        [ciminstance[]]$InputObject,

        #Specifies an SCCM collection object by providing the collection name or ID.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Identity')]
        [Alias('ClientName', 'CollectionName', 'CollectionID')]
        [string[]]$Identity,

        #Specifies a where clause to use as a filter. Specify the clause in the WQL query language.
        [Parameter(Mandatory, ParameterSetName = 'Filter')]
        [string]$Filter,

        #Only return collections with service windows - Maintenance windows are a lazy property, requery to view maintenance window info
        [Parameter()]        
        [alias('HasServiceWindow')]
        [switch]$HasMaintenanceWindow,

        #Specifies a set of instance properties to retrieve.
        [Parameter()]
        [string[]]$Property

    )

    Begin {
        $cimHash = $Global:CCMConnection.PSObject.Copy()

        if ($Property) {
            $cimHash['Property'] = $Property
        }

        if ($HasMaintenanceWindow.IsPresent) {
            $HasMaintenanceWindowSuffix = ' AND (ServiceWindowsCount > 0)'
        }
    }

    Process {
        Write-Debug "Chose parameterset '$($PSCmdlet.ParameterSetName)'"
        Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                $cimFilter = switch -Regex ($Identity) {
                    '\*' {
                        'Name LIKE "{0}" OR CollectionID LIKE "{0}"' -f ($PSItem -replace '\*', '%')
                    }

                    Default {
                        'Name = "{0}" OR CollectionID = "{0}"' -f $PSItem
                    }
                }
            }
            'Filter' {
                Get-CimInstance @cimHash -ClassName SMS_Collection -Filter $Filter
            }
            'InputObject' {
                $cimFilter = switch ($InputObject) {
                    { $PSItem.CimClass.CimClassName -match 'SMS_ObjectContainerItem' } {
                        'CollectionID = "{0}"' -f $PSItem.CollectionID
                    }
                    { $PSItem.CimClass.CimClassName -match 'SMS_UpdatesAssignment' } {
                        'CollectionID = "{0}"' -f $PSItem.TargetCollectionID
                    }
                    { $PSItem.CimClass.CimClassName -match 'SMS_Collection' } {
                        'CollectionID = "{0}"' -f $PSItem.CollectionID
                    }
                    { $PSItem.CimClass.CimClassName -match 'SMS_R_System' } {
                        'CollectionID IN (Select CollectionID from sms_fullcollectionmembership Where Resourceid = "{0}")' -f $PSItem.Resourceid
                    }
                }
            }
        }

        if ($cimFilter) {
            $cimFilter = '({0}){1} ORDER BY Name' -f ($cimFilter -join ' OR '), $HasMaintenanceWindowSuffix
            Get-CimInstance @cimHash -ClassName SMS_Collection -Filter $cimFilter
        }
    }
    End
    { }
}