class Task_AdHoc : Task
{
    Task_AdHoc($hostname, $script)
    { 
        $this.Hostname = $hostname
        $this.ScriptBlock = $script
        $this.Init()
    }

    Init()
    {
        $this.Arguments = @()
    }    

    hidden $ScriptBlock = {
        param()
        return 0
    }
}