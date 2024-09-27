function Install-Relativity
{
    <#
        .DESCRIPTION
            Performs an installation of the relativity.exe installer.

        .FUNCTIONALITY
            [Server].Role will guide this operation.
            [Server].ResponseFileProperties will guide installation parameters.
            [PathTable] will provide remote and local installation paths.
    #>
    param(
        [Switch]$Async,
        [System.Collections.Generic.List[Server]] $RssServers = @(),
        [System.Collections.Generic.List[Server]] $Servers = @(),
        [PathTable]$Paths = [PathTable]::new(),
        [Switch]$Validate,
        [String]$Session,
        [Switch]$SkipPreConfig,
        [String]$WriteProgressActivity,
        [Switch]$WriteProgress,
        [Int32]$WriteProgressID = 0
    )


    $Plan = [Plan_Install_Relativity]::new(
        $Servers,
        $RssServers,
        $Paths,
        $Session,
        $Validate,
        $SkipPreConfig,
        $Async)
    
    $Plan.WriteProgress = $WriteProgress
    $Plan.WriteProgressActivity = $WriteProgressActivity
    $Plan.WriteProgressID = $WriteProgressID

    $Plan.Run() | Out-Null

    return $Plan
}