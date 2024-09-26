class Task_InstallRelativity : Task
{
    [Server]$Server = [Server]::new()
    [PathTable]$Paths = [PathTable]::new()

    Task_InstallRelativity($server, $installBundle)
    {
        $this.Server = $server
        $this.Paths = $installBundle
        $this.Hostname = $this.Server.Name
        $this.Init()
    }

    Init()
    {
        $this.Arguments = @(
            $this.Server.Name,
            $this.Server.Role,
            $this.Server.ResponseFileProperties,
            $this.Paths,
            $this.Server.ParentInstance.CredPack
            )
    }

    hidden $ScriptBlock = {
        param($hostname, $roles, $responseFile, $installBundle, $credPack)

        <# Response File #>
        if (-not (Test-Path $installBundle.RelativityStage))
        {
            New-Item -Path $installBundle.RelativityStage -ItemType Directory -Force
        }
        $responsePath = $(Join-Path -Path $installBundle.RelativityStage -ChildPath "Response.txt")
        $responseString = $responseFile.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" } | Out-String
        Set-Content -Path $responsePath -Value $responseString

        <# Execute Installation #>
        #TODO Factor in parameters for different roles.
        #TODO PSQ-DSQ are mutually exclusive
        $cmdFile = Join-Path -Path $installBundle.RelativityStage -ChildPath "Relativity.Installer.exe"
        $cmd = "$($cmdFile) -log $($installBundle.RelativityStage) -responsefilepath $($responsePath) -EDDSDBOPASSWORD $($credPack.EDDSDBOPASSWORD) -SERVICEPASSWORD $($credPack.SERVICEPASSWORD) -SERVICEUSERNAME $($credPack.SERVICEUSERNAME)"

        # .\Relativity.Installer.exe -log $log_file  -responsefilepath="$($response_file)"
        try {
            Set-Location $installBundle.RelativityStage
            $log = Join-Path -Path $installBundle.RelativityStage -ChildPath "Install_Log.txt"
            .\Relativity.Installer.exe /log "$log" /responsefilepath="$responsePath" EDDSDBOPASSWORD="$($credPack.EDDSDBOPASSWORD)" SERVICEPASSWORD="$($credPack.SERVICEPASSWORD)" SERVICEUSERNAME="$($credPack.SERVICEUSERNAME)"
            return $cmd #TODO RMV ASAP
        }
        catch {
            return $_.Exception.Message
        }
    }
}