class Task_WhitelistRSS : Task
{
    [System.Collections.Generic.List[String]]$HostsToRegister = @()

    Task_WhitelistRSS($hostname, $hostsToRegister)
    {
        $this.Hostname = $hostname
        $this.HostsToRegister = $hostsToRegister
        $this.Init()
    }

    Init()
    {
        $this.Arguments = @($($this.HostsToRegister -join ';'))
    }    

    hidden $ScriptBlock = {
        param($hostnames)
        $RSSPath = "C:\Program Files\Relativity Secret Store\Client"
        $hostsList = $hostnames -split ';'

        if (-not (Test-Path $RSSPath)) { Write-Output "[ERROR] Relativity Secret Store Path not found"; return }
        Set-Location $RSSPath
        $whiteList = .\secretstore.exe whitelist read

        Write-Output $hostsList
        Write-Output "COUNT $($hostsList.count)"

        #TODO Scrub string to just use hostname.

        foreach ($h in $hostsList) {
            $name = $h.ToLower()
            if ($whiteList | Where-Object { $_ -like "$($name)*" }) {
                Write-Output "[$($name)] Whitelist Existed"
            } else {
                .\secretstore whitelist write "$($name).$((Get-CimInstance -ClassName Win32_ComputerSystem).Domain)"
                Write-Output "[$($name)] Whitelist Added"
            }
        }

        return
    }
}