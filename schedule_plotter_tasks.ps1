#UnRegister-ScheduledTask -TaskPath "\Chia\" -TaskName "Plot Chia" -ErrorAction ignore -Confirm:$false
$action = New-ScheduledTaskAction -Execute 'C:\Users\justin\SynologyDrive\Development\chia-utilities\plot_chia.vbs'
$trigger =  New-ScheduledTaskTrigger -Once -At 9am -RepetitionInterval (New-TimeSpan -Minutes 20)
Register-ScheduledTask -TaskPath "\Chia" -Action $action -Trigger $trigger -TaskName "Plot Chia" -Description "Plot Chia at a staggered interval" -Force
Disable-ScheduledTask -TaskName "Plot Chia" -TaskPath "\Chia"

$action = New-ScheduledTaskAction -Execute 'C:\Users\justin\SynologyDrive\Development\chia-utilities\migrate_plots_to_nas.vbs'
$trigger =  New-ScheduledTaskTrigger -Once -At 9am -RepetitionInterval (New-TimeSpan -Hours 6)
Register-ScheduledTask -TaskPath "\Chia" -Action $action -Trigger $trigger -TaskName "Migrate Plots To NAS" -Description "Migrate the plots to the NAS" -Force
Disable-ScheduledTask -TaskName "Migrate Plots To NAS" -TaskPath "\Chia"

echo "If you ran this script without editing the paths and stagger intervals first, then you should do that now by opening the Task Scheduler."
echo "The Scheduled Tasks are created and then disabled so you can double-check everything before enabling them."