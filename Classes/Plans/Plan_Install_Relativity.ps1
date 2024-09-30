class Plan_Install_Relativity : Plan
{
    [PathTable]$Paths = [PathTable]::new()
    [System.Collections.Generic.List[Server]]$RssServers = @()
    [System.Collections.Generic.List[Server]]$Servers = @() #TODO consider refactor, just pass in instance, and filter at this level
    [Boolean]$SkipPreConfig
    [Boolean]$Validate
    

    Plan_Install_Relativity() { $this.Init() }
    Plan_Install_Relativity($servers, $rssServers, $paths, $session, $validate, $skipPreConfig, $async)
    {
        $this.Servers = $servers
        $this.RssServers = $rssServers
        $this.Paths = $paths
        $this.SessionName = $session
        $this.Validate = $validate
        $this.SkipPreConfig = $skipPreConfig
        $this.Async = $async
        $this.Init()
    }

    Init()
    {
        $this.WriteProgress = $true
        $this.WriteProgressActivity = "Executing Relativity Installer Workflows"

        <# PRECONFIG #>
        if(-not $this.SkipPreConfig)
        {
            <# REGISTER RSS #>
            $this.WriteProgressActivity = "Registering with Secret Store"
            $_regRSS = [Plan_WhitelistRSS]::new($this.RssServers, $this.Servers.Name, [Action]::Add, $this.SessionName, $this.Async)
            $_regRSS.WriteProgress = $true
            $this.Tasks.Add($_regRSS)

            <# Set Local Configurations #>
            $this.WriteProgressActivity = "Executing PreConfiguration Plan"
            $_preConfig = [Plan_PreConfig]::new($this.Servers, $this.RssServers, $this.SessionName, $this.Paths, $this.Async)
            $_preConfig.WriteProgress = $true
            $this.Tasks.Add($_preConfig)            
        }

        <# INSTALL #>
        $this.WriteProgressActivity = "Executing Relativity Installer"
        $this.Servers | ForEach-Object {
            $t = [Task_InstallRelativity]::new($_, $this.Paths)
            $t.SessionName = $this.SessionName
            $this.Tasks.Add($t)
        }

        <# POST CONFIG #>
        $this.WriteProgressActivity = "Executing PostConfig Plan"
        <# VALIDATE #>
        $this.WriteProgressActivity = "Validating Relativity Installer Workflow"

        $this.WriteProgressActivity = "Plan Completed"
    }

    <#
    Final()
    {
        $this.Result = 44
    }
    #>
}