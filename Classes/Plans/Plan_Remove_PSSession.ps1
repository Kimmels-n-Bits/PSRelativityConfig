class Plan_Remove_PSSession : Plan
{
    Plan_Remove_PSSession($hostnames, $SessionName, $async)
    { 
        $this.Hostnames = $hostnames
        $this.SessionName = $SessionName
        $this.Async = $async
        $this.Init()
    }

    Init()
    {
        $this.Hostnames | ForEach-Object {
            $t = [Task_Remove_PSSession]::new($_, $this.SessionName)
            $this.Tasks.Add($t)
        }
    }
}