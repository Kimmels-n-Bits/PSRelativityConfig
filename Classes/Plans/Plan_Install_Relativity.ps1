class Plan_Install_Relativity : Plan
{
    [InstallerBundle]$InstallerBundle = [InstallerBundle]::new()
    [System.Collections.Generic.List[Server]]$Servers = @()
    [Boolean]$Validate

    Plan_Install_Relativity() { $this.Init() }
    Plan_Install_Relativity($servers, $installerBundle, $validate, $async)
    { 
        $this.Servers = $servers
        $this.InstallerBundle = $installerBundle
        $this.Validate = $validate
        $this.Async = $async
        $this.Hostnames = $servers.name
        $this.Init()
    }

    Init()
    {
        <# PRECONFIG #>
        $this.Tasks.Add([Plan_PreConfig]::new())

        <# VALIDATE #>

        <# INSTALL #>
        $this.Servers | ForEach-Object {
            $t = [Task_InstallRelativity]::new($_, $this.InstallerBundle)
            $this.Tasks.Add($t)
        }

        <# POST CONFIG #>
        <# VALIDATE #>
    }

    <#  OVERRIDE - Use this method to customize the result returned to pipeline.
        By default, all Task results will be returned as an array.
    Final()
    {
        $this.Result = <Any object type>
    }
    #>
}