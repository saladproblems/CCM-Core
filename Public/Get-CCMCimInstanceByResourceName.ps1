function Get-CCMCimInstanceByResourceName {
<#
.SYNOPSIS

Searches for a ccm class by resource ID or name

.DESCRIPTION

Searches for a ccm class by resource ID or name, meant to be a helper function for finding hardware inventory information. This function outputs PS Objects with a the resource record and each additional class as properties with the same name.

.EXAMPLE
C:\PS> Find-CCMRecordByResource -Identity ComputerName1, ComputerName2 -ClassName SMS_G_System_NETWORK_ADAPTER, SMS_G_System_PC_BIOS
Returns PSObjects for each client computer which have the properties SMS_R_System, SMS_G_System_NETWORK_ADAPTE, and SMS_G_System_PC_BIOS

.EXAMPLE
C:\PS> Get-CCMCimClass *computer*system*

CimClassName                        CimClassMethods      CimClassProperties
------------                        ---------------      ------------------
SMS_G_System_COMPUTER_SYSTEM_PRODU… {}                   {ResourceID, GroupID, RevisionID, TimeStamp…}
SMS_G_System_COMPUTER_SYSTEM        {}                   {ResourceID, GroupID, RevisionID, TimeStamp…}
SMS_G_System_DEVICE_COMPUTERSYSTEM  {}                   {ResourceID, GroupID, RevisionID, TimeStamp…}

C:\PS> Find-CCMRecordByResource -Identity Computer1 -ClassName SMS_G_System_COMPUTER_SYSTEM | Select-Object -ExpandProperty SMS_G_System_COMPUTER_SYSTEM | Select *last*

Win32_OperatingSystem contains a computer's last start time, use Get-CCMCimClass to find the correct SMS class, and then use Find-CCMRecordByResource to view the last boot time for the resource

.LINK

https://github.com/saladproblems/CCM-Core

.NOTES
Please help me rename this function, having a hard time coming up with a meaningful one - message mcdonough.david@gmail.com or go to the github project site

#>
    [cmdletbinding()]

    param(
        [parameter(mandatory)]
        [string[]]$ClassName,

        [parameter(valuefrompipeline,ValueFromPipelineByPropertyName)]
        [alias('ResourceId')]
        [string[]]$Identity       
    )

    begin {

        $sb = [System.Text.StringBuilder]::new()

        $null = $sb.AppendLine( 'SELECT * FROM SMS_R_System' )

        $ClassName | ForEach-Object {
            $null = $sb.AppendLine( "INNER JOIN $PSItem ON $PSItem.ResourceId = SMS_R_System.ResourceId" )
        }
        $null = $sb.AppendLine( 'WHERE SMS_R_System.Name LIKE "{0}" OR SMS_R_System.ResourceID LIKE "{0}"' )
    }

    process {
        foreach ($a_Identity in $Identity) {
            Get-CCMCimInstance -Query ( $sb.ToString() -f $a_Identity ) -Verbose
        }
    }
}