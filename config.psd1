@{
  # Holding Paths are fast temporary storage on the plotter where we keep the
  # plots until they can be migrated off to the slower storage of the NAS
    HoldingPaths = @(
    "d:\finalplots"
#    "f:\finalplots"
    )
    # Intermediate Path is slower network storage where plots will be placed
    # until they can be pull down by the harvesters
    # In this particular case, the network storage is the Synology NAS with
    # many terabytes of slow, spinning drives that all farming machines can
    # access
    IntermediatePath ="\\s-lloyd-02\chia-01"
    MaxParallelPlots = 32
    ThreadsPerPlot = 2
    LoggingPath = "d:\logs"
    MaxPhase1Plots = 12
    RAMAllocation = 6750
    MaxPhase1PlotsPerTempPath = 2
    RemoveLogsOnCompletion = $true
    TempStorageLocations = @(
        @{
            Path = "c:\chia"
            MaxParallelPlots = 2
        }
        # @{
        #     Path = "d:\chia"
        #     MaxParallelPlots = 2
        # }
        @{
            Path = "e:\chia"
            MaxParallelPlots = 3
        }
        # @{
        #     Path = "f:\chia"
        #     MaxParallelPlots = 3
        # }
        @{
            Path = "g:\chia"
            MaxParallelPlots = 3
        }
        @{
            Path = "i:\chia"
            MaxParallelPlots = 3
        }
        @{
            Path = "j:\chia"
            MaxParallelPlots = 3
        }
        @{
            Path = "k:\chia"
            MaxParallelPlots = 3
        }
        @{
            Path = "l:\chia"
            MaxParallelPlots = 3
        }
        @{
            Path = "n:\chia"
            MaxParallelPlots = 3
        }
    )

    SecondaryTempStorageLocations = @(
        @{
            Path = "d:\chia"
        }
        # @{
        #     Path = "c:\chia"
        # }
    )
    # define locations where Chia will be farming from
    # if you have many drives and use directory mount points instead of drive
    # letters you can specify a common root directory and have the migration
    # script recurse through the directories looking for mount points
    # my configuration consists of 24 drives in an internal array mounted at
    # c:\chia\internal and a further 45 drives in an external unit mounted at
    # c:\chia\external01, with 24 drives on  the front of the external unit 
    # and 21 drives on the back of the external unit. I mount each drive
    # column/row order, e.g. D: is mounted at c:\chia\internal\col00-row00
    # and E: is mounted at c:\chia\internal\col00-row01.
    # Because c:\chia\internal is a directory that resides on a much smaller
    # 1TB SSD I don't want to place plots in c:\chia\internal so the flag
    # SkipRootPath will ignore c:\chia\internal as a possible storage location.
    # The AddToChia flag will automatically add the directory to the chia farmer
    # in case it isn't already configured.
    Farming = @{
        Recurse = $true
        AddToChia = $true
        SkipRootPath = $true
        Paths = @(
            # the 24-bay server
            "c:\chia\internal"
            # the 45-bay jbod
            "c:\chia\external01\front"
            "c:\chia\external01\back"
        )
    }
}

