class Task_Timer : Task
{
    Task_Timer($hostname) { $this.Hostname = $hostname; $this.Init() }

    Init()
    {
        $this.Arguments = @(20, "argName1")
    }    

    hidden $ScriptBlock = {
        param($durationMax, $name)
        $_timer = Get-Random -Minimum 5 -Maximum $durationMax
        Start-Sleep -Seconds $_timer

        return 1
    }
}