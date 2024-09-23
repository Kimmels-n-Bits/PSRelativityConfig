class Plan_PreConfig : Plan
{
    [System.Collections.Generic.List[Server]]$Servers = @()
    [String]$SxS

    Plan_PreConfig() { $this.Init() }
    Plan_PreConfig($servers, $async, $sxs)
    { 
        $this.Servers = $servers
        $this.Async = $async
        $this.SxS = $sxs
        $this.Hostnames = $servers.name
        $this.Init()
    }

    Init()
    {
        $this.Servers | ForEach-Object {
            $t = [Task_PreConfig]::new($_, $this.SxS)
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