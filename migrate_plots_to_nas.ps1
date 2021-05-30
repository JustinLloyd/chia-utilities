#Requires -Version 7.0
Set-StrictMode -Version 3.0

# Description: This file copies plots from the plotter to the NAS
$Config = Import-PowershellDataFile -Path .\config.psd1 -ErrorAction Stop
$IntermediatePath = $Config.IntermediatePath
$HoldingPaths = $Config.HoldingPaths
$LoggingFilePath = Join-Path $Config.LoggingPath "migration.log"
$PlotFilesToMove = Get-ChildItem -Path $HoldingPaths -Filter '*.plot' -ErrorAction Ignore
# we use a mutex lock to only permit a single instance of this script to run
[System.Threading.Mutex]$Mutex = $null

# verify there are actually plots that need migrating
if ($PlotFilesToMove -eq $null)
{
    $msg = "Did not locate any plot files that need to migrate"
    echo $msg
    Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
    exit
}

# wrapped in a try/finally block to ensure our mutex release runs when the script exits even if we CTRL+C the script or the script errors out for some reason
try
{
    # acquire a mutex lock to ensure only a single instance of the script is running
    $MutexAcquired = $false
    $Mutex = New-Object System.Threading.Mutex($true, 'migrate_plots_to_nas', [ref] $MutexAcquired)
    # if we cannot acquire a mutex lock then we just exit gracefully
    if (!$MutexAcquired)
    {
        $msg = "Already migrating plots"
        echo $msg
        Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
        $Mutex.Dispose()
        $Mutex = $null
        exit
    }

    # we're the only instance of the script, let's start migrating those plots
    #echo $PlotFilesToMove
    $FileIndex = 0

    $StartTime = Get-Date
    $msg = "Found $($PlotFilesToMove.Count) plot files that need to be migrated."
    echo $msg
    Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
    foreach ($PlotFile in $PlotFilesToMove)
    {
        $FileIndex = $FileIndex + 1
        if (Test-Path -Path (Join-Path $IntermediatePath $PlotFile.Name) -PathType Leaf)
        {
            $msg = 'Skipping file (' + $FileIndex + ' of ' + $PlotFilesToMove.Count + ') - "' + $PlotFile.Name + '" already exists on "' + $IntermediatePath + '"' 
            echo $msg
            Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
            continue
        }

        $msg = 'Migrating plot (' + $FileIndex + ' of ' + $PlotFilesToMove.Count + ') "' + $PlotFile.Name + '" to "' + $IntermediatePath + '"'
        echo $msg
        Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
        try
        {
            Start-BitsTransfer -Source $PlotFile -Destination $IntermediatePath -DisplayName 'Migrate plots to NAS' -Description ('Migrating plot (' + $FileIndex + ' of ' + $PlotFilesToMove.Count + ') "' + $PlotFile.Name + '" to "' + $IntermediatePath + '"') -ErrorAction Stop
            $MovedPlotFile = Get-ChildItem -Path (Join-Path $IntermediatePath $PlotFile.Name) -File -ErrorAction Ignore
            if ($MovedPlotFile -eq $null)
            {
                $msg = "Failed to correctly move file $($PlotFile.FullName). It doesn't exist on the destination path at $($IntermediatePath). Double-check everything and try again. Aborting so you don't lose any plots."
                echo $msg
                Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
                exit
            }
            if ($MovedPlotFile.Length -ne $PlotFile.Length)
            {
                $msg = "Failed to correctly move file $($PlotFile.FullName). The size of the plot file at the destination path $(Join-Path $IntermediatePath $PlotFile.Name) differs from the size of file at $($PlotFile.Fullname). Double-check everything and try again. Aborting so you don't lose any plots."
                echo $msg
                Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
                Remove-Item (Join-Path $IntermediatePath $PlotFile.Name) -ErrorAction Ignore
                exit
            }

            Remove-Item $PlotFile
        }

        catch
        {
            $msg = "Transfer process was interrupted or failed due to network error"
            echo $msg
            Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
            exit
        }
    }

    $EndTime = Get-Date
    $msg = "Plot migration complete - total time $($EndTime - $StartTime)"
    echo $msg
    Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
}

# no matter what happens, we want to make sure we release the mutex lock we acquired
finally
{
    if ($Mutex)
    {
        $Mutex.ReleaseMutex()
        $Mutex.Dispose()
        $Mutex = $null
    }
}

