Function Get-NthWeekDay {
    [cmdletbinding()]
    [alias('Get-PatchTuesday')]
    param(
        [parameter()]
        [ccm.Month]$Month = (Get-Date -Format 'MM'),

        [parameter()]
        [int]$Year = (Get-Date -Format 'yyyy'),

        [Parameter()]
        [int]$Nth = 2,

        [Parameter()]
        [DayOfWeek]$DayOfWeek = [DayOfWeek]::Tuesday
    )

    begin {
        $FirstDayOfMonth = ([datetime]"$Month/1/$Year").Date
        $daysInMonth = (($FirstDayOfMonth.AddMonths(1) - $FirstDayOfMonth).totaldays)
    }
    process {

        $foundDays = 1..$daysInMonth |
            ForEach-Object { $FirstDayOfMonth.AddDays($PSItem - 1) } |
            Where-Object { $PSItem.DayOfWeek -eq $DayOfWeek }

        try {
            $foundDays[($Nth - 1)]
        }
        catch {
            Write-Error -ErrorAction Stop -Message "Did not find '$Nth'th '$DayOfWeek' in '$Month', '$Year'"
        }
    }
}