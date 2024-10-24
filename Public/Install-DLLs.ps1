function Install-DLLs 
{
    param (
        [Switch] $Async,
        [String] $InvSource,
        [String] $RelSource,
        [System.Collections.Generic.List[Server]] $Servers = @(),
        [String] $Session,
        [String] $StageTo
     )
    
    $AgentServers = $Servers | Where-Object { $_.Role -contains 'Agent' -or $_.Roles -contains 'Web' }
    $InvariantServers = $Servers | Where-Object { $_.Role -contains 'Worker' }

    [System.Collections.Generic.List[Plan]] $Plans = @()

    # Clear Old Data
    $Plan = [Plan_RemoveOldData]::new(
        $Servers.Name,
        $Session,
        $StageTo,
        $Async)
    $Plan.WriteProgressActivity = "Clearing out old hotfix and Relativity data"
    $Results = $Plan.Run()
    $Plans.Add($Plan)

    # Stage RelativityDroptit
    if($AgentServers)
    {
        $Plan = [Plan_CopyFiles]::new(
            $AgentServers.Name,
            $Session,
            $RelSource,
            $StageTo,
            "",
            $false,
            $Async)
        $Plan.WriteProgressActivity = "Copying Relativity DropIt Files"
        $Results = $Plan.Run()
        $Plans.Add($Plan)
    }

    # Stage InvariantDroptit
    if($InvariantServers)
    {
        $Plan = [Plan_CopyFiles]::new(
            $InvariantServers.Name,
            $Session,
            $InvSource,
            $StageTo,
            "",
            $false,
            $Async)
        $Plan.WriteProgressActivity = "Copying Invariant DropIt Files"
        $Results = $Plan.Run()
        $Plans.Add($Plan)
    }

    #Install RelDropit Dlls
    $Plan = [Plan_InstallDLLs]::new($Servers, $Session, $StageTo, $Async)
    $Results = $Plan.Run()
    $Plans.Add($Plan)

    return $Plans
}