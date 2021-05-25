using namespace System.Windows
using namespace System.Windows.Threading


# Define a custom DoEvents()-like function that processes GUI WPF events and can be 
# called in a custom event loop in the foreground thread.
# Adapted from: https://docs.microsoft.com/en-us/dotnet/api/system.windows.threading.dispatcherframe
function DoWpfEvents {
  [DispatcherFrame] $frame = [DispatcherFrame]::new($True)
  $null = [Dispatcher]::CurrentDispatcher.BeginInvoke(
    'Background', 
    [DispatcherOperationCallback] {
      param([object] $f)
      ($f -as [DispatcherFrame]).Continue = $false
      return $null
    }, 
    $frame)
  [Dispatcher]::PushFrame($frame)
}
try 
{
    Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase, System.Windows.Forms, System.Drawing 
}
catch 
{
    Throw 'Failed to load Windows Presentation Framework assemblies.'
}

$xaml = Get-Content -path "./giles/MainWindow.xaml" -Raw 
[xml]$xaml = $xaml -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
$reader = [System.xml.XmlNodeReader]::new($xaml)
$formMain = [System.Windows.Markup.XamlReader]::Load($reader)

$xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")  | ForEach-Object { 
    echo $_.Name
  New-Variable  -Name $_.Name -Value $formMain.FindName($_.Name) -Force 
}

$btnClose.Add_Click({$formMain.Close()})
$formMain.Show()
 while ($formMain.IsVisible) {

#   # Process GUI events.
   DoWpfEvents

   Start-Sleep -Milliseconds 50

}
$formMain.Close()
# $Form.ShowDialog()

# $WPFGuiAlert2 = New-WPFDialog -XamlData $WPFXamlAlertFixed
# $WPFGuiAlert2.Message10.Text = "Session Manager"
# # $WPFGuiAlert.ApplicationExitCode = 99

# <#  CODE  #>

# $null = $WPFGUIAlert2.UI.Dispatcher.InvokeAsync{ $WPFGuiAlert2.UI.Show() }.Wait()


# }

# Do {

# New-PopUpWindowStart

# If ( $Script:VarStart -eq $true ) { 

#     New-PopUpWindowAlertFixed
    

#     $Script:VarLoop = 1

#     <# I'd like to close the Dialog here #>

    
# }
