function Start-CCMPostBuild
{
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
    [Alias()]
    [OutputType()]
    Param
    (
        # Param1 help description
        [alias('name')]
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true
        )]
        [string[]]$ResourceName,
        [CimSession]$CimSession = (Get-CimSession -Name 'ccm-*' | Select-Object -First 1)

    )

    Begin
    {
        if (-not $CimSession) { Throw "Please use Connect-CCM to connect to CCM management server" }
        
        $postbuildColl = Get-CCMCollection -CollectionID AP10088B
    }

    Process
    {
        foreach ($obj in $ResourceName)
        {

            $null = Get-CCMResource -Name $obj -CimSession $CimSession -OutVariable '+res'
        
            if (-not $res)
            {
                Write-Error -Message ('Could not find resource with name {0}' -f $obj)
            }            
        }

    }

    End
    {
        if ($res -and $pscmdlet.ShouldProcess(($res.Name -join "`r`n"), "Add to $postbuildColl.Name"))
        {
            Add-CCMMembershipDirect -Resource $res -Collection $postbuildColl -ErrorAction Stop
        }
    }

}