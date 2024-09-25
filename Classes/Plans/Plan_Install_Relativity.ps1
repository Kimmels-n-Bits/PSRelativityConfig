class Plan_Install_Relativity : Plan
{
    [PathTable]$Paths = [PathTable]::new()
    [System.Collections.Generic.List[Server]]$Servers = @()
    [Boolean]$Validate

    Plan_Install_Relativity() { $this.Init() }
    Plan_Install_Relativity($servers, $Paths, $validate, $async)
    { 
        $this.Servers = $servers
        $this.Paths = $Paths
        $this.Validate = $validate
        $this.Async = $async
        $this.Hostnames = $servers.name
        $this.Init()
    }

    Init()
    {
        $this.WriteProgress = $true
        $this.WriteProgressActivity = "Executing Relativity Installer Workflows"

        <# PRECONFIG #>
        $this.WriteProgressActivity = "Executing PreConfiguration Plan"
        $_preConfig = [Plan_PreConfig]::new($this.Servers, $this.Async, $this.Paths.SxS)
        $_preConfig.WriteProgress = $true
        $_preConfig.WriteProgressID = 1
        $this.Tasks.Add($_preConfig)

        <# VALIDATE #>

        <# INSTALL #>
        $this.WriteProgressActivity = "Executing Relativity Installer"
        $this.Servers | ForEach-Object {
            $t = [Task_InstallRelativity]::new($_, $this.Paths)
            $this.Tasks.Add($t)
        }

        <# POST CONFIG #>
        $this.WriteProgressActivity = "Executing PostConfig Plan"
        <# VALIDATE #>
        $this.WriteProgressActivity = "Validating Relativity Installer Workflow"

        $this.WriteProgressActivity = "Plan Completed"
    }

    <#  OVERRIDE - Use this method to customize the result returned to pipeline.
        By default, all Task results will be returned as an array.
    Final()
    {
        $this.Result = <Any object type>
    }
    #>
}