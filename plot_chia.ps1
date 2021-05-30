#Requires -Version 7.0

# Description: Create a new instance of a chia plotter if there is capacity to do so

. .\plot_status.ps1

$DefaultMaxParallelPlots = 1
$DefaultRAMAllocation = 4608
$DefaultBuckets = 128
$DefaultThreadsPerPlot = 2
$DefaultMaxPhase1Plots = 1
$Config = Import-PowershellDataFile -Path .\config.psd1 -ErrorAction Stop

$HoldingPaths = $Config.HoldingPaths
$LoggingPath = $Config.LoggingPath
$MaxParallelPlots = $DefaultMaxParallelPlots
$ThreadsPerPlot = $DefaultThreadsPerPlot
$Buckets = $DefaultBuckets
$RAMAllocation = $DefaultRAMAllocation
$MaxPhase1Plots = $DefaultMaxPhase1Plots
if ($Config.MaxParallelPlots) { $MaxParallelPlots = $Config.MaxParallelPlots }
if ($Config.ThreadsPerPlot) { $ThreadsPerPlot = $Config.ThreadsPerPlot } 
if ($Config.Buckets) { $Buckets = $Config.Buckets }
if ($Config.RAMAllocation) { $RAMAllocation = $Config.RAMAllocation }
if ($Config.MaxPhase1Plots) { $MaxPhase1Plots = $Config.MaxPhase1Plots}

[void](New-Item -ItemType Directory -Path $LoggingPath -Force)
$ExecutionLog = Join-Path $LoggingPath 'plotting.log'
$TempStorageLocations = $Config.TempStorageLocations

# determine how many instances of chia are running
$ChiaProcesses = Get-Process -Name 'chia' -ErrorAction Ignore| Select-Object -Property Id,CommandLine
$PlottingCount = ($ChiaProcesses | Where {$_.CommandLine -Like "* plots create *"}).Count

# if there are greater than X instances of chia running, then exit
if ($PlottingCount -ge $MaxParallelPlots)
{
    $msg = "More than $($MaxParallelPlots) instances of chia found, will not start another plot, gonna just exit now"
    Write-Host $msg
    Add-Content -Value "MSG: $(get-date -f yyyy-MM-dd_HH-mm): $($msg)" -Path $ExecutionLog
    Exit
}

$msg ="Found less than $($MaxParallelPlots) instances of chia, starting a new plot"
Write-Host $msg
Add-Content -Value "MSG: $(get-date -f yyyy-MM-dd_HH-mm): $($msg)" -Path $ExecutionLog

$StatusOfPlots = Get-PlotStatus
$PlotsInPhase1 = ($StatusOfPlots | Where { $_.Active -And $_.Phase -Eq 1 })
if ($PlotsInPhase1.Count -ge $MaxPhase1Plots)
{
    $msg = "Detected too many ($($PlotsInPhase1Count)) plots in phase 1 - exiting"
    Write-Host $msg
    Add-Content -Value "MSG: $(get-date -f yyyy-MM-dd_HH-mm): $($msg)" -Path $ExecutionLog
    exit
}

foreach ($TempStorageLocation in $TempStorageLocations)
{
    $TempStorageLocation.MaxParallelPlots -= ($ChiaProcesses | Where {$_.CommandLine -Like "* -t $($TempStorageLocation.Path) -d *"} | Measure -ErrorAction SilentlyContinue).Count
}

$TempStorageLocation = Get-Random -InputObject ($TempStorageLocations | Where {$_.MaxParallelPlots -Gt 0})
if (!$TempStorageLocation)
{
    $msg = "No available temporary storage location - exiting"
    Write-Host $msg
    Add-Content -Value "MSG: $(get-date -f yyyy-MM-dd_HH-mm): $($msg)" -Path $ExecutionLog
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
Add-Content -Value "MSG: $(get-date -f yyyy-MM-dd_HH-mm): Plotting chia to $($TempStorageLocation.Path)" -Path $ExecutionLog
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
    Add-Content -Value "MSG: $(get-date -f yyyy-MM-dd_HH-mm): $($msg)" -Path $ExecutionLog
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
Add-Content -Path $StatusLogFilePath -Value "THREADS: $($ThreadsPerPlot)"
Add-Content -Path $StatusLogFilePath -Value "RAM: $($RAMAllocation)"
Add-Content -Path $StatusLogFilePath -Value "TEMP: $($TempStorageLocation.Path)"
Add-Content -Path $StatusLogFilePath -Value "FINAL: $($HoldingPath)"
Wait-Process $process.Id
Sleep -Seconds 3
Add-Content -Value "INFO:  $(get-date -f yyyy-MM-dd_HH-mm): $($PlotId) : $($TempStorageLocation.Path) : $($HoldingPath)" -Path $ExecutionLog
$PlotLog = Get-Content $StdOutFilePath
$Completed = $PlotLog | Select-String -Pattern '^Copied final file from ' -Quiet
if ($Completed)
{
    try
    {
        # NOTE not exactly the most robust way of pulling the capturing group out. Let's think of how we can wrap this in some decent error checking.
        $Elapsed = New-TimeSpan -Seconds ($PlotLog | Select-String -Pattern "total time = (.*?) ").Matches[0].Groups[1].Captures[0].Value
        Add-Content -Value "STAT: $(get-date -f yyyy-MM-dd_HH-mm): $($PlotId), GOOD, $($Elapsed)" -Path $ExecutionLog
    }
    catch
    {
        Add-Content -Value "STAT: $(get-date -f yyyy-MM-dd_HH-mm): $($PlotId), FAIL-MISSING-TOTAL-TIME, 0" -Path $ExecutionLog
    }

}
else
{
    Add-Content -Value "STAT: $(get-date -f yyyy-MM-dd_HH-mm): $($PlotId), FAIL-MISSING-COPY-FINAL-FILE, 0" -Path $ExecutionLog
}

if ($Config.RemoveLogsOnCompletion)
{
    Remove-Item $StatusLogFilePath -Force -ErrorAction Ignore
    Remove-Item $StdOutFilePath -Force -ErrorAction Ignore
    Remove-Item $StdErrFilePath -Force -ErrorAction Ignore
}
