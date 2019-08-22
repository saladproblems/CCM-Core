Function Get-CCMSoftwareUpdateGroup {
<#
.SYNOPSIS

Gets an SCCM 'Software Update Group' (sug/SMS_AuthorizationList)

.DESCRIPTION

Gets an SCCM 'Software Update Group' (sug/SMS_AuthorizationList) by Name or CI_ID

.OUTPUTS
Microsoft.Management.Infrastructure.CimInstance#root/sms/site_qtc/SMS_AuthorizationList

.EXAMPLE
C:\PS> Get-CCMSoftwareUpdateGroup *
Retrieves all software update groups

.EXAMPLE
C:\PS> Get-CCMSoftwareUpdateGroup ADR*
Returns all resources whose  start with ADR

.LINK

https://github.com/saladproblems/CCM-Core

#>
        [Alias('Get-SMS_AuthorizationList','Get-CCMSUG')]
        [cmdletbinding(DefaultParameterSetName = 'inputObject')]

        param(
            #Specifies an SCCM Resource object by providing the 'Name' or 'ResourceID'.
            [Parameter(ValueFromPipeline, Position = 0, ParameterSetName = 'Identity')]
            [Alias('Name','CI_ID')]
            [string[]]$Identity='*',

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
            }
            catch {
                Throw 'Not connected to CCM, reconnect using Connect-CCM'
            }
            $cimHash['ClassName'] = 'SMS_AuthorizationList'
        }

        Process {
            Switch ($PSCmdlet.ParameterSetName) {
                'Identity' {
                    foreach ($obj in $Identity) {
                        Get-CimInstance @cimHash -Filter ('LocalizedDisplayName LIKE "{0}" OR ci_id LIKE "{0}"' -f $obj -replace '\*','%')
                    }
                }
                'inputObject' {
                    $inputObject | Get-CimInstance
                }
                'Filter' {
                    foreach ($obj in $Filter) {
                        Get-CimInstance @cimHash -filter $obj
                    }
                }
            }

        }
    }