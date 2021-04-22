#Requires -Version 7.0

# Description: Create a new instance of a chia plotter if there is capacity to do so
$Config = Import-PowershellDataFile -Path .\config.psd1 -ErrorAction Stop

# determine how many instances of chia are running
$MaxParallelPlots = $Config.MaxParallelPlots
$PlottingThreads = $Config.ThreadsPerPlot
$HoldingPaths = $Config.HoldingPaths
$LoggingPath = $Config.LoggingPath
[void](New-Item -ItemType Directory -Path $LoggingPath -Force)
$ExecutionLog = Join-Path $LoggingPath 'plotting.log'
$PossibleTempPaths = $Config.PossibleTempPaths

$PlottingCount = Get-Process -Name 'chia' -ErrorAction Ignore | Measure-Object

# if there are greater than X instances of chia running, then exit
If ($PlottingCount.Count -ge $MaxParallelPlots)
{
    Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - More than $($MaxParallelPlots) instances of chia found, will not start another plot, gonna just exit now" -Path $ExecutionLog
    Exit
}

Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - Found less than $($MaxParallelPlots) instances of chia, starting a new plot" -Path $ExecutionLog

$TempPath = Get-Random -InputObject $PossibleTempPaths
$TempPath = "C:\tempchia"
$LoggingPath = "C:\tempchia"
$HoldingPath = Get-Random -InputObject $HoldingPaths
$HoldingPath = 'C:\finalplots'
[void](New-Item -ItemType Directory -Path $TempPath -Force)
[void](New-Item -ItemType Directory -Path $HoldingPath -Force)
$PlottingLogFilePath=Join-Path $LoggingPath "test-plot-$(get-date -f yyyy-MM-dd_HH-mm).log"
Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - Plotting chia to $($TempPath) with logging output sent to $($PlottingLogFilePath)" -Path $ExecutionLog
pushd ~\AppData\Local\chia-blockchain\app-*\resources\app.asar.unpacked\daemon
Start-Transcript -Append -Path $PlottingLogFilePath
$process = Start-Process .\chia -ArgumentList "plots create -k 25 --override-k -n 1 -r $PlottingThreads -t $TempPath -d $HoldingPath" -PassThru -NoNewWindow >> $PlottingLogFilePath
Write-Host $process.Id
Wait-Process $process.Id
Stop-Transcript
popd
