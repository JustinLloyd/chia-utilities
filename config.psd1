@{
  # Holding Paths are fast temporary storage on the plotter where we keep the
  # plots until they can be migrated off to the slower storage of the NAS
    HoldingPaths = @(
    "c:\finalplots"
#    "f:\finalplots"
    )
    # Intermediate Path is slower network storage where plots will be placed
    # until they can be pull down by the harvesters
    # In this particular case, the network storage is the Synology NAS with
    # many terabytes of slow, spinning drives that all farming machines can
    # access
    IntermediatePath ="\\s-lloyd-02\chia-01"
    MaxParallelPlots = 15
    ThreadsPerPlot = 16
    LoggingPath = "F:\logs"
    TempStorageLocations = @(
        @{
            Path = "c:\chia"
            MaxParallelPlots = 5
        }
        @{
            Path = "d:\chia"
            MaxParallelPlots = 5
        }
        @{
            Path = "f:\chia"
            MaxParallelPlots = 3
        }
    )
}