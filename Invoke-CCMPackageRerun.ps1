Function Invoke-CCMPackageRerun
{
    [cmdletbinding()]

    param(
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [pscredential]$Credential
    )

    Begin
    {
        $rerunSB = {
        
            Get-CimInstance -ClassName CCM_SoftwareDistribution -namespace root\ccm\policy\machine/ActualConfig -OutVariable Advertisements | Set-CimInstance -Property @{ 
                ADV_RepeatRunBehavior = 'RerunAlways'
                ADV_MandatoryAssignments = $True
            }

            foreach ($a_Advertisement in $Advertisements)
            {
                Write-Verbose -Message "Searching for schedule for package: $() - $($a_Advertisement.PKG_Name)"
                Get-CimInstance -ClassName CCM_Scheduler_ScheduledMessage -namespace "ROOT\ccm\policy\machine\actualconfig" -filter "ScheduledMessageID LIKE '$($a_Advertisement.ADV_AdvertisementID)%'" | 
                    ForEach-Object {

                        $null = Invoke-CimMethod -Namespace 'root\ccm' -ClassName SMS_CLIENT -MethodName TriggerSchedule @{ sScheduleID = $PSItem.ScheduledMessageID }

                        [pscustomobject]@{
                            PKG_Name = $a_Advertisement.PKG_Name
                            ADV_AdvertisementID = $a_Advertisement.ADV_AdvertisementID
                            sScheduleID = $PSItem.ScheduledMessageID
                        }
                    }
            }
            
        }

        $ComputerList = [System.Collections.Generic.List[string]]::new()
    }

    Process
    {
        $ComputerList.AddRange( ([string[]]$ComputerName) )
    }

    End
    {
        $invokeParm = @{
                ScriptBlock = $rerunSB                
        }

        $invokeParm['ComputerName'] = $ComputerList
        
        if ($Credential){
            $invokeParm['Credential'] = $Credential
        }

        if ($ComputerName -eq $env:COMPUTERNAME)
        {
            $invokeParm.Remove('Credential')
            $invokeParm.Remove('ComputerName')
        }

        $invokeParm | Out-String | Write-Verbose

        Invoke-Command @invokeParm
    }

}

#https://kelleymd.wordpress.com/2015/02/08/run-local-advertisement-with-triggerschedule/