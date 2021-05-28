# Chia XCH Plotting Utilities

Some basic PowerShell scripts I use for assisting me when plotting out Chia (XCH) crypto.

Requirements: Windows 10, Powershell 7.0 or above. I'm running PowerShell 7.1 as of this writing.

## Scheduled Tasks
I run these scripts from the Task Scheduler and they are configured to run at various intervals. Each Scheduled Task launches a small .vbs script that then launches the actual PowerShell script that I want. This prevents any extraneous windows popping-up on my desktop.

There is a script named `schedule_plotter_tasks.ps1` that you can use as a starting point for creating your own scheduled tasks. The script will create the scheduled tasks and then immediately disable them, just in case you haven't edited the path to the .vbs files, or have the desired stagger time.

## Plot Chia
Creates a single chia plot with parameters pulled from the configuration file.

Will only launch a new plot creation process if there are less than N plots already in process.

The configuration file defines one or more temporary storage locations where plots are created. Each storage location can have a maximum number of parallel plots that can be plotting at any particular moment. The script will verify it is not attempting to create more plots on the temporary storage location than the storage location is permitted to host.

This script would be run from Task Scheduler at regular intervals. I set my workstation up to launch this script about once every 15 minutes.

There is an attendant .vbs script that is run by the Task Scheduler that launches the actual PowerShell script. This VBS script ensures that no window flashes up when the script is launched from Task Scheduler.

## Plot Status
Obtains status information about curent plots. This script defines a function called `Get-PlotStatus.` Dot source the plot_status file into your environment or other script and then invoke `Get-PlotStatus`

```
. .\plot_status.ps1
Get-PlotStatus| Where { $_.active } | Sort Elapsed | ft Pid,Phase,Elapsed
```

Will display all currently active plots, the phase they are currently in and how long the plot has been running for.

This script is a work in progress and at the prototype stage.

This script only works if the plots were launched via `plot_chia.ps1` script.

## Trim SSDs
The script `trim_ssds.ps1` will force a TRIM to be performed on all SSDs attached to your system. I've noticed that a once a day trim will boost plotting performance significantly. The problem with the Windows 10 scheduled trim is that either it doesn't run at all, doesn't run often enough, or runs at such low priority that your drive never gets the chance to execute the low-priority trim operation due to the continuous plotting operations that are underway. This script fixes that by forcing the trim. Don't trim too oftn, a trim does in fact shorten the lifespan of your SSD, by a very small amount, and one trim per day for a year will shorten the lifespan by around 0.1%, but it does add up and isn't a recommended practice to perform it all the time. Under normal circumstances on a large (1TB or higher) SSD that is only 80% full and isn't being continuously written too over-and-over again, the exact opposite of a plotting operation, a once a month trim is sufficient.

* NOTE: This script must be execute with Administrative privileges.

## Migrate Plots To NAS
My plotting setup consists of a separate plotting machine with some fast SSDs attached. Once a plot is completed it is moved to a slower SSD ready for offload to the farm server.

My plotter does not have direct access to the farm server storage. There is an intermediate storage server (My Synology NAS) that temporarily holds plots for the farm server. The `migrate_plots_to_nas.ps` script will move plots from the plotter to the NAS.

This script is stateless and can be interrupted at any time.

I run this script on a scheduled task once every few hours.

Only a single instance of this script can execute at any time so an overlapping Task Schedule won't cause any issues.

## Migrate Plots From NAS
At a regular interval the farmer migrates plots from the NAS to local hard drives. The `migrate_plots_from_nas.ps1` script queries all attached spinning rust hard drives (ignores SSD) for available space, picks the HDD with the least amount of space that can fit the largest plot available and migrates the plot to that HDD.

The script iterates over this process until all of the plots stored on the NAS have migrated to their final resting place.

This script is stateless and can be interrupted at any time.

This script runs as a scheduled task every few hours.

## Farm Chia
Launches the full node, wallet, harvester and farmer from the CLI if they are not already launched.

This code is very prototype and probably the least optimal and incorrect way of doing this.

This script would be run at regular interval from Task Scheduler to restart any stopped processes.

