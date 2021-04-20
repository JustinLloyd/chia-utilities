$folders=@('F:\finalplots')
foreach ($folder in $folders)
{
    $files=Get-ChildItem -Path $folder -Filter '*.plot'
    foreach ($file in $files)
    {
        $destinationpath = '\\s-lloyd-02\chia-01'
        echo $file
        # rename the file to have a .plottmp extension, move the file using robocopy to the NAS, remove the .plottmp extension
        $TempName = "$($file.Name).plottmp"
        echo "TempName", $TempName
        $TempSrcFilepath = Join-Path $file.DirectoryName $TempName
        $TempDestFilepath = Join-Path $destinationpath $TempName
        echo "TempSrcFilePath", $TempSrcFilepath
        echo "TempDestFilePath", $TempDestFilepath
        Rename-Item $file.FullName $TempSrcFilepath
        robocopy /mov $file.DirectoryName $destinationpath $TempName
        Rename-Item $TempDestFilepath (Join-Path $destinationpath $file.Name)
    }
}
