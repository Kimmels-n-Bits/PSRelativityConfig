class Task_Hotfix : Task
{
    Task_Hotfix($hostname) { $this.Hostname = $hostname; $this.Init() }

    Init()
    {
        $this.Arguments = @()
    }    

    hidden $ScriptBlock = {
        
    }
}