#Requires -Version 7.0

# Description: Create a new instance of a chia plotter if there is capacity to do so
$DefaultMaxParallelPlots = 1
$DefaultRAMAllocation = 4608
$DefaultBuckets = 128
$DefaultThreadsPerPlot = 2
$Config = Import-PowershellDataFile -Path .\config.psd1 -ErrorAction Stop

$HoldingPaths = $Config.HoldingPaths
$LoggingPath = $Config.LoggingPath
$MaxParallelPlots = $DefaultMaxParallelPlots
$ThreadsPerPlot = $DefaultThreadsPerPlot
$Buckets = $DefaultBuckets
$RAMAllocation = $DefaultRAMAllocation
if ($Config.MaxParallelPlots) { $MaxParallelPlots = $Config.MaxParallelPlots }
if ($Config.ThreadsPerPlot) { $ThreadsPerPlot = $Config.ThreadsPerPlot } 
if ($Config.Buckets) { $Buckets = $Config.Buckets }
if ($Config.RAMAllocation) { $RAMAllocation = $Config.RAMAllocation } 

[void](New-Item -ItemType Directory -Path $LoggingPath -Force)
$ExecutionLog = Join-Path $LoggingPath 'plotting.log'
$TempStorageLocations = $Config.TempStorageLocations

# determine how many instances of chia are running
$ChiaProcesses = Get-Process -Name 'chia' -ErrorAction Ignore| Select-Object -Property Id,CommandLine
$PlottingCount = $ChiaProcesses | Where {$_.CommandLine -Like "* plots create *"}  | Measure-Object

# if there are greater than X instances of chia running, then exit
if ($PlottingCount.Count -ge $MaxParallelPlots)
{
    $msg = "More than $($MaxParallelPlots) instances of chia found, will not start another plot, gonna just exit now"
    Write-Host $msg
    Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - $($msg)" -Path $ExecutionLog
    Exit
}

$msg ="Found less than $($MaxParallelPlots) instances of chia, starting a new plot"
Write-Host $msg
Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - $($msg)" -Path $ExecutionLog

foreach ($TempStorageLocation in $TempStorageLocations)
{
    $TempStorageLocation.MaxParallelPlots -= ($ChiaProcesses | Where {$_.CommandLine -Like "* -t $($TempStorageLocation.Path) -d *"} | Measure -ErrorAction SilentlyContinue).Count
}

$TempStorageLocation = Get-Random -InputObject ($TempStorageLocations | Where {$_.MaxParallelPlots -Gt 0})
if (!$TempStorageLocation)
{
    $msg = "No available temporary storage location - exiting"
    Write-Host $msg
    Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - $($msg)" -Path $ExecutionLog
    exit
}

# determine which chia processes were started by this script
# determine which phase each chia process is in
# look for any available temp storage location that does not have a plot in phase 1
# if we didn't find an available temp storage location then just exit

$HoldingPath = Get-Random -InputObject $HoldingPaths
[void](New-Item -ItemType Directory -Path $TempStorageLocation.Path -Force)
[void](New-Item -ItemType Directory -Path $HoldingPath -Force)
$PlottingLogPath = Join-Path $LoggingPath "plot-$(get-date -f yyyy-MM-dd_HH-mm)"
$StdOutFilePath = "$($PlottingLogPath).out.log"
$StdErrFilePath = "$($PlottingLogPath).err.log"
$StatusLogFilePath = "$($PlottingLogPath).status.log"
Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - Plotting chia to $($TempStorageLocation.Path)" -Path $ExecutionLog
#pushd ~\AppData\Local\chia-blockchain\app-*\resources\app.asar.unpacked\daemon
$ChiaExecutable = Resolve-Path ~\AppData\Local\chia-blockchain\app-*\resources\app.asar.unpacked\daemon\chia.exe
$ChiaArguments = "plots create -b $($RAMAllocation) -u $($Buckets) -k 32 -n 1 -r $($ThreadsPerPlot) -t $($TempStorageLocation.Path) -d $($HoldingPath)"
$process = Start-Process $ChiaExecutable -ArgumentList $ChiaArguments -PassThru -NoNewWindow -RedirectStandardOutput $StdOutFilePath -RedirectStandardError $StdErrFilePath
Start-Sleep -Seconds 3
# TODO wait until the process has actually started, but with a timeout
if ($process.HasExited)
{
    $msg = "Chia prematurely exited"
    Write-Host $msg
    Add-Content -Value "$(get-date -f yyyy-MM-dd_HH-mm) - $($msg)" -Path $ExecutionLog
    Exit
}

# Wait until the chia plotting process starts writing data to the log file
# TODO wait until there is actually data written to the log file
while (!(Test-Path $StdOutFilePath) || $process.HasExited)
{
    Start-Sleep -Seconds 2
}

# wait just a little more to ensure some data has actually been written to the plot log file
# NOTE this sleep step is less than ideal, we should wait for the file size to change, and then wait for the string we want to appear in the log
Start-Sleep -Seconds 3
# snag the plot id from the plot process console output for the log file
# TODO we could really use some more robust error checking on the match/groups/captures/value lookup - it could easily fail
$PlotId  = (Select-String -Path $StdOutFilePath -Pattern '^ID: (.*)$').Matches[0].Groups[1].Captures[0].Value.ToString()
# TODO we should throw an error here if the string wasn't found
Add-Content -Path $StatusLogFilePath -Value "EXE: $($ChiaExecutable) $($ChiaArguments)"
Add-Content -Path $StatusLogFilePath -Value "PID: $($process.Id)"
Add-Content -Path $StatusLogFilePath -Value "ID: $($PlotId)"
Wait-Process $process.Id
