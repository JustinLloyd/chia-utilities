# Description: This file copies the plots from the NAS to the farming drives
$Config = Import-PowershellDataFile -Path .\config.psd1
$IntermediatePath = $Config.IntermediatePath
# clean up .farmtmp files on destination drives
# change folders to be source folders 
# add destination folders list
# add a switch to toggle between HDDs and specified desintation folders
# add a config.yaml
# read settings from config.yaml
# verify only one instance is running at a time (PID check or get-process)
# reprocess robocopy output to make a nicer progress bar and cleaner output
# get a list of all plots files on the NAS sorted by size in descending order, so the biggest files are listed first
$PlotFilesToMove = Get-ChildItem -Path $IntermediatePath -Filter '*.plot' -ErrorAction Ignore `
    | Sort -Descending -Property Length
foreach ($PlotFile in $PlotFilesToMove)
{
    echo $PlotFile
    # FInd a spinning rust hard drive with the least amount of space capable of storing the largest plot file
    $TargetDrive = Get-PhysicalDisk | Where -Property MediaType -eq -Value HDD `
        | Get-Disk | Get-Partition | Get-Volume `
        | Sort -Property SizeRemaining `
        | Where -Property SizeRemaining -ge -Value $PlotFilesToMove.Length `
        | Select -First 1
    # TODO add error checking to ensure we have a drive capable of storing our plot file
    # if we cannot store the plot file, what do we want to do? throw an error? skip the plot file?
#    echo $targetdrive

    $DestinationPath = $TargetDrive.DriveLetter + ':\'
    try
    {
        Start-BitsTransfer -Source $PlotFile -Destination $DestinationPath `
            -DisplayName 'Migrate plots from NAS' `
            -Description ('Migrating plot (' + $count + ' of ' + $PlotFilesToMove.Count + ') "' + $file.Name + '" to "' + $DestinationPath + '"') `
            -ErrorAction Stop
        Remove-Item $PlotFile -Confirm
    }

    catch
    {
        echo "Transfer process was interrupted or failed due to network error"
        exit
    }

#    echo $destinationpath
    # rename the file to have a .farmtmp extension, move the file using robocopy to the final resting place, remove the .farmtmp extension
    #$TempName = "$($biggestfile.Name).farmtmp"
    #echo "TempName", $TempName
    #$TempSrcFilepath = Join-Path $biggestfile.DirectoryName $TempName
    #$TempDestFilepath = Join-Path $destinationpath $TempName
    #echo "TempSrcFilePath", $TempSrcFilepath
    #echo "TempDestFilePath", $TempDestFilepath
    #Rename-Item $biggestfile.FullName $TempSrcFilepath
    #robocopy /mt /j /mov $biggestfile.DirectoryName $destinationpath $TempName
    #Rename-Item $TempDestFilepath (Join-Path $destinationpath $biggestfile.Name)

# move-item -path $biggestfile -destination $destinationpath -verbose
}
