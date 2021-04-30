function Get-DriveStatus
{
    Get-PhysicalDisk | Get-StorageReliabilityCounter | sort temperature | ft Temperature,TemperatureMax,*latency*,Wear,DeviceId
}