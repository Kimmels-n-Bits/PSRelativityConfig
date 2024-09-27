class Plan_PreConfig : Plan
{
    [PathTable]$Paths
    [System.Collections.Generic.List[Server]]$RSSServers = @()
    [System.Collections.Generic.List[Server]]$Servers = @()

    Plan_PreConfig() { $this.Init() }
    Plan_PreConfig($servers, $rssServers, $session, $paths, $async)
    { 
        $this.Servers = $servers
        $this.RSSServers = $rssServers
        $this.SessionName = $session
        $this.Paths = $paths
        $this.Async = $async
        $this.Hostnames = $servers.name
        $this.Init()
    }

    Init()
    {
        $Plan = [Plan_CopyFiles]::new(
        $this.Servers.Name,
        $this.SessionName,
        "\\$($this.RSSServers[0].Name)\C$\Program Files\Relativity Secret Store\Client\",
        $this.Paths.SecretStoreStage,
        $this.Paths.SecretStoreStage,
        $false,
        $this.Async)

        $Plan.WriteProgress = $true
        $Plan.WriteProgressActivity = "Staging RSS Registration Files"
        $this.Tasks.Add($Plan)
    

        $this.Servers | ForEach-Object {
            $t = [Task_PreConfig]::new($_, $this.RSSServers, $this.Paths)
            $this.Tasks.Add($t)
        }
    }

    <#  OVERRIDE - Use this method to customize the result returned to pipeline.
        By default, all Task results will be returned as an array.
    Final()
    {
        $this.Result = <Any object type>
    }
    #>
}