#Requires -Version 7.0
Set-StrictMode -Version 3.0

# Description: This file copies plots from the plotter to the NAS
$Config=Import-PowershellDataFile -Path .\config.psd1 -ErrorAction Stop
$IntermediatePath = $Config.IntermediatePath
$HoldingPaths = $Config.HoldingPaths
$LoggingFilePath = Join-Path $Config.LoggingPath "migration.log"
$PlotFilesToMove = Get-ChildItem -Path $HoldingPaths -Filter '*.plot' -ErrorAction Ignore
# verify there are actually plots that need migrating
if ($PlotFilesToMove -eq $null)
{
    $msg = "Did not locate any plot files that need to migrate"
    echo $msg
    Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
    exit
}

# only permit a single instance of this script to run - simpel check, look to see if the script is already executing
if (Get-Process -Name 'pwsh' | Where { $_.CommandLine -Like '*migrate_plots_to_nas*' })
{
    $msg = "Already migrating plots"
    echo $msg
    Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
    exit
}

#echo $PlotFilesToMove
$FileIndex = 0

$StartTime = Get-Date
$msg = "Found $($PlotFilesToMove.Length) plot files that need to be migrated."
echo $msg
Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
foreach ($PlotFile in $PlotFilesToMove)
{
    $FileIndex = $FileIndex + 1
    if (Test-Path -Path (Join-Path $IntermediatePath $PlotFile.Name) -PathType Leaf)
    {
        $msg = 'Skipping file (' + $FileIndex + ' of ' + $PlotFilesToMove.Length + ') - "' + $PlotFile.Name + '" already exists on "' + $IntermediatePath + '"' 
        echo $msg
        Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
        continue
    }

    $msg = 'Migrating plot (' + $FileIndex + ' of ' + $PlotFilesToMove.Length + ') "' + $PlotFile.Name + '" to "' + $IntermediatePath + '"'
    echo $msg
    Add-Content -Path $LoggingFilePath "$(Get-Date -f yyyy-MM-dd_HH-mm): $($msg)"
    try
    {
        Start-BitsTransfer -Source $PlotFile -Destination $IntermediatePath -DisplayName 'Migrate plots to NAS' -Description ('Migrating plot (' + $FileIndex + ' of ' + $PlotFilesToMove.Length + ') "' + $PlotFile.Name + '" to "' + $IntermediatePath + '"') -ErrorAction Stop
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
