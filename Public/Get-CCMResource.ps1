Function Get-CCMResource {
    <#
.SYNOPSIS

Get an SCCM Resource

.DESCRIPTION

Get an SCCM Resource by Name or ResourceID

.OUTPUTS
Microsoft.Management.Infrastructure.CimInstance#root/sms/site_qtc/SMS_R_System

.EXAMPLE
C:\PS> Get-CCMResource *
Retrieves all Resources

.EXAMPLE
C:\PS> Get-CCMResource *SVR*
Returns all resources with SVR in the name

.LINK

https://github.com/saladproblems/CCM-Core

#>
    [Alias('Get-SMS_R_System')]
    [cmdletbinding()]

    param(
        #Specifies an SCCM Resource object by providing the 'Name' or 'ResourceID'.
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Identity')]
        [Alias('Name', 'ClientName', 'ResourceName', 'ResourceID', 'InputObject')]
        [object[]]$Identity,

        #Specifies a where clause to use as a filter. Specify the clause in either the WQL or the CQL query language.
        [Parameter(Mandatory, ParameterSetName = 'Filter')]
        [string[]]$Filter,

        [Parameter()]
        [string[]]$Property = '*'
    )

    Begin {
        try {
            $cimHash = $Global:CCMConnection.PSObject.Copy()
        }
        catch {
            Throw 'Not connected to CCM, reconnect using Connect-CCM'
        }
        [string]$propertyString = $Property -replace '^', 'SMS_R_System.' -join ','
    }

    Process {
        Switch ($Identity) {
            { $PSItem -is [string] -or $PSItem -is [int] } {
                Get-CimInstance @cimHash -Query ('SELECT {0} FROM SMS_R_System WHERE ResourceId LIKE "{1}" OR Name LIKE "{1}"' -f $propertyString, ($PSItem -replace '\*', '%'))                   
            }
            { $PSItem -is [ciminstance] } {
                switch ($PSItem) {
                    {$PSItem.CimSystemProperties.ClassName -eq 'SMS_R_System'} {
                        Get-CimInstance -InputObject $PSItem
                    }
                    {$PSItem.CimSystemProperties.ClassName -eq 'SMS_Collection'} {
                        Get-CimInstance @cimHash -Query ('SELECT {0} FROM SMS_R_System INNER JOIN SMS_FullCollectionMembership ON SMS_R_System.ResourceId = SMS_FullCollectionMembership.ResourceId WHERE CollectionId = "{1}"' -f $propertyString, $PSItem.CollectionId)
                    }
                    default {
                        $PSItem.CimSystemProperties.ClassName
                    }
                }
            }
            default {
                Write-Error ('Did not recognize Identity: {0}' -f $Identity)
            }
        }
        if ($Filter) {        
            $Filter | ForEach-Object {
                Get-CimInstance @cimHash -Query ("SELECT {0} FROM SMS_R_System WHERE {1}" -f $propertyString, $PSItem)
            }
        }
    }
}