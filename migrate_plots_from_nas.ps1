#Requires -Version 7.0

# Description: This file copies the plots from the NAS to the farming drives
$Config = Import-PowershellDataFile -Path .\config.psd1 -ErrorAction Stop
$IntermediatePath = $Config.IntermediatePath
$Farming = $Config.Farming
$FarmingPaths = $Farming.Paths
$LoggingFilePath = Join-Path $Config.LoggingPath "migration.log"
# TODO change destination folders to be source folders 
# TODO add destination folders list
# TODO add a switch to toggle between any and all HDDs and specified destination folders
# TODO verify only one instance is running at a time (PID check or get-process)

$Params = @{}
if ($Config.Farming.SkipRootPath) 
{
    $Params['exclude'] = $path
}

if ($Config.Farming.Recurse)
{
    $Params['recurse'] = $true
}

# we use a mutex lock to only permit a single instance of this script to run
[System.Threading.Mutex]$Mutex = $null
# wrapped in a try/finally block to ensure our mutex release runs when the script exits even if we CTRL+C the script or the script errors out for some reason
try
{
    # acquire a mutex lock to ensure only a single instance of the script is running
    $Mutex = New-Object System.Threading.Mutex($false, 'migrate_plots_from_nas')
    $MutexAcquired = $false
    try
    {
        $MutexAcquired = $Mutex.WaitOne(0)
    }
    catch [System.Threading.AbandonedMutexException]
    {
        $msg = "A previous execution of the migration script did not cleanly exit."
        echo $msg
        Add-Content -Path $LoggingFilePath "DBG: $(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
        $MutexAcquired = $true
    }

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

    $FarmingPaths = Get-Childitem -Path $Config.Farming.Paths @Params -Directory | Select Fullname

    # get a list of all plots files on the NAS sorted by size in descending order, so the biggest files are listed first
    $PlotFilesToMove = Get-ChildItem -Path $IntermediatePath -Filter '*.plot' -ErrorAction Ignore | Sort -Descending -Property Length

    $msg = "Found $($PlotFilesToMove.Count) plot files that need to be migrated."
    echo $msg
    Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"

    $FileIndex = 0
    foreach ($PlotFile in $PlotFilesToMove)
    {
        $FileIndex = $FileIndex + 1

        # Find a storage location with the least amount of space capable of storing the largest plot file
        $Destination = $FarmingPaths | Select Fullname, @{Name="SizeRemaining"; Expression={(Get-Volume -filepath $_.Fullname).SizeRemaining}} | Sort -Property SizeRemaining | Where -Property SizeRemaining -ge -Value $PlotFile.Length | Select -First 1
        if (!$Destination)
        {
            $msg = "None of the defined storage locations have enough free space to store plot $($PlotFile)"
            echo $msg
            Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
            Continue
        }

        $msg = 'Migrating plot (' + $FileIndex + ' of ' + $PlotFilesToMove.Count + ') "' + $PlotFile.Name + '" to "' + $Destination.FullName + '"'
        echo $msg
        Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
        try
        {
            Start-BitsTransfer -Source $PlotFile -Destination $Destination.FullName `
                -DisplayName 'Migrate plots from NAS' `
                -Description ('Migrating plot (' + $FileIndex + ' of ' + $PlotFilesToMove.Count + ') "' + $PlotFile.Name + '" to "' + $Destination.FullName + '"') `
                -ErrorAction Stop
            Remove-Item $PlotFile
        }

        catch
        {
            $msg = "Transfer process was interrupted or failed due to network error or lack of storage space."
            echo $msg
            Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
            exit
        }

    }

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
