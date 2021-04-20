# Description: This file copies the plots from the NAS to the farming drives
$folders=@('\\s-lloyd-02\chia-01\*.plot')
# clean up .farmtmp files on destination drives
# change folders to be source folders 
# add destination folders list
# add a switch to toggle between HDDs and specified desintation folders
# add a config.yaml
# read settings from config.yaml
# verify only one instance is running at a time (PID check or get-process)
# reprocess robocopy output to make a nicer progress bar and cleaner output
foreach ($folder in $folders)
{
    $files=dir $folder | sort -descending -property length
    foreach ($biggestfile in $files)
    {
        echo $biggestfile
        $targetdrive=get-physicaldisk | where -property mediatype -eq -value HDD |  Get-Disk | Get-Partition | Get-Volume | sort -Property sizeremaining | where -property sizeremaining -ge -value $biggestfile.length | select -first 1
    #    echo $targetdrive

        $destinationpath = $targetdrive.DriveLetter + ':\'
    #    echo $destinationpath
        # rename the file to have a .farmtmp extension, move the file using robocopy to the final resting place, remove the .farmtmp extension
        $TempName = "$($biggestfile.Name).farmtmp"
        echo "TempName", $TempName
        $TempSrcFilepath = Join-Path $biggestfile.DirectoryName $TempName
        $TempDestFilepath = Join-Path $destinationpath $TempName
        echo "TempSrcFilePath", $TempSrcFilepath
        echo "TempDestFilePath", $TempDestFilepath
        Rename-Item $biggestfile.FullName $TempSrcFilepath
        robocopy /mt /j /mov $biggestfile.DirectoryName $destinationpath $TempName
        Rename-Item $TempDestFilepath (Join-Path $destinationpath $biggestfile.Name)

    # move-item -path $biggestfile -destination $destinationpath -verbose
    }
}
