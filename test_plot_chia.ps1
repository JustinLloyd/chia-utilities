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

$ChiaProcesses = Get-Process -Name 'chia' -ErrorAction Ignore| Select-Object -Property Id,CommandLine
$PlottingCount = $ChiaProcesses | Where {$_.CommandLine -Like "* plots create *"}  | Measure-Object

# if there are greater than X instances of chia running, then exit
If ($PlottingCount.Count -ge $MaxParallelPlots)
{
    Write-Host "More than $($MaxParallelPlots) instances of chia found, will not start another plot, gonna just exit now"
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
    Write-Host "No available temporary storage location - exiting"
    Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - No available temporary storage location - exiting" -Path $ExecutionLog
    Exit
}

# determine which chia processes were started by this script
# determine which phase each chia process is in
# look for any available temp storage location that does not have a plot in phase 1
# if we didn't find an available temp storage location then just exit

TempPath = $TempStorageLocation.Path
$HoldingPath = Get-Random -InputObject $HoldingPaths
# NOTE hard-coded paths for prototyping
$TempPath = "C:\tempchia"
$LoggingPath = "C:\tempchia"
$HoldingPath = 'C:\finalplots'
[void](New-Item -ItemType Directory -Path $TempPath -Force)
[void](New-Item -ItemType Directory -Path $HoldingPath -Force)
$PlottingLogPath=Join-Path $LoggingPath "test-plot-$(get-date -f yyyy-MM-dd_HH-mm)"
Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - Plotting chia to $($TempPath) with logging output sent to $($PlottingLogFilePath)" -Path $ExecutionLog
$StdOutFilePath = "$($PlottingLogPath).out.log"
$StdErrFilePath = "$($PlottingLogPath).err.log"
$LogFilePath = "$($PlottingLogPath).status.log"
Add-Content -Path $LogFilePath -Value ""
# TODO verify the drive has enough space to create a temporary plot
# TODO verify at least one holding path has enough space to hold the final plot
$ChiaExecutable=Join-Path ~\AppData\Local\chia-blockchain\app-*\resources\app.asar.unpacked\daemon\ chia.exe -resolve
#pushd ~\AppData\Local\chia-blockchain\app-*\resources\app.asar.unpacked\daemon
$process = Start-Process $ChiaExecutable -ArgumentList "plots create -k 25 --override-k -n 1 -r $PlottingThreads -t $TempPath -d $HoldingPath" -PassThru -NoNewWindow -RedirectStandardOutput $StdOutFilePath -RedirectStandardError $StdErrFilePath
Start-Sleep -Seconds 3
# TODO wait until the process has actually started, but with a timeout
if ($process.HasExited)
{
    $msg = "Plotting chia to $($TempPath) with logging output sent to $($PlottingLogFilePath)"
    Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - $($msg)" -Path $ExecutionLog
    Exit
}

Add-Content -Path $LogFilePath -Value "PID: $($process.Id)"
# Wait until the chia plotting process starts writing data to the log file
# TODO wait until there is actually data written to the log file
while (!(Test-Path $StdOutFilePath) || $process.HasExited)
{
    Start-Sleep -Seconds 2
}

# wait just a little more to ensure some data has actually been written to the plot log file
# NOTE this sleep step is less than ideal, we should wait for the file size to change, and then wait for the string we want to appear in the log
Start-Sleep -Seconds 3
if ($process.HasExited)
{
    $msg = "Plotting chia to $($TempPath) with logging output sent to $($PlottingLogFilePath)"
    Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - $($msg)" -Path $ExecutionLog
    Exit
}

# snag the plot id from the plot process console output for the log file
# TODO we could really use some more robust error checking on the match/groups/captures/value lookup - it could easily fail
$PlotId  = (Select-String -Path $StdOutFilePath -Pattern '^ID: (.*)$').Matches[0].Groups[1].Captures[0].Value.ToString()
# TODO we should throw an error here if the string wasn't found
Add-Content -Path $LogFilePath -Value "ID: $($PlotId)"
Wait-Process $process.Id
#popd
