class Task_Remove_PSSession : Task
{
    [String]$TargetSession
    
    Task_Remove_PSSession($hostname, $pSSessionName)
    { 
        $this.Hostname = $hostname
        $this.TargetSession = $pSSessionName
        $this.Init() }

    Init()
    {
        $this.Arguments = @($this.TargetSession)
    }    

    hidden $ScriptBlock = {
        Param
        (
            [Parameter(Mandatory = $True, Position = 0)]
            [String]$SessionName
        )

        Unregister-PSSessionConfiguration -Name $SessionName -Force

        return 1
    }
}