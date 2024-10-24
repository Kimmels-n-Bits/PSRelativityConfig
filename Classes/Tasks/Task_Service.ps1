class Task_Service : Task
{
    [Action]$Action
    [System.Collections.Generic.List[String]]$Services = @()

    Task_Service($hostname, $action, $services)
    {
        $this.Hostname = $hostname
        $this.Action = $action
        $this.Services = $services
        $this.Init()
    }

    Init()
    {
        $this.Arguments = @([Int32]$this.Action, $this.Services)
    }    

    hidden $ScriptBlock = {
        param($action, $services)

        foreach ($svc in $services)
        {
            if ($svc -eq "WinRM") { continue } # NO TOUCH
    
            if (Get-Service -Name $svc -ErrorAction SilentlyContinue)
            {
                if ($action -eq 0) # Stop
                {
                    Stop-Service -Name $svc -Force
                }
                elseif ($action -eq 1) # Start
                {
                    Start-Service -Name $svc -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    while ((Get-Service -Name $svc).Status -ne 'Running') { Start-Sleep -Seconds 1 }
                }
            }
            else { <# Not Found #> }
        }
    }
}