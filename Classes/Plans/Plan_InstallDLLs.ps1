class Plan_InstallDLLs : Plan
{
    [System.Collections.Generic.List[Server]] $Servers = @()
    [String] $StagePath

    Plan_InstallDLLs($servers, $session, $stagePath, $async)
    {
        $this.Async = $async
        $this.Hostnames = $servers.Name
        $this.Servers = $servers
        $this.SessionName = $session
        $this.StagePath = $stagePath
        $this.Init()
    }

    Init()
    {
        $this.Servers | ForEach-Object {
            $roles = $_.Role -join ', '
            $this.Tasks.Add([Task_InstallDLLs]::new($_.Name, $roles, $this.StagePath))
        }
    }
}