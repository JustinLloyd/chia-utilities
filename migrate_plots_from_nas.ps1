#Requires -Version 7.0

# Description: This file copies the plots from the NAS to the farming drives
$Config = Import-PowershellDataFile -Path .\config.psd1 -ErrorAction Stop
$IntermediatePath = $Config.IntermediatePath
# TODO change destination folders to be source folders 
# TODO add destination folders list
# TODO add a switch to toggle between any and all HDDs and specified destination folders
# TODO verify only one instance is running at a time (PID check or get-process)

# get a list of all plots files on the NAS sorted by size in descending order, so the biggest files are listed first
$PlotFilesToMove = Get-ChildItem -Path $IntermediatePath -Filter '*.plot' -ErrorAction Ignore | Sort -Descending -Property Length

echo "Found $($PlotFilesToMove.Count) plot files that need to be migrated."
$FileIndex = 0
foreach ($PlotFile in $PlotFilesToMove)
{
    $FileIndex = $FileIndex + 1
    # Find a spinning rust hard drive with the least amount of space capable of storing the largest plot file
    $TargetDrive = Get-PhysicalDisk | Where -Property MediaType -eq -Value HDD | Get-Disk | Get-Partition | Get-Volume | Sort -Property SizeRemaining | Where -Property SizeRemaining -ge -Value $PlotFile.Length | Select -First 1
    # TODO add error checking to ensure we have a drive capable of storing our plot file
    # if we cannot store the plot file, what do we want to do? throw an error? skip the plot file?
    $DestinationPath = $TargetDrive.DriveLetter + ':\'
    echo ('Migrating plot (' + $FileIndex + ' of ' + $PlotFilesToMove.Count + ') "' + $PlotFile.Name + '" to "' + $DestinationPath + '"')
    try
    {
        Start-BitsTransfer -Source $PlotFile -Destination $DestinationPath `
            -DisplayName 'Migrate plots from NAS' `
            -Description ('Migrating plot (' + $FileIndex + ' of ' + $PlotFilesToMove.Count + ') "' + $PlotFile.Name + '" to "' + $DestinationPath + '"') `
            -ErrorAction Stop
        Remove-Item $PlotFile
    }

    catch
    {
        echo "Transfer process was interrupted or failed due to network error"
        exit
    }

}
