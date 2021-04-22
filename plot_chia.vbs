rem Description: Launch the plotting script using powershell and make sure no new window pops up
Dim shell,command
Set shell = CreateObject("WScript.Shell")
shell.CurrentDirectory = "c:\users\justin\SynologyDrive\Development\chia-utilities\"
command = "pwsh.exe -nologo -File c:\users\justin\SynologyDrive\Development\chia-utilities\plot_chia.ps1"
shell.Run command,0