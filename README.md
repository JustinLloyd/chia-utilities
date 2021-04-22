# Chia XCH Plotting Utilities

Some basic PowerShell scripts I use for assisting me when plotting out Chia (XCH) crypto.

## Migrate Plots To NAS
My plotting setup consists of a separate plotting machine with some fast SSDs attached. Once a plot is completed it is moved to a slower SSD ready for offload to the farm server.

My plotter does not have direct access to the farm server storage. There is an intermediate storage server (My Synology NAS) that temporarily holds plots for the farm server. The "migrate_plots_to_nas" script will move plots from the plotter to the NAS.

This script is stateless and can be interrupted at any time.

I run this script on a scheduled task once every few hours.

## Migrate Plots From NAS
At a regular interval the farmer migrates plots from the NAS to local hard drives. The "migrate_plots_from_nas" script queries all attached spinning rust hard drives (ignores SSD) for available space, picks the HDD with the least amount of space that can fit the largest plot available and migrates the plot to that HDD.

The script iterates over this process until all of the plots stored on the NAS have migrated to their final resting place.

This script is stateless and can be interrupted at any time.

This script runs as a scheduled task every few hours.

## Farm Chia
Launches the full node, wallet, harvester and farmer from the CLI if they are not already launched.

This code is very prototype and probably the least optimal and incorrect way of doing this.

This script would be run at regular interval from Task Scheduler to restart any stopped processes.

## Plot Chia
Creates a single chia plot with parameters pulled from the configuration file.

Will only launch a new plot creation process if there are less than N plots already in process.

This script would be run from Task Scheduler at regular intervals.

## Plot Status
Prints out statistical information about past plots and status of current plots.

This script is a work in progress and at the prototype stage.