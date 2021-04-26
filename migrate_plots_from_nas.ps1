#Requires -Version 7.0

# Description: This file copies the plots from the NAS to the farming drives
$Config = Import-PowershellDataFile -Path .\config.psd1 -ErrorAction Stop
$IntermediatePath = $Config.IntermediatePath
$Farming = $Config.Farming
$FarmingPaths = $Farming.Paths
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

$FarmingPaths = Get-Childitem -Path $Config.Farming.Paths @Params -Directory | Select Fullname

# get a list of all plots files on the NAS sorted by size in descending order, so the biggest files are listed first
$PlotFilesToMove = Get-ChildItem -Path $IntermediatePath -Filter '*.plot' -ErrorAction Ignore | Sort -Descending -Property Length

echo "Found $($PlotFilesToMove.Count) plot files that need to be migrated."
$FileIndex = 0
foreach ($PlotFile in $PlotFilesToMove)
{
    $FileIndex = $FileIndex + 1

    # Find a storage location with the least amount of space capable of storing the largest plot file
    $Destination = $FarmingPaths | Select Fullname, @{Name="SizeRemaining"; Expression={(Get-Volume -filepath $_.Fullname).SizeRemaining}} | Sort -Property SizeRemaining | Where -Property SizeRemaining -ge -Value $PlotFile.Length | Select -First 1
    if (!$Destination)
    {
        echo "None of the defined storage locations have enough free space to store plot $($PlotFile)"
        Continue
    }

    echo ('Migrating plot (' + $FileIndex + ' of ' + $PlotFilesToMove.Count + ') "' + $PlotFile.Name + '" to "' + $Destination.FullName + '"')
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
        echo "Transfer process was interrupted or failed due to network error or lack of storage space."
        exit
    }

}