class Task_RegisterRSS : Task
{
    [System.Collections.Generic.List[String]]$HostsToRegister = @()

    Task_RegisterRSS($hostname, $hostsToRegister)
    {
        $this.Hostname = $hostname
        $this.HostsToRegister = $hostsToRegister
        $this.Init()
    }

    Init()
    {
        $this.Arguments = @($this.HostsToRegister)
    }    

    hidden $ScriptBlock = {
        param($hostnames)
        $RSSPath = "C:\Program Files\Relativity Secret Store\Client"

        if (-not (Test-Path $RSSPath)) { Write-Output "[ERROR] Relativity Secret Store Path not found"; return }
        Set-Location $RSSPath
        $whiteList = .\secretstore.exe whitelist read

        foreach ($h in $hostnames) {
            $name = $h.ToLower()
            if ($whiteList | Where-Object { $_ -like "$($name)*" }) {
                Write-Output "[$($name)] Whitelist Existed"
            } else {
                .\secretstore whitelist write "$($name).oasisdiscovery.com"
                Write-Output "[$($name)] Whitelist Added"
            }
        }

        return
    }
}