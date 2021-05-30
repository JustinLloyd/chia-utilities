#Requires -Version 7.0

# Description: Gets the status of all current plots
function Get-PlotStatus
{
    $Config = Import-PowershellDataFile -Path .\config.psd1 -ErrorAction Stop

    # determine how many instances of chia are running
    $MaxParallelPlots = $Config.MaxParallelPlots
    $LoggingPath = $Config.LoggingPath
    [void](New-Item -ItemType Directory -Path $LoggingPath -Force -ErrorAction Stop)

    #$ActivePlotProcesses = Get-Process -Name 'chia' -ErrorAction Ignore | Select-Object -Property CommandLine | Select-String -Pattern 'plots create'
    $AllStatusLogs = Get-ChildItem -Path $LoggingPath -Filter plot-*.status.log -ErrorAction Ignore
    $AllPlotLogs = Get-ChildItem -Path $LoggingPath -Filter plot-*.out.log -ErrorAction Ignore
    $AllPlots = @()
    $PlotIndex = 0
    $ChiaProcesses = Get-Process -Name 'chia' -ErrorAction Ignore
    foreach ($StatusLogFile in $AllStatusLogs)
    {
        $PlotIndex++
        
        Write-Progress -Activity "Scanning Logs" -Status "$($PlotIndex) of $($AllStatusLogs.Count)" -PercentComplete ($PlotIndex / $AllStatusLogs.Count * 100) -CurrentOperation  $StatusLogFile.Name
        $PlotLogFile = $StatusLogFile -Replace "status.log", "out.log"
        $PlotInfo = [PSCustomObject]@{
            StatusLog = Get-Content -Path $StatusLogFile
            PlotLog = Get-Content -Path $PlotLogFile -ErrorAction Ignore
            Active = $false
    #        Completed = $false
            Id = ""
            Phase = 0
            PercentComplete = 0
            Elapsed = New-TimeSpan
            PID = 0
            CommandLine = ""
            TempPath = ""
            FinalPath = ""
            Threads = 0
            RAMAllocation = 0
        }

        try
        {
            $PlotInfo.Phase = ($PlotInfo.PlotLog  | Select-String -Pattern '^Starting phase (\d)/4:' | Select -Last 1).Matches[0].Groups[1].Captures[0].Value.ToString()
        }

        catch
        {
            # do nothing
        }

        $PlotInfo.Id = ($PlotInfo.StatusLog | Select-String -Pattern '^ID: (.*)$').Matches[0].Groups[1].Captures[0].Value.ToString()
        $PlotInfo.PID = ($PlotInfo.StatusLog | Select-String -Pattern '^PID: (.*)$').Matches[0].Groups[1].Captures[0].Value
        try
        {
            $PlotInfo.CommandLine = ($PlotInfo.StatusLog | Select-String -Pattern '^EXE: (.*)$').Matches[0].Groups[1].Captures[0].Value
        }

        catch
        {
            # do nothing
        }

        try
        {
            $PlotInfo.TempPath = ($PlotInfo.StatusLog | Select-String -Pattern '^TEMP: (.*)$').Matches[0].Groups[1].Captures[0].Value
        }
        
        catch
        {
            #do nothing
        }

        try
        {
            $PlotInfo.FinalPath = ($PlotInfo.StatusLog | Select-String -Pattern '^FINAL: (.*)$').Matches[0].Groups[1].Captures[0].Value
        }
        catch
        {
            # do nothing
        }

        try
        {
            $PlotInfo.RAMAllocation = ($PlotInfo.StatusLog | Select-String -Pattern '^RAM: (.*)$').Matches[0].Groups[1].Captures[0].Value
        }

        catch
        {
            # do nothing
        }

        try
        {
            $PlotInfo.Threads = ($PlotInfo.StatusLog | Select-String -Pattern '^THREADS: (.*)$').Matches[0].Groups[1].Captures[0].Value
        }

        catch
        {
            # do nothing
        }

        $PlotProcess = $ChiaProcesses | Where { $_.Id -Eq $PlotInfo.PID }
        if ($PlotProcess)
        {
            $PlotInfo.Active = $true
            $PlotInfo.Elapsed = $PlotProcess.CPU
        }
        else
        {
            try
            {
                $PlotInfo.Elapsed = New-TimeSpan -Seconds ($PlotInfo.Log | Select-String -Pattern "total time = (.*?) ").Matches[0].Groups[1].Captures[0].Value
            }

            catch
            {
                # do nothing
            }
        }

        $AllPlots += $PlotInfo
    }

    Write-Progress -Completed -Activity "Scanning Logs"
    $AllPlots
}