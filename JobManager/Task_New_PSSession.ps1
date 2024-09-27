class Task_New_PSSession : Task
{
    [String]$TargetSession

    Task_New_PSSession($hostname, $credential, $pSSessionName)
    { 
        $this.Hostname = $hostname
        $this.Credentials = $credential
        $this.TargetSession = $pSSessionName
        $this.Init() }

    Init()
    {
        $this.Arguments = @($this.Credentials, $this.TargetSession)
    }    

    hidden $ScriptBlock = {
        Param
        (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [PSCredential] $NetworkCredential,
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [String] $PSSessionName
        )

        try
        {
            if ($null -eq (Get-PSSessionConfiguration -Name $PSSessionName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue))
            {
                try {
                    Register-PSSessionConfiguration -RunAsCredential $NetworkCredential `
                        -Name $PSSessionName *>$null
                }
                catch {
                    Write-Output "[ERROR] $_"
                }
                
            }
        }
        catch
        {
            return 0
        }

        return 1
    }
}