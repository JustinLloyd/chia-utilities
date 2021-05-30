#Requires -Version 7.0

# Description: Performs a trim command on all of the SSDs attached to the system
# NOTE: This needs to run from an elevated PowerShell

Function Trim-SSDs
{
    Get-PhysicalDisk | Where -Property MediaType -eq -Value SSD | Get-Disk | Get-Partition -ErrorAction Ignore | Get-Volume | Optimize-Volume -Retrim -ErrorAction Ignore
}