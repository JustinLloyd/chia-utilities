#Requires -Version 7.0

# Description: Extracts the number of plots that passed filter, number of proofs found, and the amount of time it took to do so from the log files
# Usage: Dot source the file then invoke Get-FilterProofs
# You can sort by time by issuing `. .\get_proofs.ps1;Get-FilterProofs | Sort Time`
# NOTE: Log files must be configured with INFO level logging

function Get-FilterProofs
{
    gc ~\.chia\mainnet\log\*.log* | ? {$_ -match "INFO.*(?<Plots>\d+) plots.*Found (?<Proofs>\d+).*Time\: (?<Time>\d+\.\d+) s"} | %{$matches} | select Plots,Proofs,Time
}