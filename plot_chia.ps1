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
$TempStorageLocations = $Config.TempStorageLocations

$PlottingCount = Get-Process -Name 'chia' -ErrorAction Ignore | Measure-Object

# if there are greater than X instances of chia running, then exit
If ($PlottingCount.Count -ge $MaxParallelPlots)
{
    Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - More than $($MaxParallelPlots) instances of chia found, will not start another plot, gonna just exit now" -Path $ExecutionLog
    Exit
}

Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - Found less than $($MaxParallelPlots) instances of chia, starting a new plot" -Path $ExecutionLog

$ChiaProcesses = Get-Process -Name 'chia' | Select-Object -Property Id,CommandLine
echo "Available Temporary Storage Locations"
echo $TempStorageLocations
foreach ($TempStorageLocation in $TempStorageLocations)
{
    $TempStorageLocation.MaxParallelPlots -= ($ChiaProcesses | Where {$_.CommandLine -Like "* -t $($TempStorageLocation.Path) -d *"} | Measure -ErrorAction SilentlyContinue).Count
}

echo "Available Temporary Storage Locations After Scanning"
echo $TempStorageLocations
$TempStorageLocation = Get-Random -InputObject ($TempStorageLocations | Where {$_.MaxParallelPlots -Gt 0})
echo "Temporary Storage Location Selected"
echo $TempStorageLocation
if (!$TempStorageLocation)
{
    echo "No available temporary storage location - exiting"
    exit
}

$HoldingPath = Get-Random -InputObject $HoldingPaths
$HoldingPath = 'C:\finalplots'
[void](New-Item -ItemType Directory -Path $TempStorageLocation.Path -Force)
[void](New-Item -ItemType Directory -Path $HoldingPath -Force)
$PlottingLogFilePath=Join-Path $LoggingPath "plot-$(get-date -f yyyy-MM-dd_HH-mm).log"
Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - Plotting chia to $($TempStorageLocation.Path) with logging output sent to $($PlottingLogFilePath)" -Path $ExecutionLog
pushd ~\AppData\Local\chia-blockchain\app-*\resources\app.asar.unpacked\daemon
.\chia plots create -k 32 -n 1 -r $PlottingThreads -t $TempStorageLocation.Path -d $HoldingPath *>&1 | Tee-Object -FilePath $PlottingLogFilePath
popd
