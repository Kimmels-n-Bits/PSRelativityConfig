class Task_InstallRelativity : Task
{
    [Server]$Server = [Server]::new()
    [InstallerBundle]$InstallerBundle = [InstallerBundle]::new()

    Task_InstallRelativity($server, $installBundle)
    {
        $this.Server = $server
        $this.InstallerBundle = $installBundle
        $this.Hostname = $this.Server.Name
        $this.Init()
    }

    Init()
    {
        $this.Arguments = @(
            $this.Server.Name,
            $this.Server.Role,
            $this.Server.ResponseFileProperties,
            $this.InstallerBundle,
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
        $cmdFile = Join-Path -Path $installBundle.RelativityStage -ChildPath "Relativity.Installer.exe"
        $cmd = "$($cmdFile) `
            -log $($installBundle.RelativityStage) `
            -responsefilepath '$($myResponse)' `
            -EDDSDBOPASSWORD '$($credPack.EDDSDBOPASSWORD)' `
            -SERVICEPASSWORD '$($credPack.SERVICEPASSWORD)' `
            -SERVICEUSERNAME '$($credPack.SERVICEUSERNAME)'"

        return
    }
}