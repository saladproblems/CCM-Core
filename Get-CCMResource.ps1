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
    [cmdletbinding(DefaultParameterSetName = 'inputObject')]

    param(
        #Specifies an SCCM Resource object by providing the 'Name' or 'ResourceID'.
        [Parameter(ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Identity')]
        [Alias('Name', 'ClientName', 'ResourceName''ResourceID')]
        [WildcardPattern[]]$Identity,

        #Specifies a CIM instance object to use as input.
        [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'inputObject')]
        [ciminstance]$inputObject,

        #Specifies a where clause to use as a filter. Specify the clause in either the WQL or the CQL query language.
        [Parameter(ParameterSetName = 'Filter')]
        [string]$Filter
    )

    Begin {
        try {
            $cimHash = $Global:CCMConnection.PSObject.Copy()
        } catch {
            Throw 'Not connected to CCM, reconnect using Connect-CCM'
        }
        $cimHash['ClassName'] = 'SMS_R_System'
    }

    Process {
        Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                switch -Regex ($Identity.ToWql()) {
                    '^(\d|%)+$' {
                        Get-CimInstance @cimHash -Filter ('ResourceID LIKE "{0}"' -f $PSItem)
                    }
                    default {
                        Get-CimInstance @cimHash -filter ('Name LIKE "{0}"' -f $PSItem)
                    }
                }
            }
            'inputObject' {
                $inputObject | Get-CimInstance
            }
            'Filter' {
                Foreach ($obj in $Filter) {
                    Get-CimInstance @cimHash -filter $Filter
                }
            }
        }
    }
}