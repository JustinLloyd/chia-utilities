#Requires -Version 7.0

# Description: Create a new instance of a chia plotter if there is capacity to do so
$DefaultMaxParallelPlots = 1
$DefaultRAMAllocation = 4608
$DefaultBuckets = 128
$DefaultPlottingThreads = 2
$Config = Import-PowershellDataFile -Path .\config.psd1 -ErrorAction Stop

# determine how many instances of chia are running
$MaxParallelPlots = if ($Config.MaxParallelPlots) { $Config.MaxParallelPlots } else { $DefaultMaxParallelPlots }
$PlottingThreads = if ($Config.ThreadsPerPlot) { $Config.PlottingThreads } else { $DefaultPlottingThreads }
$HoldingPaths = $Config.HoldingPaths
$LoggingPath = $Config.LoggingPath
$Buckets = if ($Config.Buckets) { $Config.Buckets } else { $DefaultBuckets }
$RAMAllocation = if ($Config.RAMAllocation) { $Config.RAMAllocation } else { $DefaultRAMAllocation }

[void](New-Item -ItemType Directory -Path $LoggingPath -Force)
$ExecutionLog = Join-Path $LoggingPath 'plotting.log'
$TempStorageLocations = $Config.TempStorageLocations

$ChiaProcesses = Get-Process -Name 'chia' -ErrorAction Ignore| Select-Object -Property Id,CommandLine
$PlottingCount = $ChiaProcesses | Where {$_.CommandLine -Like "* plots create *"}  | Measure-Object

# if there are greater than X instances of chia running, then exit
If ($PlottingCount.Count -ge $MaxParallelPlots)
{
    Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - More than $($MaxParallelPlots) instances of chia found, will not start another plot, gonna just exit now" -Path $ExecutionLog
    Exit
}

Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - Found less than $($MaxParallelPlots) instances of chia, starting a new plot" -Path $ExecutionLog

foreach ($TempStorageLocation in $TempStorageLocations)
{
    $TempStorageLocation.MaxParallelPlots -= ($ChiaProcesses | Where {$_.CommandLine -Like "* -t $($TempStorageLocation.Path) -d *"} | Measure -ErrorAction SilentlyContinue).Count
}

$TempStorageLocation = Get-Random -InputObject ($TempStorageLocations | Where {$_.MaxParallelPlots -Gt 0})
if (!$TempStorageLocation)
{
    Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - No available temporary storage location - exiting" -Path $ExecutionLog
    exit
}

$HoldingPath = Get-Random -InputObject $HoldingPaths
[void](New-Item -ItemType Directory -Path $TempStorageLocation.Path -Force)
[void](New-Item -ItemType Directory -Path $HoldingPath -Force)
$PlottingLogFilePath=Join-Path $LoggingPath "plot-$(get-date -f yyyy-MM-dd_HH-mm).log"
Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - Plotting chia to $($TempStorageLocation.Path) with logging output sent to $($PlottingLogFilePath)" -Path $ExecutionLog
pushd ~\AppData\Local\chia-blockchain\app-*\resources\app.asar.unpacked\daemon
.\chia plots create -b $RAMAllocation -u $Buckets -k 32 -n 1 -r $PlottingThreads -t $TempStorageLocation.Path -d $HoldingPath *>&1 | Tee-Object -FilePath $PlottingLogFilePath
popd
