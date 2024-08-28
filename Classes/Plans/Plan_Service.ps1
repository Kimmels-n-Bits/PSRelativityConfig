class Plan_Service : Plan
{
    [Action]$Action
    [System.Collections.Generic.List[String]]$Services = @()

    Plan_Service($hostnames, $sessionName, [Action]$action, $services, $async)
    { 
        $this.Hostnames = $hostnames
        $this.SessionName = $SessionName
        $this.Action = $action
        $this.Services = $services
        $this.Async = $async
        $this.Init()
    }

    Init()
    {
        $this.Hostnames | ForEach-Object {
            $t = [Task_Service]::new($_, $this.Action, $this.Services)
            $this.Tasks.Add($t)
        }
    }
}