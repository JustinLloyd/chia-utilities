#Requires -Version 7.0

# Description: Create a new instance of a chia plotter if there is capacity to do so
$Config = Import-PowershellDataFile -Path .\config.psd1 -ErrorAction Stop

# determine how many instances of chia are running
$MaxParallelPlots = $Config.MaxParallelPlots
$LoggingPath = $Config.LoggingPath
[void](New-Item -ItemType Directory -Path $LoggingPath -Force -ErrorAction Stop)

$ExecutionLog = Join-Path $LoggingPath 'plotting.log'

$ActivePlotProcesses = Get-Process -Name 'chia' -ErrorAction Ignore | Select-Object -Property CommandLine | Select-String -Pattern 'plots create'
$AllPlotLogs = Get-ChildItem -Path $LoggingPath -Filter plot-*.log -ErrorAction Ignore
$AllPlots = @()
$PlotIndex = 0
foreach ($PlotLogFile in $AllPlotLogs)
{
    $PlotIndex++
    Write-Progress -Activity "Scanning Logs" -Status "$($PlotIndex) of $($AllPlotLogs.Length)" -PercentComplete ($PlotIndex / $AllPlotLogs.Length * 100) -CurrentOperation  $PlotLogFile.Name
    $PlotInfo = [PSCustomObject]@{
        Log = Get-Content -Path $PlotLogFile
        Active = $false
        Completed = $false
        Id = ""
        Phase = 0
        PercentComplete = 0
        Elapsed = New-TimeSpan
    }

    $PlotInfo.Id = ($PlotInfo.Log | Select-String -Pattern '^ID: (.*)$').Matches[0].Groups[1].Captures[0].Value.ToString()
    $PlotInfo.Completed = $PlotInfo.Log | Select-String -Pattern '^Copied final file from ' -Quiet
    try
    {
        $PlotInfo.Elapsed = New-TimeSpan -Seconds ($PlotInfo.Log | Select-String -Pattern "total time = (.*?) ").Matches[0].Groups[1].Captures[0].Value
    }
    catch
    {
        $PlotInfo.Elapsed = New-TimeSpan
    }

    $AllPlots += $PlotInfo
}

Write-Progress -Completed -Activity "Scanning Logs"
$AllPlots
$AllPlots.Length
#$AllPlotIds = Get-Content -Path $AllPlotLogs | Select-String -Pattern '^ID: '
#$CompletedPlots = Get-Content -Path $PlotLogs | Select-String -Pattern '^Copied final file from ' | Measure-Object
#$ActivePlotIds
#$ActivePlotLogs
#$ActivePlotPhases
#$ActivePlotsByTempPath

#$stats = Select-String -Path (Join-Path $LoggingPath "plot-*.log") -Pattern "total time" | ForEach-Object{($_ -Split "\s+")[3]} | Measure-Object -Average -Sum
#echo "Active plots" $ActivePlots.Count
#$TBPerDay = 86400 / $stats.Average * 6 * 101.366 / 1024
#echo "Average plot time" $stats.Average/3600
#echo "TiB/day" $TBPerDay
#grep -i "total time" /home/jm/chialogs/*.log |awk '{sum=sum+$4} {avg=sum/NR} {tday=86400/avg*6*101.366/1024} END {printf "%d K32 plots, avg %0.1f seconds, %0.2f TiB/day \n", NR, avg, tday}'