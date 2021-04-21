$Config=Import-PowershellDataFile -Path .\config.psd1
$DestPath=$Config.FinalPlots.DestPath
$SrcPaths=$Config.FinalPlots.SrcPaths

$PlotFilesToMove = Get-ChildItem -Path $SrcPaths -Filter '*.plot' -ErrorAction Ignore
# TODO only permit a single instance of this script to run
echo $PlotFilesToMove
$count=0
echo "Found $($PlotFilesToMove.Count) plot files that need to be migrated."
foreach ($file in $PlotFilesToMove)
{
    $count=$count+1
    if (Test-Path -Path (Join-Path $DestPath $file.Name) -PathType Leaf)
    {
        echo ('Skipping file (' + $count + ' of ' + $PlotFilesToMove.Count + ') - "' + $file.Name + '" already exists on "' + $DestPath + '"')
        continue
    }

    echo ('Migrating plot (' + $count + ' of ' + $PlotFilesToMove.Count + ') "' + $file.Name + '" to "' + $DestPath + '"')
    try
    {
        Start-BitsTransfer -Source $file -Destination $DestPath -DisplayName 'Migrate plots to NAS' -Description ('Migrating plot (' + $count + ' of ' + $PlotFilesToMove.Count + ') "' + $file.Name + '" to "' + $DestPath + '"') -ErrorAction Stop
        Remove-Item $file -Confirm
        echo "we would delete the file here"
    }

    catch
    {
        echo "Transfer process was interrupted or failed due to network error"
        exit
    }
}
