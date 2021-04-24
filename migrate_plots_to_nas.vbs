rem Description: Launch the migration to NAS script using powershell and make sure no new window pops up
Dim shell,command
Set shell = CreateObject("WScript.Shell")
shell.CurrentDirectory = "c:\users\justin\SynologyDrive\Development\chia-utilities\"
command = "pwsh.exe -nologo -File c:\users\justin\SynologyDrive\Development\chia-utilities\migrate_plots_to_nas.ps1"
shell.Run command,0