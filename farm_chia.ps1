#Requires -Version 7.0

# Description: This file launches the farmer, harvester, node and wallet and then monitors the log file at the end
# Note: This is probably the least ideal way to start up chia for farming.
$Config = Import-PowershellDataFile -Path .\config.psd1 -ErrorAction Stop
Write-Host "Launching Chia farmer"
cd ~\AppData\Local\chia-blockchain\app-*\resources\app.asar.unpacked\daemon
$WalletCount = Get-Process -Name 'start_wallet' -ErrorAction Ignore  | Measure-Object

If ($WalletCount.Count -eq 0)
{
    Write-Host "Wallet process was not found, starting it"
    Start-Process .\chia -ArgumentList "start wallet" -NoNewWindow
}

$FarmerCount = Get-Process -Name 'start_farmer' -ErrorAction Ignore  | Measure-Object

If ($FarmerCount.Count -eq 0)
{
    Write-Host "Farmer process was not found, starting it"
    Start-Process .\chia -ArgumentList "start farmer" -NoNewWindow
}

$HarvesterCount = Get-Process -Name 'start_harvester' -ErrorAction Ignore  | Measure-Object

If ($HarvesterCount.Count -eq 0)
{
    Write-Host "Harvester process was not found, starting it"
    Start-Process .\chia -ArgumentList "start harvester" -NoNewWindow
}

$FullNodeCount = Get-Process -Name 'start_full_node' -ErrorAction Ignore  | Measure-Object

If ($FullNodeCount.Count -eq 0)
{
    Write-Host "Full node process was not found, starting it"
    Start-Process .\chia -ArgumentList "start node" -NoNewWindow
}


#Start-Process .\chia -ArgumentList "start node" -NoNewWindow
#Start-Process .\chia -ArgumentList "start farmer" -NoNewWindow
#Start-Process .\chia -ArgumentList "start harvester" -NoNewWindow
Write-Host "Waiting a few seconds before showing logs"
Start-Sleep -Seconds 20
Get-Content ~\.chia\mainnet\log\debug.log -wait | where {$_ -Like '*chia.harvester.harvester: INFO*'} | where {$_ -NotLike '*chia.harvester.harvester: INFO 0*'}
